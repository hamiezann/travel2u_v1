import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel2u_v1/presentation/widgets/custom_card.dart';
import 'package:travel2u_v1/presentation/widgets/custom_textfield.dart';

class UserProfile {
  String firstName;
  String lastName;
  String phoneNo;
  String address;
  String country;
  String city;
  DateTime? dateOfBirth;
  String status;
  String passportNo;
  String imageUrl;
  UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.phoneNo = '',
    this.address = '',
    this.country = '',
    this.city = '',
    this.dateOfBirth,
    this.status = 'Active',
    this.passportNo = '',
    this.imageUrl = '',
  });
}

class ProfilePage extends StatefulWidget {
  final UserProfile? initialProfile;

  const ProfilePage({Key? key, this.initialProfile}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  UserProfile _profile = UserProfile(
    firstName: '',
    lastName: '',
    phoneNo: '',
    address: '',
    country: '',
    city: '',
    passportNo: '',
    dateOfBirth: DateTime.now(),
    status: '',
    imageUrl: '',
  );
  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImageFile;
  String? _oldImageUrl;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _passportNoController;
  late TextEditingController _dobController;
  late TextEditingController _imageUrlController;
  String? _profileImageUrl;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _profile = widget.initialProfile ?? UserProfile();
    _firstNameController = TextEditingController(text: _profile.firstName);
    _lastNameController = TextEditingController(text: _profile.lastName);
    _phoneController = TextEditingController(text: _profile.phoneNo);
    _addressController = TextEditingController(text: _profile.address);
    _countryController = TextEditingController(text: _profile.country);
    _cityController = TextEditingController(text: _profile.city);
    _passportNoController = TextEditingController(text: _profile.passportNo);
    _dobController = TextEditingController(
      text:
          _profile.dateOfBirth != null
              ? '${_profile.dateOfBirth!.day}/${_profile.dateOfBirth!.month}/${_profile.dateOfBirth!.year}'
              : '',
    );
    _imageUrlController = TextEditingController(text: _profile.imageUrl);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _passportNoController.dispose();
    _dobController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _profile.dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade900),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _profile.dateOfBirth = picked;
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      setState(() {
        userRole = data['role'];
        _profile = UserProfile(
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          phoneNo: data['phone'] ?? '',
          address: data['address'] ?? '',
          country: data['country'] ?? '',
          city: data['city'] ?? '',
          dateOfBirth:
              data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
          status: data['status'] ?? 'Active',
          passportNo: data['passportNo'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
        );
        _firstNameController.text = _profile.firstName;
        _lastNameController.text = _profile.lastName;
        _phoneController.text = _profile.phoneNo;
        _addressController.text = _profile.address;
        _countryController.text = _profile.country;
        _cityController.text = _profile.city;
        _passportNoController.text = _profile.passportNo;
        _dobController.text =
            _profile.dateOfBirth != null
                ? '${_profile.dateOfBirth!.day}/${_profile.dateOfBirth!.month}/${_profile.dateOfBirth!.year}'
                : '';
        _imageUrlController.text = _profile.imageUrl;
      });
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<bool> _checkUniquePhoneNo(String inputtedPhoneNo) async {
    if (inputtedPhoneNo.isEmpty) {
      return true;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: inputtedPhoneNo)
              .limit(1)
              .get();
      if (querySnapshot.docs.isEmpty) {
        return true;
      } else {
        String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (querySnapshot.docs.length == 1 &&
            querySnapshot.docs.first.id == currentUserId) {
          return true;
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error checking phone no uniqueness: $e');
      return false;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      bool isUnique = await _checkUniquePhoneNo(_phoneController.text);
      if (!isUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This phone number is not available.')),
        );
        return;
      }

      final profileCollection = FirebaseFirestore.instance.collection('users');
      final profileData = {
        'firstName': _profile.firstName,
        'lastName': _profile.lastName,
        'dob': _profile.dateOfBirth,
        'phone': _profile.phoneNo,
        'address': _profile.address,
        'city': _profile.city,
        'country': _profile.country,
        'updatedAt': FieldValue.serverTimestamp(),
        'passportNo': _profile.passportNo,
      };
      if (_selectedImageFile != null) {
        final newImageUrl = await uploadImage(user.uid);
        if (newImageUrl != null) {
          profileData['imageUrl'] = newImageUrl;
        }
      }
      await profileCollection
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Colors.blue.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _profilePictureField(),
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 16),
              CustomCard(
                children: [
                  CustomTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    onSaved: (value) => _profile.firstName = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    onSaved: (value) => _profile.lastName = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _dobController,
                    label: 'Date of Birth',
                    icon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date of birth is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  (userRole == "staff")
                      ? const SizedBox()
                      : CustomTextField(
                        controller: _passportNoController,
                        label: 'Passport No',
                        icon: Icons.add_card_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                        onSaved: (value) => _profile.passportNo = value ?? '',
                      ),
                ],
              ),

              const SizedBox(height: 32),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              const SizedBox(height: 16),
              CustomCard(
                children: [
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                    onSaved: (value) => _profile.phoneNo = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                    onSaved: (value) => _profile.address = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  if (userRole == "customer") ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                            onSaved: (value) => _profile.city = value ?? '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _countryController,
                            label: 'Country',
                            icon: Icons.public_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                            onSaved: (value) => _profile.country = value ?? '',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
      ),
    );
  }

  Widget _profilePictureField() {
    return Column(
      children: [
        Stack(
          children: [
            // Profile Picture Container
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.blue.shade900, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    _selectedImageFile != null
                        ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                        : (_profile.imageUrl.isNotEmpty
                            ? Image.network(
                              _profile.imageUrl,
                              fit: BoxFit.cover,
                            )
                            : _buildProfileIcon()),
              ),
            ),
            // Edit Button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  // ClipRRect(
                  //   borderRadius: BorderRadius.circular(12),
                  //   child:
                  //       _isUploadingImage
                  //           ? const Center(child: CircularProgressIndicator())
                  //           : _selectedImageFile != null
                  //           ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                  //           : _profile.imageUrl.isNotEmpty
                  //           ? Image.network(
                  //             _profile.imageUrl,
                  //             fit: BoxFit.cover,
                  //             loadingBuilder: (context, child, progress) {
                  //               if (progress == null) return child;
                  //               return const Center(
                  //                 child: CircularProgressIndicator(),
                  //               );
                  //             },
                  //             errorBuilder: (context, error, trace) {
                  //               return const Center(
                  //                 child: Icon(Icons.broken_image, size: 50),
                  //               );
                  //             },
                  //           )
                  //           : Center(
                  //             child: Column(
                  //               mainAxisAlignment: MainAxisAlignment.center,
                  //               children: [
                  //                 Icon(
                  //                   Icons.add_photo_alternate,
                  //                   size: 48,
                  //                   color: Colors.grey.shade400,
                  //                 ),
                  //                 const SizedBox(height: 8),
                  //                 Text(
                  //                   'Tap to upload',
                  //                   style: TextStyle(
                  //                     color: Colors.grey.shade600,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ),
                  // ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Upload Profile Picture',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
          TextButton.icon(
            onPressed: _removeImage,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove Photo'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          ),
      ],
    );
  }

  Widget _buildProfileIcon() {
    // Show profile icon with user initials if name is available
    String initials = '';
    if (_profile.firstName.isNotEmpty || _profile.lastName.isNotEmpty) {
      initials =
          '${_profile.firstName.isNotEmpty ? _profile.firstName[0] : ''}'
          '${_profile.lastName.isNotEmpty ? _profile.lastName[0] : ''}';
    }

    if (initials.isNotEmpty) {
      return Container(
        color: Colors.blue.shade100,
        child: Center(
          child: Text(
            initials.toUpperCase(),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ),
      );
    } else {
      // Show default profile icon if no name
      return Container(
        color: Colors.blue.shade100,
        child: Icon(Icons.person, size: 70, color: Colors.blue.shade900),
      );
    }
  }

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 20),
                // ListTile(
                //   leading: Icon(Icons.camera_alt, color: Colors.blue.shade900),
                //   title: const Text('Take Photo'),
                //   onTap: () {
                //     Navigator.pop(context);
                //     _takePhoto();
                //   },
                // ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Colors.blue.shade900,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _chooseFromGallery();
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImageFile = File(pickedFile.path);
      _profileImageUrl = null; // temporary, until uploaded
    });
  }

  Future<String?> uploadImage(String userId) async {
    if (_selectedImageFile == null) return null;

    try {
      // Delete old image first (if exists)
      if (_profile.imageUrl.isNotEmpty) {
        _oldImageUrl = _profile.imageUrl;
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(_oldImageUrl!);
          await oldRef.delete();
        } catch (e) {}
      }

      // Upload new image
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child(userId)
          .child('profile.jpg');

      await ref.putFile(_selectedImageFile!);
      final imageUrl = await ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      // print('Error uploading image: $e');
      return null;
    }
  }

  void _chooseFromGallery() async {
    Navigator.pop(context);
    await pickImage();
    setState(() {});
  }

  void _removeImage() {
    setState(() {
      _profileImageUrl = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile picture removed'),
        backgroundColor: Colors.blue.shade900,
      ),
    );
  }
}
