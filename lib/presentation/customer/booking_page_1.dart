import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel2u_v1/core/models/travel_package.dart';

class BookingPage1 extends StatefulWidget {
  final TravelPackage package;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic> initialData;

  const BookingPage1({
    super.key,
    required this.package,
    required this.onDataChanged,
    required this.initialData,
  });

  @override
  State<BookingPage1> createState() => _BookingPage1State();
}

class _BookingPage1State extends State<BookingPage1> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController paxCtrl;
  final TextEditingController _travelDateController = TextEditingController();
  DateTime? selectedDate;
  int maxNumTravelers = 1;

  int get safeTravelerCount {
    final parsed = int.tryParse(paxCtrl.text) ?? 1;
    return parsed.clamp(1, maxNumTravelers);
  }

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(text: widget.initialData["name"] ?? "");
    emailCtrl = TextEditingController(text: widget.initialData["email"] ?? "");
    phoneCtrl = TextEditingController(text: widget.initialData["phone"] ?? "");
    paxCtrl = TextEditingController(
      text: widget.initialData["numTravelers"]?.toString() ?? "",
    );

    // if (widget.initialData["travelDate"] != null) {
    //   // selectedDate = DateTime.tryParse(widget.initialData["travelDate"]);
    //   _travelDateController.text = DateFormat(
    //     'dd/MM/yyyy',
    //   ).format(widget.initialData['travelDate']);
    //   ;
    // }
    if (widget.package.travelDate != null) {
      final date = DateFormat("dd/MM/yyyy").format(
        DateTime.parse(
          widget.package.travelDate.toLocal().toString(),
        ).toLocal(),
      );
      if (date != null) {
        _travelDateController.text = date;
      }
    }
    if (widget.package.paxType == 'Solo') {
      maxNumTravelers = 1;
      paxCtrl.text = '1';
    } else if (widget.package.paxType == 'Group') {
      maxNumTravelers = 30;
    } else if (widget.package.paxType == 'Family') {
      maxNumTravelers = 10;
    }

    // _travelDateController.text =
    // DateFormat('dd/MM/yyyy').format(pickedRange.start);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package Image + Title + Tags
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              SizedBox(
                height: 200,
                width: double.infinity,
                child:
                    pkg.imageUrl.isNotEmpty
                        ? Image.network(
                          pkg.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF0064D2),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        )
                        : Container(
                          color: const Color(0xFF0064D2),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
              ),

              // Info Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Color(0xFF0064D2),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pkg.destination,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF687089),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 18,
                            color: Color(0xFF0064D2),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${pkg.duration} days',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (pkg.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            pkg.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF687089),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Flight Details
        _buildInfoCard(
          icon: Icons.flight,
          title: 'Flight Details',
          children: [
            _buildDetailRow('Airline', pkg.flightDetail),
            const SizedBox(height: 12),
            _buildDetailRow('Class', pkg.flightClass),
          ],
        ),

        // Hotel Details
        _buildInfoCard(
          icon: Icons.hotel,
          title: 'Accommodation',
          children: [
            _buildDetailRow('Hotel', pkg.hotelDetail),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rating',
                  style: TextStyle(fontSize: 14, color: Color(0xFF687089)),
                ),
                Row(
                  children: [
                    ...List.generate(
                      int.parse(pkg.hotelRating.split(' ')[0]),
                      (index) => const Icon(
                        Icons.star,
                        size: 18,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pkg.hotelRating,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Tour Guide
        _buildInfoCard(
          icon: Icons.person,
          title: 'Tour Guide',
          children: [
            const SizedBox(height: 4),
            Text(
              pkg.tourGuide,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Traveler input section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                // controller: _travelerController,
                enabled: maxNumTravelers != 1,
                controller: paxCtrl,
                decoration: const InputDecoration(
                  labelText: 'Number of Travelers',
                  hintText: 'e.g. 2',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  final num? parsed = num.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid number';
                  }
                  if (parsed > maxNumTravelers) {
                    return 'Maximum number is $maxNumTravelers';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
                onSaved: (value) {
                  // final numTravelers = int.tryParse(value ?? '') ?? 1;
                  widget.onDataChanged({
                    "packageName": pkg.name,
                    "name": nameCtrl.text,
                    "email": emailCtrl.text,
                    "phone": phoneCtrl.text,
                    "numTravelers": int.tryParse(paxCtrl.text) ?? 1,
                    // "travelDate": selectedDate?.toIso8601String(),
                    "travelDate": widget.package.travelDate.toIso8601String(),
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF687089),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    // valueListenable: _travelerController,
                    valueListenable: paxCtrl,
                    builder: (context, value, _) {
                      // final travelers = int.tryParse(value.text) ?? 1;
                      final travelers = safeTravelerCount;
                      final total = travelers * pkg.price;
                      return Text(
                        'RM ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5C00),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Travel Date",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _travelDateController.text,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),

              // if (selectedDate != null)
              //   Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //         'End Date: ${selectedDate!.add(Duration(days: pkg.duration - 1)).day}/'
              //         '${selectedDate!.add(Duration(days: pkg.duration - 1)).month}/'
              //         '${selectedDate!.add(Duration(days: pkg.duration - 1)).year}',
              //         style: const TextStyle(
              //           fontSize: 14,
              //           color: Color(0xFF687089),
              //         ),
              //       ),
              //     ],
              //   ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF0064D2)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF687089)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
