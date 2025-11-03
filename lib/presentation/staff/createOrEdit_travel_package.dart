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
    tourGuide: '',
    flightDetail: '',
    flightClass: '',
    hotelDetail: '',
    hotelRating: '',
    tags: const [],
    activityPool: [],
    activitiesByDay: [],
  );
  bool isEditMode = false;

  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  final _priceController = TextEditingController();
  var _imageUrlController = TextEditingController();
  var _tourGuideController = TextEditingController();
  final _hotelDetailController = TextEditingController();
  final _hotelRatingController = TextEditingController();
  final _flightClassController = TextEditingController();
  final _flightDetailController = TextEditingController();

  final List<String> _flightClassList = [
    "Economy Class",
    "Business Class",
    "First Class",
    "No Flight Used",
  ];
  final List<String> _hotelRatingList = [
    "1 Star",
    "2 Star",
    "3 Star",
    "4 Star",
    "5 Star",
  ];

  final List<String> _timeSlots = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
    '20:00 - 22:00',
    '22:00 - 00:00',
  ];

  // List<String> selectedSlots = [];
  List<String> _selectedTags = [];
  List<String> _selectedFoodTypes = [];
  String _selectedActivityTypes = '';
  List<String> _tagsList = [];
  List<String> _foodTypesList = [];
  List<String> _flightAirlineList = [];
  List<String> _activityTypesList = [];
  List _staffNames = [];
  bool _isLoadingTags = true;
  bool _isLoadingStaffNames = false;
  File? _selectedImageFile;
  String? _oldImageUrl;
  bool _isSavingLoading = false;
  bool _isUploadingImage = false;
  bool _hasUnsavedChanges = false;
  bool _isSubmitting = false;

  int _currentDay = 1;
  Map<int, List<String>> _takenSlotsByDay = {};
  @override
  void initState() {
    super.initState();
    _fetchTags();
    _fetchFoodTypes();
    _fetchActivityTypes();
    _fetchFlightClass();
    _fetchStaffNames();
    ensureSignedIn();
    if (widget.packageId != null && widget.packageId!.isNotEmpty) {
      isEditMode = true;
      _fetchTravelPackageData(widget.packageId!);
    }

    _nameController.addListener(_markAsChanged);
    _destinationController.addListener(_markAsChanged);
    _durationController.addListener(_markAsChanged);
    _priceController.addListener(_markAsChanged);
    _tourGuideController.addListener(_markAsChanged);
    _hotelDetailController.addListener(_markAsChanged);
    _hotelRatingController.addListener(_markAsChanged);
    _flightClassController.addListener(_markAsChanged);
    _flightDetailController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
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
        debugPrint('Fetched data: ${doc.data()}');

        if (data != null) {
          setState(() {
            _travelPackage = TravelPackage.fromJson(data);
            _travelPackage.activityPool =
                _travelPackage.activitiesByDay
                    .expand((dayList) => dayList)
                    .toList();
            _takenSlotsByDay.clear();
            for (final activity in _travelPackage.activityPool) {
              _takenSlotsByDay[activity.day] ??= [];
              _takenSlotsByDay[activity.day]!.addAll(
                activity.duration.split(',').map((s) => s.trim()),
              );
            }

            // 🧭 Ensure current day starts at 1
            _currentDay = 1;
            _nameController.text = _travelPackage.name;
            _destinationController.text = _travelPackage.destination;
            _durationController.text = _travelPackage.duration.toString();
            _priceController.text = _travelPackage.price.toString();
            _imageUrlController.text = _travelPackage.imageUrl;
            _tourGuideController.text = _travelPackage.tourGuide;
            _hotelDetailController.text = _travelPackage.hotelDetail;
            _hotelRatingController.text = _travelPackage.hotelRating;
            _flightDetailController.text = _travelPackage.flightDetail;
            _flightClassController.text = _travelPackage.flightClass;
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

  Future<void> _fetchStaffNames() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'staff')
              .get();

      final names =
          querySnapshot.docs
              .map((doc) => doc['firstName'] ?? '') // adjust field if needed
              .where((name) => name.isNotEmpty)
              .toList();

      setState(() {
        _staffNames = names;
        _isLoadingStaffNames = false;
      });
    } catch (e) {
      debugPrint('Error fetching staff names: $e');
      setState(() => _isLoadingStaffNames = false);
    }
  }

  Future<void> _fetchFlightClass() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('taxonomy')
              .doc('flightClass')
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['values'] != null) {
          setState(() {
            _flightAirlineList = List<String>.from(data['values']);
            _isLoadingTags = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching class: $e');
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
    setState(() => _isUploadingImage = true);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _selectedImageFile = File(pickedFile.path);
    }
    setState(() {
      _isUploadingImage = false;
    });
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
          // print('Old image deleted.');
        } catch (e) {
          // print('No old image to delete or failed: $e');
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
      // print('Error uploading image: $e');
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

      setState(() => _isSavingLoading = true);

      int totalDays =
          int.tryParse(_durationController.text.split(' ').first) ?? 1;

      // ✅ Check that every day has exactly 8 filled slots
      bool allDaysFilled = true;
      for (int day = 1; day <= totalDays; day++) {
        if ((_takenSlotsByDay[day]?.length ?? 0) < 8) {
          allDaysFilled = false;
          break;
        }
      }

      if (!allDaysFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please fill all 8 activity slots for each day before saving.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isSavingLoading = false);
        return;
      }

      final travelCollection = FirebaseFirestore.instance.collection(
        'travel_packages',
      );
      final user = FirebaseAuth.instance.currentUser;

      // 🆕 Generate ID if new package
      if (!isEditMode && _travelPackage.id.isEmpty) {
        _travelPackage.id = travelCollection.doc().id;
      }

      // 📸 Upload image if new or replaced
      final imageUrl = await uploadImage(_travelPackage.id);
      if (imageUrl != null) {
        _travelPackage.imageUrl = imageUrl;
      }

      // 🔧 Prepare structured data grouped by day
      Map<int, List<Activity>> activitiesByDay = {};
      for (var activity in _travelPackage.activityPool) {
        activitiesByDay.putIfAbsent(activity.day, () => []);
        activitiesByDay[activity.day]!.add(activity);
      }

      // Convert to list form for Firestore
      final activitiesByDayList =
          activitiesByDay.entries.map((entry) {
            return {
              'day': entry.key,
              'activities': entry.value.map((a) => a.toJson()).toList(),
            };
          }).toList();

      final packageData = {
        'id': _travelPackage.id,
        'name': _travelPackage.name,
        'destination': _travelPackage.destination,
        'duration': _travelPackage.duration,
        'price': _travelPackage.price,
        'imageUrl': _travelPackage.imageUrl,
        'tourGuide': _travelPackage.tourGuide,
        'hotelDetail': _travelPackage.hotelDetail,
        'hotelRating': _travelPackage.hotelRating,
        'flightDetail': _travelPackage.flightDetail,
        'flightClass': _travelPackage.flightClass,
        'tags': _travelPackage.tags,
        'creatorId': user?.uid,
        'activitiesByDay': activitiesByDayList,
        if (isEditMode)
          'updatedAt': FieldValue.serverTimestamp()
        else
          'createdAt': FieldValue.serverTimestamp(),
      };

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

      // 🧹 Reset after saving
      setState(() {
        _isSavingLoading = false;
        _currentStep = 0;
        _travelPackage = TravelPackage(
          id: '',
          name: '',
          destination: '',
          duration: 0,
          price: 0.0,
          imageUrl: '',
          hotelDetail: '',
          hotelRating: '',
          flightDetail: '',
          flightClass: '',
          tourGuide: '',
          tags: const [],
          activityPool: [],
          activitiesByDay: [],
        );
        _takenSlotsByDay.clear();
      });

      Navigator.popAndPushNamed(context, '/staff/manage-travel');
    } catch (e) {
      setState(() => _isSavingLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_markAsChanged);
    _destinationController.removeListener(_markAsChanged);
    _durationController.removeListener(_markAsChanged);
    _priceController.removeListener(_markAsChanged);
    _tourGuideController.removeListener(_markAsChanged);
    _hotelDetailController.removeListener(_markAsChanged);
    _hotelRatingController.removeListener(_markAsChanged);
    _flightDetailController.removeListener(_markAsChanged);
    _flightClassController.removeListener(_markAsChanged);
    // _imageUrlController.removeListener(_markAsChanged);
    // _tagsController.removeListener(_markAsChanged);
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
    // _travelPackage.duration = int.tryParse(_durationController.text) ?? 0;
    _travelPackage.duration =
        int.tryParse(_durationController.text.split(' ').first) ?? 0;
    _travelPackage.price = double.tryParse(_priceController.text) ?? 0.0;
    _travelPackage.imageUrl = _imageUrlController.text;
    _travelPackage.tags = _selectedTags;
    _travelPackage.tourGuide = _tourGuideController.text;
    _travelPackage.hotelDetail = _hotelDetailController.text;
    _travelPackage.hotelRating = _hotelRatingController.text;
    _travelPackage.flightDetail = _flightDetailController.text;
    _travelPackage.flightClass = _flightClassController.text;
  }

  // Future<void> _handleBackPress() async {
  //   final shouldPop = await _onWillPop();
  //   if (shouldPop && mounted) {
  //     Navigator.of(context).pop();
  //   }
  // }

  // Check if user can leave
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges || _isSubmitting) {
      return true;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text('Unsaved Changes'),
              ],
            ),
            content: const Text(
              'You have unsaved changes. Are you sure you want to leave? Your changes will be lost.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: AppBar(
          title: Text(
            isEditMode ? 'Update Travel Package ' : 'Add Travel Package',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.blue.shade300,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // color: Colors.blue.shade50,
              child: CustomStepIndicator(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                stepLabels: const ['Basic Info', 'Activities', 'Review '],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(key: _formKey, child: _buildPackageContent()),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        label: const Text('Previous'),
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(
                            color: Colors.blue.shade300,
                            width: 1.5,
                          ),
                        ),
                        // child: const Text('Previous'),
                      ),
                    ),
                  // next & submit button
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isSavingLoading
                              ? null
                              : _currentStep < _totalSteps - 1
                              ? _nextStep
                              : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isSavingLoading = true);
                                  _saveForm();
                                  saveToFirestore();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child:
                          _isSavingLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep < _totalSteps - 1
                                        ? 'Next'
                                        : 'Submit',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      // fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentStep < _totalSteps - 1
                                        ? Icons.arrow_forward
                                        : Icons.check_circle,
                                    size: 20,
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        const Text(
          'Package Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Package Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Package Name',
            hintText: 'e.g., Bali Paradise Adventure',
            prefixIcon: const Icon(Icons.card_travel),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter package name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Destination
        TextFormField(
          controller: _destinationController,
          decoration: InputDecoration(
            labelText: 'Destination',
            hintText: 'e.g., Bali, Indonesia',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter destination'
                      : null,
        ),
        const SizedBox(height: 16),
        // TextFormField(
        //   controller: _tourGuideController,
        //   decoration: InputDecoration(
        //     labelText: 'Tour Guide Name',
        //     // hintText: 'e.g., Bali, Indonesia',
        //     prefixIcon: const Icon(Icons.hail_outlined),
        //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        //     filled: true,
        //     fillColor: Colors.grey.shade50,
        //   ),
        //   validator:
        //       (value) =>
        //           (value == null || value.isEmpty)
        //               ? 'Please enter tour guide name'
        //               : null,
        // ),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _staffNames
                .cast<String>()
                .where(
                  (option) => option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                )
                .toList();
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            _tourGuideController = fieldTextEditingController;
            return TextFormField(
              // controller: fieldTextEditingController,
              controller: _tourGuideController,
              focusNode: fieldFocusNode,
              decoration: InputDecoration(
                labelText: 'Tour Guide Name',
                prefixIcon: const Icon(Icons.hail_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Please enter tour guide name'
                          : null,
            );
          },
          onSelected: (String selection) {
            debugPrint('Selected: $selection');
            _tourGuideController.text = selection;
          },
        ),

        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value:
              _flightClassList.contains(_flightClassController.text)
                  ? _flightClassController.text
                  : null,
          items:
              _flightClassList.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
          onChanged: (value) {
            setState(() => _flightClassController.text = value ?? '');
          },
          decoration: InputDecoration(
            labelText: 'Flight Class',
            prefixIcon: const Icon(Icons.flight_class_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),

        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value:
              _flightAirlineList.contains(_flightDetailController.text)
                  ? _flightDetailController.text
                  : null,
          items:
              _flightAirlineList.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
          onChanged: (value) {
            setState(() => _flightDetailController.text = value ?? '');
          },
          decoration: InputDecoration(
            labelText: 'Flight Detail',
            prefixIcon: const Icon(Icons.flight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),

        const SizedBox(height: 16),
        TextFormField(
          controller: _hotelDetailController,
          decoration: InputDecoration(
            labelText: 'Hotel Detail',
            // hintText: 'e.g., Bali, Indonesia',
            prefixIcon: const Icon(Icons.hotel_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter hotel detail'
                      : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value:
              _hotelRatingList.contains(_hotelRatingController.text)
                  ? _hotelRatingController.text
                  : null,
          items:
              _hotelRatingList.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
          onChanged: (value) {
            setState(() => _hotelRatingController.text = value ?? '');
          },
          decoration: InputDecoration(
            labelText: 'Hotel Rating',
            prefixIcon: const Icon(Icons.hotel_class),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),

        // Duration and Price
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final DateTimeRange? pickedRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDateRange: _selectedDateRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.blue.shade900, // header background
                            onPrimary: Colors.white, // header text color
                            onSurface: Colors.black, // body text color
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.blue.shade900, // button color
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedRange != null) {
                    setState(() {
                      _selectedDateRange = pickedRange;

                      final difference =
                          pickedRange.end.difference(pickedRange.start).inDays +
                          1;
                      _durationController.text = '$difference days';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Travel Duration',
                      hintText: 'Select date range',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please select travel dates'
                                : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Image Upload
        const Text(
          'Cover Photo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  _isUploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedImageFile != null
                      ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                      : _travelPackage.imageUrl.isNotEmpty
                      ? Image.network(
                        _travelPackage.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, trace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tags
        const Text(
          'Tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        MultiSelectDialogField(
          items:
              _tagsList
                  .map((tag) => MultiSelectItem<String>(tag, tag))
                  .toList(),
          title: const Text("Select Tags"),
          selectedColor: Colors.blue,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          buttonIcon: const Icon(Icons.label_outline),
          buttonText: Text(
            _selectedTags.isEmpty
                ? "Select tags"
                : "${_selectedTags.length} selected",
            style: const TextStyle(fontSize: 16),
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
    int totalDays =
        int.tryParse(_durationController.text.split(' ').first) ?? 1;
    bool isDayFull(int day) {
      return (_takenSlotsByDay[day]?.length ?? 0) >= 8;
    }

    bool canAddActivity = !isDayFull(_currentDay);

    void addActivity() {
      showDialog(
        context: context,
        builder: (context) {
          final idController = TextEditingController();
          final nameController = TextEditingController();
          final locationController = TextEditingController();
          List<String> localSelectedSlots = [];

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Activity',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Activity ID
                          TextField(
                            controller: idController,
                            decoration: InputDecoration(
                              labelText: 'Activity ID',
                              prefixIcon: const Icon(Icons.tag),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Activity Name
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Activity Name',
                              prefixIcon: const Icon(Icons.local_activity),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Activity Type
                          DropdownButtonFormField<String>(
                            value:
                                _selectedActivityTypes.isNotEmpty
                                    ? _selectedActivityTypes
                                    : null,
                            items:
                                _activityTypesList
                                    .map(
                                      (type) => DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(
                                () => _selectedActivityTypes = value ?? '',
                              );
                            },
                            decoration: InputDecoration(
                              labelText: 'Activity Type',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Select Duration Slots',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _timeSlots.map((slot) {
                                  // Disable slot if already used for this day
                                  bool isTaken =
                                      _takenSlotsByDay[_currentDay]?.contains(
                                        slot,
                                      ) ??
                                      false;

                                  return FilterChip(
                                    label: Text(slot),
                                    selected: localSelectedSlots.contains(slot),
                                    onSelected:
                                        isTaken
                                            ? null
                                            : (selected) {
                                              setStateDialog(() {
                                                if (selected) {
                                                  localSelectedSlots.add(slot);
                                                } else {
                                                  localSelectedSlots.remove(
                                                    slot,
                                                  );
                                                }
                                              });
                                            },
                                    selectedColor: Colors.blue.shade100,
                                    disabledColor: Colors.grey.shade200,
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Location
                          TextField(
                            controller: locationController,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              prefixIcon: const Icon(Icons.place),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Food Types
                          MultiSelectDialogField(
                            items:
                                _foodTypesList
                                    .map(
                                      (food) =>
                                          MultiSelectItem<String>(food, food),
                                    )
                                    .toList(),
                            title: const Text("Food Options"),
                            selectedColor: Colors.blue,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            buttonIcon: const Icon(Icons.restaurant),
                            buttonText: Text(
                              _selectedFoodTypes.isEmpty
                                  ? "Select food types"
                                  : "${_selectedFoodTypes.length} selected",
                              style: const TextStyle(fontSize: 16),
                            ),
                            onConfirm: (results) {
                              setStateDialog(() {
                                _selectedFoodTypes = List<String>.from(results);
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  if (localSelectedSlots.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select at least one time slot',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // Prevent exceeding 8 slots per day
                                  if ((_takenSlotsByDay[_currentDay]?.length ??
                                              0) +
                                          localSelectedSlots.length >
                                      8) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Maximum 8 slots per day allowed',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final newActivity = Activity(
                                    id: idController.text.trim(),
                                    name: nameController.text.trim(),
                                    type: _selectedActivityTypes.trim(),
                                    duration: localSelectedSlots.join(', '),
                                    location: locationController.text.trim(),
                                    foodType: _selectedFoodTypes,
                                    day: _currentDay,
                                  );

                                  setState(() {
                                    _travelPackage.activityPool.add(
                                      newActivity,
                                    );

                                    // Mark selected slots as taken
                                    _takenSlotsByDay[_currentDay] ??= [];
                                    _takenSlotsByDay[_currentDay]!.addAll(
                                      localSelectedSlots,
                                    );
                                  });

                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Add Activity'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    void removeActivity(int dayActivityIndex) {
      setState(() {
        // Filter activities for the current day
        final dayActivities =
            _travelPackage.activityPool
                .where((a) => a.day == _currentDay)
                .toList();

        if (dayActivityIndex < 0 || dayActivityIndex >= dayActivities.length)
          return;

        final removedActivity = dayActivities[dayActivityIndex];

        // Free up slots for this activity
        final slots = removedActivity.duration.split(',').map((s) => s.trim());
        _takenSlotsByDay[removedActivity.day]?.removeWhere(
          (s) => slots.contains(s),
        );

        // Remove from main activityPool
        _travelPackage.activityPool.removeWhere(
          (a) => a.id == removedActivity.id && a.day == removedActivity.day,
        );
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activities',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Add activities for each travel day',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        Center(
          child: Text(
            'Day $_currentDay of $totalDays',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isDayFull(_currentDay) ? null : addActivity,
            icon: Icon(Icons.add_circle_outline, color: Colors.blue.shade300),
            label: Text(
              isDayFull(_currentDay) ? 'Day Full (8/8 slots)' : 'Add Activity',
              style: TextStyle(
                color:
                    isDayFull(_currentDay)
                        ? Colors.grey.shade400
                        : Colors.blue.shade300,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color:
                    isDayFull(_currentDay)
                        ? Colors.grey.shade300
                        : Colors.blue.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // List Activities
        if (_travelPackage.activityPool.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No activities added yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                _travelPackage.activityPool
                    .where((a) => a.day == _currentDay)
                    .length,
            itemBuilder: (context, index) {
              final dayActivities =
                  _travelPackage.activityPool
                      .where((a) => a.day == _currentDay)
                      .toList();
              final activity = dayActivities[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.category, 'Type', activity.type),
                        _buildDetailRow(
                          Icons.schedule,
                          'Duration',
                          activity.duration,
                        ),
                        _buildDetailRow(
                          Icons.place,
                          'Location',
                          activity.location,
                        ),
                        if (activity.foodType.isNotEmpty)
                          _buildDetailRow(
                            Icons.restaurant,
                            'Food',
                            activity.foodType.join(", "),
                          ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => removeActivity(index),
                    tooltip: 'Remove activity',
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 16),

        // ✅ Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentDay > 1)
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous Day'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: () {
                  setState(() {
                    _currentDay--;
                  });
                },
              ),
            if (_currentDay < totalDays && isDayFull(_currentDay))
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text('Next Day (${_currentDay + 1})'),
                onPressed: () {
                  setState(() {
                    _currentDay++;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // Step 3: Review Form
  Widget _buildStep3Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review & Submit',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your package before submitting',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Package Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _travelPackage.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildSummaryRow(
                Icons.location_on,
                'Destination',
                _travelPackage.destination,
              ),
              _buildSummaryRow(
                Icons.calendar_today,
                'Duration',
                '${_travelPackage.duration} days',
              ),
              _buildSummaryRow(
                Icons.attach_money,
                'Price',
                '\$${_travelPackage.price}',
              ),

              if (_travelPackage.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.label, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            _travelPackage.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ],

              if (_travelPackage.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _travelPackage.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Activities Section
        Row(
          children: [
            const Icon(Icons.local_activity, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_travelPackage.activityPool.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_travelPackage.activityPool.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'No activities added',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _travelPackage.activityPool.length,
            itemBuilder: (context, index) {
              final activity = _travelPackage.activityPool[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${activity.type} • ${activity.duration} • ${activity.location}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (activity.foodType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Food: ${activity.foodType.join(", ")}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
