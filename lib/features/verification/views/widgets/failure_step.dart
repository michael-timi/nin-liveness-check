import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/verification_controller.dart';

class FailureStep extends StatelessWidget {
  const FailureStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 96, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            controller.errorMessage ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: controller.retry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
