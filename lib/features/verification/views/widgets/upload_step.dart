import 'package:flutter/material.dart';

class UploadStep extends StatelessWidget {
  const UploadStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Uploading evidence securely...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
