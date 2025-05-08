import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'dart:convert';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => ContactsScreenState();
}

class ContactsScreenState extends State<ContactsScreen> {
  final List<Map<String, String>> _emergencyContacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;
  String _selectedCountryCode = '+20'; // القيمة الافتراضية (مصر)

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        await _loadContacts();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initialize user: $e")),
        );
      }
    }
  }

  Future<void> _loadContacts() async {
    try {
      if (_userId == null) return;
      final doc = await _firestore.collection('users').doc(_userId).get();
      final contactsData = doc.data()?['emergency_contacts'] ?? [];
      final List<Map<String, String>> contacts =
          List<Map<String, String>>.from(
            contactsData.map((c) {
              String cleanPhone = (c['phone'] as String).replaceAll(
                RegExp(r'[^0-9+]'),
                '',
              );
              if (cleanPhone.length < 10) {
                print('Invalid phone number detected: $cleanPhone, skipping.');
                return {'name': c['name'] as String, 'phone': ''};
              }
              return {'name': c['name'] as String, 'phone': cleanPhone};
            }),
          ).where((c) => c['phone']!.isNotEmpty).toList();

      setState(() {
        _emergencyContacts.clear();
        _emergencyContacts.addAll(contacts);
      });

      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          _emergencyContacts.map((contact) => jsonEncode(contact)).toList();
      await prefs.setStringList('emergencyContacts', contactsJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load contacts: $e")));
      }
    }
  }

  Future<void> _saveContacts() async {
    try {
      if (_userId == null) return;
      await _firestore.collection('users').doc(_userId).set({
        'emergency_contacts':
            _emergencyContacts
                .map((c) => {'name': c['name'], 'phone': c['phone']})
                .toList(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          _emergencyContacts.map((contact) => jsonEncode(contact)).toList();
      await prefs.setStringList('emergencyContacts', contactsJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save contacts: $e")));
      }
    }
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    // التحقق من أن الرقم يبدأ بـ "+" ويحتوي على 10 أرقام على الأقل بعد الرمز
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    print('Validating phone number: $cleanPhone');
    if (!cleanPhone.startsWith('+') || cleanPhone.length < 10) {
      print('Invalid phone number length or format');
      return false;
    }
    return true;
  }

  void _addContact(String name, String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    print('Adding contact - Cleaned phone: $cleanPhone');

    if (name.isEmpty || !_isValidPhoneNumber(cleanPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter a valid name and phone number (e.g., +93123456789, min 10 digits)",
          ),
        ),
      );
      return;
    }

    if (_emergencyContacts.any((contact) => contact['phone'] == cleanPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This phone number is already added")),
      );
      return;
    }

    setState(() {
      _emergencyContacts.add({'name': name, 'phone': cleanPhone});
    });
    _saveContacts();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Contact Added")));
    }
  }

  void _removeContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    _saveContacts();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Contact Removed")));
    }
  }

  void _callNumber(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch phone dialer")),
        );
      }
    }
  }

  Future<void> _showAddContactDialog() async {
    PermissionStatus permissionStatus = await Permission.contacts.status;
    print("Initial permission status: $permissionStatus");

    if (permissionStatus.isGranted) {
      await _openContactPicker();
    } else {
      permissionStatus = await Permission.contacts.request();
      print("Permission status after request: $permissionStatus");

      if (permissionStatus.isGranted) {
        await _openContactPicker();
      } else if (permissionStatus.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  title: const Text(
                    "Permission Denied",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Access to contacts was permanently denied. Please enable it in Settings.",
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showManualAddContactDialog();
                      },
                      child: const Text(
                        "Add Manually",
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        bool opened = await openAppSettings();
                        if (!opened && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open settings"),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Open Settings",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ),
                  ],
                ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  title: const Text(
                    "Permission Denied",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Access to contacts was denied. You can enable it in Settings or add a contact manually.",
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showManualAddContactDialog();
                      },
                      child: const Text(
                        "Add Manually",
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        bool opened = await openAppSettings();
                        if (!opened && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open settings"),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Open Settings",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ),
                  ],
                ),
          );
        }
      }
    }
  }

  Future<void> _openContactPicker() async {
    try {
      Contact? contact = await ContactsService.openDeviceContactPicker();
      print("Contact picked: $contact");

      if (contact != null) {
        String? name = contact.displayName;
        String? phone =
            contact.phones?.isNotEmpty == true
                ? contact.phones!.first.value
                : null;

        if (name != null && phone != null) {
          final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
          print('Picked contact phone (cleaned): $cleanPhone');

          if (!_isValidPhoneNumber(cleanPhone)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Contact phone number must be valid (e.g., +93123456789, min 10 digits)",
                  ),
                ),
              );
            }
            return;
          }
          _addContact(name, cleanPhone);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Invalid contact selected. Please select a contact with a valid name and phone number.",
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("No contact selected.")));
        }
      }
    } catch (e) {
      print("Error opening contact picker: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open contact picker: $e")),
        );
      }
    }
  }

  void _showManualAddContactDialog() {
    setState(() {
      _selectedCountryCode = '+20'; // إعادة تعيين القيمة الافتراضية
      _phoneController.clear();
      _nameController.clear();
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            title: const Text(
              "Add Emergency Contact Manually",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(color: Colors.black54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100, // عرض ثابت لـ CountryCodePicker
                        child: CountryCodePicker(
                          onChanged: (countryCode) {
                            setState(() {
                              _selectedCountryCode =
                                  countryCode.dialCode ?? '+20';
                            });
                            print(
                              'Selected country code: $_selectedCountryCode',
                            );
                          },
                          initialSelection: 'EGY', // مصر افتراضيًا
                          favorite: ['+20', 'EGY'], // الدول المفضلة
                          showCountryOnly: false,
                          showFlag: true,
                          showFlagDialog: true,
                          searchDecoration: const InputDecoration(
                            labelText: 'Search for a country',
                            labelStyle: TextStyle(color: Colors.black54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          textStyle: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 16), // مسافة بين العنصرين
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: "Phone Number (without country code)",
                            labelStyle: TextStyle(color: Colors.black54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty &&
                      _phoneController.text.isNotEmpty) {
                    // تنظيف الرقم (إزالة أي أحرف غير رقمية)
                    final cleanPhoneNumber = _phoneController.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    // إضافة رمز الدولة إلى الرقم
                    final fullPhone = '$_selectedCountryCode$cleanPhoneNumber';
                    print('Full phone number: $fullPhone');

                    if (!_isValidPhoneNumber(fullPhone)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Phone number must be valid (e.g., +93123456789, min 10 digits)",
                          ),
                        ),
                      );
                      return;
                    }

                    _addContact(_nameController.text, fullPhone);
                    _nameController.clear();
                    _phoneController.clear();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill in both fields"),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Add",
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final contact = _emergencyContacts.removeAt(oldIndex);
      _emergencyContacts.insert(newIndex, contact);
    });
    _saveContacts();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Contact order updated")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[100],
        title: const Text(
          "Contacts",
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: const [],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _showAddContactDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Contacts",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _emergencyContacts.isEmpty
                ? const Center(child: Text("No emergency contacts added"))
                : ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: _onReorder,
                  children: List.generate(_emergencyContacts.length, (index) {
                    final contact = _emergencyContacts[index];
                    return Padding(
                      key: ValueKey(index),
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.black12,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            contact['name']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(contact['phone']!),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.reorder, color: Colors.grey),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeContact(index),
                              ),
                            ],
                          ),
                          onTap: () => _callNumber(contact['phone'] ?? ''),
                        ),
                      ),
                    );
                  }),
                ),
            const SizedBox(height: 20),
            const Text(
              "Emergency Calls",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _callNumber("911"),
                    child: Container(
                      height: 150,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.local_police,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Police",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _callNumber("112"),
                    child: Container(
                      height: 150,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Ambulance",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
