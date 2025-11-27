import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReviewPage extends StatefulWidget {
  final String bookingId;
  final String packageId;
  final String mode; // "add", "edit", "view"
  final String? reviewId;

  const ReviewPage({
    super.key,
    required this.bookingId,
    required this.packageId,
    required this.mode,
    this.reviewId,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  List<File> _localImages = [];
  List<String> _existingImages = [];

  double _rating = 0;
  bool _agree = false;
  bool _loading = true;
  bool _submitting = false;

  bool get isView => widget.mode == "view";
  bool get isEdit => widget.mode == "edit";
  bool get isAdd => widget.mode == "add";

  @override
  void initState() {
    super.initState();
    if (isEdit || isView) {
      _loadExistingReview();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadExistingReview() async {
    final snap =
        await FirebaseFirestore.instance
            .collection("reviews")
            .doc(widget.reviewId)
            .get();

    if (snap.exists) {
      _rating = snap.data()?["rating"] ?? 0;
      _reviewController.text = snap.data()?["review"] ?? "";
      _existingImages = List<String>.from(snap.data()?["images"] ?? []);
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: Text(
          isView
              ? "View Review"
              : isEdit
              ? "Edit Review"
              : "Write a Review",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  Icon(
                    isView
                        ? Icons.rate_review_rounded
                        : Icons.edit_note_rounded,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isView
                        ? "Your Travel Review"
                        : isEdit
                        ? "Update Your Experience"
                        : "Share Your Experience",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isView
                        ? "View your shared feedback"
                        : "Help others plan their perfect trip",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AbsorbPointer(
                  absorbing: isView,
                  child: Opacity(
                    opacity: isView ? 0.85 : 1,
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRating(),
                            const SizedBox(height: 28),
                            _buildReviewInput(),
                            const SizedBox(height: 28),
                            _buildImagesSection(),
                            const SizedBox(height: 28),
                            if (!isView) _buildPolicyCheckbox(),
                            if (!isView) const SizedBox(height: 24),
                            if (!isView) _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ⭐ RATING SECTION
  Widget _buildRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Rate Your Experience",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1a1a),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final isSelected = i < _rating;
              return GestureDetector(
                onTap: isView ? null : () => setState(() => _rating = i + 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 40,
                    color: isSelected ? Colors.amber[600] : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Share Your Experience",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1a1a),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reviewController,
          maxLines: 6,
          readOnly: isView,
          style: const TextStyle(fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText:
                "Tell us about your journey, highlights, and memorable moments...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            // enabledBorder: OutlineInputBorder(
            //   borderRadius: BorderRadius.circular(16),
            //   borderSide: BorderSide(color: Colors.grey[200]!),
            // ),
            // focusedBorder: OutlineInputBorder(
            //   borderRadius: BorderRadius.circular(16),
            //   borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            // ),
            contentPadding: const EdgeInsets.all(12),
          ),
          validator:
              (v) =>
                  v == null || v.isEmpty
                      ? "Please share your experience"
                      : null,
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    final hasImages = _existingImages.isNotEmpty || _localImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Add Photos",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1a1a),
              ),
            ),
            const Spacer(),
            if (hasImages)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_existingImages.length + _localImages.length} ${(_existingImages.length + _localImages.length) == 1 ? 'photo' : 'photos'}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Share moments from your trip",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Images Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Existing network images
            ..._existingImages.map(
              (url) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(url, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Local images
            ..._localImages.map(
              (img) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(img, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Add photo button
            if (!isView)
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Add Photo",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ☑ CHECKBOX
  Widget _buildPolicyCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              activeColor: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showPrivacyDialog,
              child: Text.rich(
                TextSpan(
                  text: "I agree with the  ",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1a1a1a),
                  ),
                  children: [
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SUBMIT BUTTON
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[600]!],
        ),
        boxShadow: [
          BoxShadow(
            // color: Colors.blue[700]!.withOpacity(0.3),
            color: Colors.grey[700]!.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            _submitting
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEdit ? Icons.check_circle_rounded : Icons.send_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? "Update Review" : "Submit Review",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // PICK IMAGE
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _localImages.add(File(picked.path)));
    }
  }

  // PRIVACY DIALOG
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.privacy_tip_rounded,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Privacy Policy",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "We are committed to protecting your privacy. This policy explains what information we collect and how we use it.",
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  SizedBox(height: 12),

                  Text(
                    "Information We Collect",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "We collect personal data like your name, email, phone number, and booking details when you create an account and book a package. We also collect anonymous usage data to improve the app.",
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "How We Use Your Information",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Your data is primarily used to process your bookings, communicate trip details, and provide customer support. We only share essential booking information with our travel partners (hotels/guides) to fulfill your trip.",
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Security",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "We use industry-standard security measures to protect your information and do not sell your personal data to third parties.",
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      return _showToast("Please give a star rating");
    }
    if (!_agree) {
      return _showToast("You must agree with the Privacy Policy");
    }

    setState(() => _submitting = true);

    try {
      String uid = user!.uid;

      List<String> imageUrls = [..._existingImages];
      for (var file in _localImages) {
        final ref = FirebaseStorage.instance.ref(
          "reviews/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg",
        );
        await ref.putFile(file);
        imageUrls.add(await ref.getDownloadURL());
      }

      final data = {
        "bookingId": widget.bookingId,
        "packageId": widget.packageId,
        "rating": _rating,
        "review": _reviewController.text.trim(),
        "images": imageUrls,
        "edited": isEdit,
        "timestamp": FieldValue.serverTimestamp(),
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection("reviews")
            .doc(widget.reviewId)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection("reviews").add(data);
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showToast("Failed to submit review");
    }

    setState(() => _submitting = false);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
