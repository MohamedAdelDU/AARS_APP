import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  // Controllers for editable fields
  final _mobileNumberController = TextEditingController();
  final _nationalAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      // Validate userId
      if (userId.isEmpty) {
        throw Exception("User ID is empty");
      }

      // Create storage reference
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$userId.jpg',
      );

      // Upload the file
      final uploadTask = storageRef.putFile(image);

      // Wait for the upload to complete and get the snapshot
      final snapshot = await uploadTask.whenComplete(() {});

      // Check the upload state
      if (snapshot.state != TaskState.success) {
        throw Exception("Image upload failed: ${snapshot.state}");
      }

      // Get the download URL
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
        // Fetch name and email from FirebaseAuth
        final displayName = user.displayName ?? 'Unknown User';
        final nameParts = displayName.split(' ');
        final email = user.email ?? 'No email provided';

        // Fetch additional data from Firestore
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        setState(() {
          _firstName = nameParts.isNotEmpty ? nameParts[0] : 'Unknown';
          _lastName = nameParts.length > 1 ? nameParts[1] : 'User';
          _email = email;
          _mobileNumber =
              doc.exists
                  ? doc['mobileNumber'] ?? 'Not provided'
                  : 'Not provided';
          _nationalAddress =
              doc.exists
                  ? doc['nationalAddress'] ?? 'Not provided'
                  : 'Not provided';
          _selectedBloodType = doc.exists ? doc['bloodType'] ?? 'None' : 'None';
          _profileImageUrl = doc.exists ? doc['profileImageUrl'] : null;
          // Set controller values
          _mobileNumberController.text = _mobileNumber!;
          _nationalAddressController.text = _nationalAddress!;
          // Load image from URL if available
          if (_profileImageUrl != null) {
            _image = null; // Image will be displayed via NetworkImage
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

        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'mobileNumber': _mobileNumberController.text.trim(),
          'nationalAddress': _nationalAddressController.text.trim(),
          'bloodType': _selectedBloodType,
          'profileImageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update local state
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
                  // Reset controllers to current values when canceling edit
                  _mobileNumberController.text =
                      _mobileNumber ?? 'Not provided';
                  _nationalAddressController.text =
                      _nationalAddress ?? 'Not provided';
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
                          : _buildProfileInfo(_selectedBloodType, "Blood Type"),
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
