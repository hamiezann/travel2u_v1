import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:travel2u_v1/core/models/activity.dart';
import 'package:travel2u_v1/core/models/travel_package.dart';
import 'package:travel2u_v1/presentation/widgets/custom_step_indicator.dart';

class CreateOrEditTravelPackagePage extends StatefulWidget {
  final String? packageId;
  // const AddTravelPackagePage({Key? key}) : super(key: key);
  const CreateOrEditTravelPackagePage({super.key, this.packageId});

  @override
  State<CreateOrEditTravelPackagePage> createState() =>
      _CreateOrEditTravelPackagePageState();
}

class _CreateOrEditTravelPackagePageState
    extends State<CreateOrEditTravelPackagePage> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  final _formKey = GlobalKey<FormState>();
  TravelPackage _travelPackage = TravelPackage(
    id: '',
    name: '',
    destination: '',
    duration: 0,
    price: 0.0,
    imageUrl: '',
    tags: const [],
    activityPool: [],
  );
  bool isEditMode = false;
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  var _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();
  List<String> _selectedTags = [];
  List<String> _selectedFoodTypes = [];
  String _selectedActivityTypes = '';
  List<String> _tagsList = [];
  List<String> _foodTypesList = [];
  List<String> _activityTypesList = [];
  bool _isLoadingTags = true;
  File? _selectedImage;
  File? _selectedImageFile;
  String? _oldImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchTags();
    _fetchFoodTypes();
    _fetchActivityTypes();
    ensureSignedIn();
    if (widget.packageId != null && widget.packageId!.isNotEmpty) {
      isEditMode = true;
      _fetchTravelPackageData(widget.packageId!);
    }
  }

  Future<void> _fetchTravelPackageData(String packageId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('travel_packages')
              .doc(packageId)
              .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _travelPackage = TravelPackage.fromJson(data);
            _nameController.text = _travelPackage.name;
            _destinationController.text = _travelPackage.destination;
            _durationController.text = _travelPackage.duration.toString();
            _priceController.text = _travelPackage.price.toString();
            _imageUrlController.text = _travelPackage.imageUrl;
            _selectedTags = _travelPackage.tags;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching travel package: $e');
    }
  }

  // tag list for dropdown to prevent nonsense tags entered
  Future<void> _fetchTags() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('taxonomy')
              .doc('tags')
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['values'] != null) {
          setState(() {
            _tagsList = List<String>.from(data['values']);
            _isLoadingTags = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tags: $e');
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  Future<void> _fetchFoodTypes() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('taxonomy')
              .doc('foodTypes')
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['values'] != null) {
          setState(() {
            _foodTypesList = List<String>.from(data['values']);
            _isLoadingTags = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tags: $e');
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  Future<void> _fetchActivityTypes() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('taxonomy')
              .doc('activityTypes')
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['values'] != null) {
          setState(() {
            _activityTypesList = List<String>.from(data['values']);
            _isLoadingTags = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tags: $e');
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  // Pick new image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage(String packageId) async {
    if (_selectedImageFile == null) return null;

    try {
      // Delete old image first (if exists)
      if (_oldImageUrl != null && _oldImageUrl!.isNotEmpty) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(_oldImageUrl!);
          await oldRef.delete();
          print('Old image deleted.');
        } catch (e) {
          print('No old image to delete or failed: $e');
        }
      }

      // Upload new image
      final ref = FirebaseStorage.instance
          .ref()
          .child('travel_packages')
          .child('$packageId.jpg');

      await ref.putFile(_selectedImageFile!);
      final imageUrl = await ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> ensureSignedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> saveToFirestore() async {
    try {
      await ensureSignedIn();
      _saveForm();
      final travelCollection = FirebaseFirestore.instance.collection(
        'travel_packages',
      );

      // if new package, generate ID
      if (!isEditMode && _travelPackage.id.isEmpty) {
        _travelPackage.id = travelCollection.doc().id;
      }

      // Upload or replace image
      final imageUrl = await uploadImage(_travelPackage.id);
      if (imageUrl != null) {
        _travelPackage.imageUrl = imageUrl;
      }

      final packageData = {
        'id': _travelPackage.id,
        'name': _travelPackage.name,
        'destination': _travelPackage.destination,
        'duration': _travelPackage.duration,
        'price': _travelPackage.price,
        'imageUrl': _travelPackage.imageUrl,
        'tags': _travelPackage.tags,
        'activityPool':
            _travelPackage.activityPool.map((a) => a.toJson()).toList(),
        if (isEditMode)
          'updatedAt': FieldValue.serverTimestamp()
        else
          'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await (isEditMode
            ? travelCollection.doc(_travelPackage.id).update(packageData)
            : travelCollection.doc(_travelPackage.id).set(packageData));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Travel Package updated successfully!'
                  : 'Travel Package added successfully!',
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error saving travel package: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save travel package')),
        );
      }

      // Optionally reset form or navigate away
      setState(() {
        _currentStep = 0;
        _travelPackage = TravelPackage(
          id: '',
          name: '',
          destination: '',
          duration: 0,
          price: 0.0,
          imageUrl: '',
          tags: const [],
          activityPool: [],
        );
      });
      // send back to list page
      Navigator.popAndPushNamed(
        context,
        '/staff/manage-travel',
        // (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        _saveForm();
        setState(() {
          if (_currentStep < _totalSteps - 1) {
            _currentStep++;
          }
        });
      }
    } else {
      setState(() {
        if (_currentStep < _totalSteps - 1) {
          _currentStep++;
        }
      });
    }
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _saveForm() {
    _travelPackage.name = _nameController.text;
    _travelPackage.destination = _destinationController.text;
    _travelPackage.duration = int.tryParse(_durationController.text) ?? 0;
    _travelPackage.price = double.tryParse(_priceController.text) ?? 0.0;
    _travelPackage.imageUrl = _imageUrlController.text;
    _travelPackage.tags = _selectedTags;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Travel Package'), elevation: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            color: Colors.blue.shade50,
            child: CustomStepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              stepLabels: const ['Basic Info', 'Activity', 'Review'],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(key: _formKey, child: _buildPackageContent()),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _currentStep < _totalSteps - 1
                            ? _nextStep
                            : () {
                              if (_formKey.currentState!.validate()) {
                                _saveForm();
                                // Handle final submission
                                saveToFirestore();
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(
                                //     content: Text('Travel package created!'),
                                //   ),
                                // );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      _currentStep < _totalSteps - 1 ? 'Next' : 'Submit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageContent() {
    if (_currentStep == 2) {
      _saveForm();
    }

    switch (_currentStep) {
      case 0:
        return _buildBasicInfoForm();
      case 1:
        return _buildStep2Form();
      case 2:
        return _buildStep3Form();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoForm() {
    if (_isLoadingTags) {
      // _fetchTags();
      // _fetchActivityTypes();
      // _fetchFoodTypes();
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Package Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Travel Package Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.card_travel),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the travel package name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _destinationController,
          decoration: const InputDecoration(
            labelText: 'Destination',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter the destination'
                      : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _durationController,
          decoration: const InputDecoration(
            labelText: 'Duration (days)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.schedule),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the duration';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            labelText: 'Price',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the price';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // image picker from gallery
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel Package Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  image:
                      _travelPackage.imageUrl.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(_travelPackage.imageUrl),
                            fit: BoxFit.cover,
                          )
                          : _selectedImageFile != null
                          ? DecorationImage(
                            image: FileImage(_selectedImageFile!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _isUploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : _travelPackage.imageUrl.isNotEmpty ||
                            _selectedImageFile != null
                        ? null
                        : const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            if (_travelPackage.imageUrl.isEmpty && _selectedImage == null)
              const Text(
                'Tap to upload an image',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // multiple dropdown for tags
        MultiSelectDialogField(
          items:
              _tagsList
                  .map((tag) => MultiSelectItem<String>(tag, tag))
                  .toList(),
          title: const Text("Tags"),
          selectedColor: Colors.blueAccent,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          buttonIcon: const Icon(Icons.tag, color: Colors.blue),
          buttonText: const Text(
            "Select Tags",
            style: TextStyle(color: Colors.blue, fontSize: 16),
          ),
          onConfirm: (results) {
            setState(() {
              _selectedTags = List<String>.from(results);
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep2Form() {
    void addActivity() {
      showDialog(
        context: context,
        builder: (context) {
          final _idController = TextEditingController();
          final _nameController = TextEditingController();
          final _durationController = TextEditingController();
          final _locationController = TextEditingController();

          return AlertDialog(
            title: const Text('Add Activity'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(labelText: 'Activity ID'),
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  DropdownButtonFormField<String>(
                    value:
                        _selectedActivityTypes.isNotEmpty
                            ? _selectedActivityTypes
                            : null,
                    items:
                        _activityTypesList.map((tag) {
                          return DropdownMenuItem<String>(
                            value: tag,
                            child: Text(tag),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedActivityTypes = value ?? '');
                    },
                    decoration: const InputDecoration(
                      labelText: 'Activity Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: 'Duration'),
                  ),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),

                  MultiSelectDialogField(
                    items:
                        _foodTypesList
                            .map((tag) => MultiSelectItem<String>(tag, tag))
                            .toList(),
                    title: const Text("Food Types"),
                    selectedColor: Colors.blueAccent,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    buttonIcon: const Icon(Icons.tag, color: Colors.blue),
                    buttonText: const Text(
                      "Select Food Types",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                    onConfirm: (results) {
                      setState(() {
                        _selectedFoodTypes = List<String>.from(results);
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newActivity = Activity(
                    id: _idController.text.trim(),
                    name: _nameController.text.trim(),
                    // type: _typeController.text.trim(),
                    type: _selectedActivityTypes.trim(),
                    duration: _durationController.text.trim(),
                    location: _locationController.text.trim(),
                    foodType: _selectedFoodTypes,
                  );

                  setState(() {
                    _travelPackage.activityPool.add(newActivity);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    }

    void removeActivity(int index) {
      setState(() {
        _travelPackage.activityPool.removeAt(index);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Activities',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Create detailed activities that belong to this travel package.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: addActivity,
          icon: const Icon(Icons.add),
          label: const Text('Add New Activity'),
        ),
        const SizedBox(height: 24),

        if (_travelPackage.activityPool.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _travelPackage.activityPool.length,
            itemBuilder: (context, index) {
              final activity = _travelPackage.activityPool[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    activity.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${activity.type}'),
                      Text('Duration: ${activity.duration}'),
                      Text('Location: ${activity.location}'),
                      if (activity.foodType.isNotEmpty)
                        Text('Food: ${activity.foodType.join(", ")}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => removeActivity(index),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Submit',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Review the travel package details before submitting.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // 🔹 Travel Package Summary
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 ${_travelPackage.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Destination: ${_travelPackage.destination}'),
                Text('Duration: ${_travelPackage.duration} days'),
                Text('Price: \$${_travelPackage.price}'),
                const SizedBox(height: 8),
                if (_travelPackage.tags.isNotEmpty)
                  Text('Tags: ${_travelPackage.tags.join(", ")}'),
                const SizedBox(height: 8),
                if (_travelPackage.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _travelPackage.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 🔹 Activity List Preview
        Text(
          'Activities',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_travelPackage.activityPool.isEmpty)
          const Text('No activities added yet.'),
        if (_travelPackage.activityPool.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _travelPackage.activityPool.length,
            itemBuilder: (context, index) {
              final a = _travelPackage.activityPool[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  title: Text(a.name),
                  subtitle: Text(
                    'Type: ${a.type}\nDuration: ${a.duration}\nLocation: ${a.location}',
                  ),
                ),
              );
            },
          ),

        // const SizedBox(height: 32),
        // Center(
        //   child: ElevatedButton.icon(
        //     onPressed: saveToFirestore,
        //     icon: const Icon(Icons.cloud_upload),
        //     label: const Text('Submit Travel Package'),
        //     style: ElevatedButton.styleFrom(
        //       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        //       textStyle: const TextStyle(
        //         fontSize: 16,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
