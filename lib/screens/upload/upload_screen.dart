import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share a Hidden Gem')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Upload Discovery',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Post new places, photos, and reviews here.'),
          ],
        ),
      ),
    );
  }
}