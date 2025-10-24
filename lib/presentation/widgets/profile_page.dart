import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/presentation/widgets/custom_card.dart';
import 'package:travel2u_v1/presentation/widgets/custom_dropdown.dart';
import 'package:travel2u_v1/presentation/widgets/custom_textfield.dart';

class UserProfile {
  // String userId;
  String firstName;
  String lastName;
  String username;
  String phoneNo;
  String address;
  String country;
  String city;
  String password;
  String preferredTravelStyle;
  DateTime? dateOfBirth;
  String status;

  UserProfile({
    // this.userId = '',
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.phoneNo = '',
    this.address = '',
    this.country = '',
    this.city = '',
    this.password = '',
    this.preferredTravelStyle = '',
    this.dateOfBirth,
    this.status = 'Active',
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
  // late UserProfile _profile;
  UserProfile _profile = UserProfile(
    firstName: '',
    lastName: '',
    username: '',
    phoneNo: '',
    address: '',
    country: '',
    city: '',
    password: '',
    preferredTravelStyle: '',
    dateOfBirth: DateTime.now(),
    status: '',
  );
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _dobController;
  String? _profileImageUrl;
  String? userRole;

  final List<String> _travelStyles = [
    'Adventure',
    'Relaxation',
    'Cultural',
    'Family',
    'Business',
    'Luxury',
    'Budget',
    'Solo',
    'Group',
  ];

  final List<String> _statusOptions = ['Active', 'Inactive', 'Suspended'];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _profile = widget.initialProfile ?? UserProfile();

    _firstNameController = TextEditingController(text: _profile.firstName);
    _lastNameController = TextEditingController(text: _profile.lastName);
    _usernameController = TextEditingController(text: _profile.username);
    _phoneController = TextEditingController(text: _profile.phoneNo);
    _addressController = TextEditingController(text: _profile.address);
    _countryController = TextEditingController(text: _profile.country);
    _cityController = TextEditingController(text: _profile.city);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _dobController = TextEditingController(
      text:
          _profile.dateOfBirth != null
              ? '${_profile.dateOfBirth!.day}/${_profile.dateOfBirth!.month}/${_profile.dateOfBirth!.year}'
              : '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
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
          username: data['userName'] ?? '',
          phoneNo: data['phone'] ?? '',
          address: data['address'] ?? '',
          country: data['country'] ?? '',
          city: data['city'] ?? '',
          preferredTravelStyle: data['preferredTravel'] ?? '',
          dateOfBirth:
              data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
          status: data['status'] ?? 'Active',
        );
        _firstNameController.text = _profile.firstName;
        _lastNameController.text = _profile.lastName;
        _usernameController.text = _profile.username;
        _phoneController.text = _profile.phoneNo;
        _addressController.text = _profile.address;
        _countryController.text = _profile.country;
        _cityController.text = _profile.city;
        _dobController.text =
            _profile.dateOfBirth != null
                ? '${_profile.dateOfBirth!.day}/${_profile.dateOfBirth!.month}/${_profile.dateOfBirth!.year}'
                : '';
      });
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
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

      final profileCollection = FirebaseFirestore.instance.collection('users');
      final profileData = {
        'firstName': _profile.firstName,
        'lastName': _profile.lastName,
        'userName': _profile.username,
        'dob': _profile.dateOfBirth,
        'phone': _profile.phoneNo,
        'address': _profile.address,
        'city': _profile.city,
        'country': _profile.country,
        'preferredTravel': _profile.preferredTravelStyle,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await profileCollection
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      // Optional: update password if user entered a new one
      if (_profile.password != null && _profile.password!.isNotEmpty) {
        await user.updatePassword(_profile.password!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Colors.blue.shade900,
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
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.account_circle_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => _profile.username = value ?? '',
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
                    validator: (value) {
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

              // Preferences Section
              if (userRole == "customer") ...[
                _buildSectionHeader('Preferences'),
                const SizedBox(height: 16),
                CustomCard(
                  children: [
                    CustomDropdownField(
                      label: 'Preferred Travel Style',
                      icon: Icons.flight_outlined,
                      value:
                          _profile.preferredTravelStyle.isEmpty
                              ? null
                              : _profile.preferredTravelStyle,
                      items: _travelStyles,
                      onChanged: (value) {
                        setState(() {
                          _profile.preferredTravelStyle = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a travel style';
                        }
                        return null;
                      },
                    ),

                    // const SizedBox(height: 16),
                    // _buildDropdownField(
                    //   label: 'Account Status',
                    //   icon: Icons.verified_user_outlined,
                    //   value: _profile.status,
                    //   items: _statusOptions,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _profile.status = value ?? 'Active';
                    //     });
                    //   },
                    // ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // ),

              // Security Section
              _buildSectionHeader('Security'),
              const SizedBox(height: 16),
              CustomCard(
                children: [
                  CustomTextField(
                    controller: _passwordController,
                    label: 'New Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    helperText: 'Leave blank to keep current password',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        _profile.password = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (_passwordController.text.isNotEmpty) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),

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
                    _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? Image.network(
                          _profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildProfileIcon();
                          },
                        )
                        : _buildProfileIcon(),
              ),
            ),
            // Edit Button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
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
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blue.shade900),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
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

  void _takePhoto() {
    // Implement camera functionality
    // You'll need image_picker package for this
    // Example:
    // final ImagePicker picker = ImagePicker();
    // final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    // if (photo != null) {
    //   setState(() {
    //     _profileImageUrl = photo.path; // or upload to server and get URL
    //   });
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Camera feature - Add image_picker package'),
        backgroundColor: Colors.blue.shade900,
      ),
    );
  }

  void _chooseFromGallery() {
    // Implement gallery functionality
    // You'll need image_picker package for this
    // Example:
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   setState(() {
    //     _profileImageUrl = image.path; // or upload to server and get URL
    //   });
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gallery feature - Add image_picker package'),
        backgroundColor: Colors.blue.shade900,
      ),
    );
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
