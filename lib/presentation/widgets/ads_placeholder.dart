import 'package:flutter/material.dart';

Widget buildAdsPlaceholder() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    padding: const EdgeInsets.all(20),
    height: 120,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: Text(
        "Ad Placeholder",
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    ),
  );
}
