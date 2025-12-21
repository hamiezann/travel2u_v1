import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel2u_v1/core/models/travel_package.dart';
import 'package:travel2u_v1/core/services/itinerary_service.dart';
import 'package:travel2u_v1/core/services/notification_service.dart';
import 'package:travel2u_v1/presentation/customer/booking_page_1.dart';
import 'package:travel2u_v1/presentation/customer/booking_page_2.dart';
import 'package:travel2u_v1/presentation/customer/booking_page_3.dart';
import 'package:travel2u_v1/presentation/widgets/custom_message_popup.dart';
import 'package:travel2u_v1/presentation/widgets/custom_step_indicator.dart';

class BookingPage extends StatefulWidget {
  final String packageId;
  const BookingPage({super.key, required this.packageId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int currentStep = 0;
  final int _totalSteps = 3;
  final _formKey = GlobalKey<FormState>();

  bool _hasUnsavedChanges = false;
  bool _isSubmitting = false;
  bool _isSavingLoading = false;

  final GlobalKey<BookingPage2State> _bookingPage2Key =
      GlobalKey<BookingPage2State>();

  TravelPackage? _package;
  Map<String, dynamic> _bookingData = {};
  String packageName = '';
  String creatorId = '';
  late String userName;
  @override
  void initState() {
    super.initState();
    _fetchPackageDetails(widget.packageId);
    _fetchUserDetail();
  }

  Future<void> _fetchPackageDetails(String packageId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('travel_packages')
              .doc(packageId)
              .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _package = TravelPackage.fromJson({...data, 'id': doc.id});
            creatorId = data['creatorId'];
            packageName = data['name'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching package: $e');
    }
  }

  Future<void> _fetchUserDetail() async {
    final userid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userid)
              .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          userName = data['firstName'] ?? "Client A";
        }
      }
    } catch (e) {
      debugPrint('Error fetching package: $e');
    }
  }

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

  void _autoSaveBookingPage2() {
    // if (_bookingPage2Key.currentState != null) {
    //   final data = _bookingPage2Key.currentState!.getBookingData();
    //   _updateBookingData(data);
    // }
    _bookingPage2Key.currentState?.saveToParent();
  }

  void _nextStep() async {
    if (currentStep == 1) {
      _autoSaveBookingPage2();
    }

    if (currentStep == 0 || currentStep == 1) {
      if (!_formKey.currentState!.validate()) {
        MessagePopup.show(
          context,
          message: "Please complete all required fields",
          type: MessageType.warning,
          position: PopupPosition.top,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      _formKey.currentState!.save();
    }

    setState(() {
      if (currentStep < _totalSteps - 1) currentStep++;
    });
  }

  void _previousStep() {
    if (currentStep == 1) {
      _autoSaveBookingPage2();
    }

    setState(() {
      if (currentStep > 0) currentStep--;
    });
  }

  void _updateBookingData(Map<String, dynamic> data) {
    setState(() {
      _bookingData.addAll(data);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingLoading = true);

    await _bookingPage2Key.currentState?.savePreferencesToFirestore();

    try {
      final bookingCollection = FirebaseFirestore.instance.collection(
        'bookings',
      );

      final docRef = bookingCollection.doc();
      final bookingData = {
        ..._bookingData,
        'id': docRef.id,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'packageId': widget.packageId,
        'status': 'booked',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(bookingData);
      final userId =
          bookingData['userId'] ?? FirebaseAuth.instance.currentUser?.uid;

      final result = await ItineraryService.generateUserItinerary(
        userId: userId ?? '',
        packageId: widget.packageId,
        userPrefs: bookingData['preferences'] ?? {},
        packageDuration: _package!.duration,
      );

      final updateData = <String, dynamic>{
        'itineraryStatus': result['success'] == true ? 'generated' : 'failed',
        'itineraryGeneratedAt': FieldValue.serverTimestamp(),
      };
      if (result['success'] == true && result['itineraryId'] != null) {
        updateData['itineraryId'] = result['itineraryId'];
      } else {
        updateData['itineraryError'] = result['message'] ?? 'Unknown error';
      }
      await docRef.update(updateData);
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("wishlist")
          .doc(widget.packageId)
          .delete();

      await NotificationService().sendNotification(
        title: "New Booking!",
        body: "$userName booked $packageName package.",
        userId: creatorId,
        data: {"type": "new-booking"},
      );

      if (!mounted) return;
      setState(() {
        _isSavingLoading = false;
        _isSubmitting = true;
      });

      MessagePopup.show(
        context,
        message:
            result['success'] == true
                ? 'Booking submitted! Itinerary pending approval.'
                : 'Booking submitted but itinerary generation failed. Staff will verify.',
        type:
            result['success'] == true
                ? MessageType.success
                : MessageType.warning,
        position: PopupPosition.top,
        duration: const Duration(seconds: 2),
      );

      Navigator.pop(context);
    } catch (e, st) {
      // debugPrint('Error submitting booking: $e\n$st');
      MessagePopup.show(
        context,
        message: "Failed to submit booking: $e",
        type: MessageType.error,
        position: PopupPosition.top,
        duration: const Duration(seconds: 4),
      );
      setState(() => _isSavingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        body:
            _package == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Container(height: 20, color: Colors.white),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
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
                      child: CustomStepIndicator(
                        currentStep: currentStep,
                        totalSteps: _totalSteps,
                        stepLabels: const [
                          'Package Info',
                          'User Details',
                          'Review',
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Form(
                            key: _formKey,
                            child: _buildPackageContent(),
                          ),
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
                          if (currentStep > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.arrow_back, size: 20),
                                label: const Text('Previous'),
                                onPressed: _previousStep,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(
                                    color: Colors.blue.shade300,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          if (currentStep > 0) const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isSavingLoading
                                      ? null
                                      : currentStep < _totalSteps - 1
                                      ? _nextStep
                                      : _submitBooking,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentStep < _totalSteps - 1
                                                ? 'Next'
                                                : 'Submit',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            currentStep < _totalSteps - 1
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
    switch (currentStep) {
      case 0:
        return BookingPage1(
          package: _package!,
          onDataChanged: _updateBookingData,
          initialData: _bookingData,
        );
      case 1:
        return BookingPage2(
          key: _bookingPage2Key,
          numTravelers: _bookingData['numTravelers'] ?? 1,
          initialData: _bookingData,
          onDataSaved: _updateBookingData,
        );
      case 2:
        return BookingPage3(
          package: _package!.toJson(),
          bookingData: _bookingData,
          onConfirm: _submitBooking,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
