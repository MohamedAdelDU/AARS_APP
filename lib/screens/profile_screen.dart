import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final bool isPostAuth;

  const ProfileScreen({super.key, this.isPostAuth = false});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  String _selectedBloodType = 'None';
  final List<String> _bloodTypes = [
    'None',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _mobileNumber;
  String? _nationalAddress;
  String? _profileImageUrl;
  bool _isEditing = false;
  bool _isLoading = false;

  final _mobileNumberController = TextEditingController();
  final _nationalAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isPostAuth) {
      _isEditing = true;
    }
    _loadProfileData();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
      }
    }
  }

  Future<String?> _uploadImageToStorage(File image, String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception("User ID is empty");
      }
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$userId.jpg',
      );
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      if (snapshot.state != TaskState.success) {
        throw Exception("Image upload failed: ${snapshot.state}");
      }
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error uploading image: $e")));
      }
      return null;
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final displayName = user.displayName ?? 'Unknown User';
        final nameParts = displayName.split(' ');
        final email = user.email ?? 'No email provided';
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        setState(() {
          _firstName = nameParts.isNotEmpty ? nameParts[0] : 'Unknown';
          _lastName = nameParts.length > 1 ? nameParts[1] : 'User';
          _email = email;
          _mobileNumber = doc.exists ? doc['mobileNumber'] ?? '' : '';
          _nationalAddress = doc.exists ? doc['nationalAddress'] ?? '' : '';
          _selectedBloodType = doc.exists ? doc['bloodType'] ?? 'None' : 'None';
          _profileImageUrl = doc.exists ? doc['profileImageUrl'] : null;
          _mobileNumberController.text = _mobileNumber!;
          _nationalAddressController.text = _nationalAddress!;
          if (_profileImageUrl != null) {
            _image = null;
          }
        });
      } else {
        throw Exception('No user is signed in');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile data: $e")),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl = _profileImageUrl;
        if (_image != null) {
          imageUrl = await _uploadImageToStorage(_image!, user.uid);
          if (imageUrl == null) {
            throw Exception("Failed to upload image");
          }
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': '$_firstName $_lastName',
          'mobileNumber': _mobileNumberController.text.trim(),
          'nationalAddress': _nationalAddressController.text.trim(),
          'bloodType': _selectedBloodType,
          'profileImageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() {
          _mobileNumber = _mobileNumberController.text.trim();
          _nationalAddress = _nationalAddressController.text.trim();
          _profileImageUrl = imageUrl;
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
          if (widget.isPostAuth) {
            Navigator.pop(context); // Close modal
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        throw Exception('No user is signed in');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile data: $e")),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mobileNumberController.dispose();
    _nationalAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPostAuth) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.lightBlue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "We're almost done! Complete your profile details quickly.",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.lightBlue[800],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _isEditing ? _pickImage : null,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _image != null
                                        ? FileImage(_image!)
                                        : _profileImageUrl != null
                                        ? NetworkImage(_profileImageUrl!)
                                        : null,
                                child:
                                    _image == null && _profileImageUrl == null
                                        ? Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Colors.grey[600],
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildProfileInfo(
                              "$_firstName $_lastName",
                              "Name",
                              editable: false,
                            ),
                            _buildProfileInfo(
                              _email ?? 'No email provided',
                              "Email",
                              editable: false,
                            ),
                            _isEditing
                                ? _buildEditableField(
                                  _mobileNumberController,
                                  "Mobile Number",
                                )
                                : _buildProfileInfo(
                                  _mobileNumber ?? 'Not provided',
                                  "Mobile Number",
                                ),
                            _isEditing
                                ? _buildEditableField(
                                  _nationalAddressController,
                                  "National Address",
                                )
                                : _buildProfileInfo(
                                  _nationalAddress ?? 'Not provided',
                                  "National Address",
                                ),
                            _isEditing
                                ? _buildBloodTypeDropdown("Blood Type")
                                : _buildProfileInfo(
                                  _selectedBloodType,
                                  "Blood Type",
                                ),
                            if (_isEditing)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: ElevatedButton(
                                  onPressed: _saveProfileData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                  child: const Text(
                                    "Save Profile",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.isPostAuth)
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/home',
                                  );
                                },
                                child: const Text(
                                  "Skip for now",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Profile", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _mobileNumberController.text = _mobileNumber ?? '';
                    _nationalAddressController.text = _nationalAddress ?? '';
                    _selectedBloodType = _selectedBloodType;
                  }
                });
              },
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                _image != null
                                    ? FileImage(_image!)
                                    : _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                            child:
                                _image == null && _profileImageUrl == null
                                    ? Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: Colors.grey[600],
                                    )
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildProfileInfo(
                          "$_firstName $_lastName",
                          "Name",
                          editable: false,
                        ),
                        _buildProfileInfo(
                          _email ?? 'No email provided',
                          "Email",
                          editable: false,
                        ),
                        _isEditing
                            ? _buildEditableField(
                              _mobileNumberController,
                              "Mobile Number",
                            )
                            : _buildProfileInfo(
                              _mobileNumber ?? 'Not provided',
                              "Mobile Number",
                            ),
                        _isEditing
                            ? _buildEditableField(
                              _nationalAddressController,
                              "National Address",
                            )
                            : _buildProfileInfo(
                              _nationalAddress ?? 'Not provided',
                              "National Address",
                            ),
                        _isEditing
                            ? _buildBloodTypeDropdown("Blood Type")
                            : _buildProfileInfo(
                              _selectedBloodType,
                              "Blood Type",
                            ),
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton(
                              onPressed: _saveProfileData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                "Save Profile",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
      );
    }
  }

  Widget _buildProfileInfo(String value, String label, {bool editable = true}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEditableField(TextEditingController controller, String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Enter $label",
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeDropdown(String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: _selectedBloodType,
            decoration: const InputDecoration(border: InputBorder.none),
            items:
                _bloodTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 18)),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _selectedBloodType = value!),
          ),
        ],
      ),
    );
  }
}
