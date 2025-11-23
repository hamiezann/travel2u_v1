import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

Widget buildImageSlider() {
  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true,
      height: 180,
      enlargeCenterPage: true,
      viewportFraction: 0.9,
    ),
    // why my assets not showing?
    items:
        ['assets/banner1.jpg', 'assets/banner2.jpg', 'assets/banner3.jpg'].map((
          img,
        ) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(img, fit: BoxFit.cover, width: double.infinity),
          );
        }).toList(),
  );
}
