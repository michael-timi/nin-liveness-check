import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/verification_controller.dart';

class ConsentStep extends StatelessWidget {
  const ConsentStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${controller.nin ?? 'user'}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Before we start, we need your consent to capture live images and audio. '
            'This data will only be used to verify that you are a live person and to match your NIN profile.',
          ),
          const SizedBox(height: 24),
          const _ConsentPoint(
            icon: Icons.light_mode,
            text: 'Find a bright, shadow-free environment.',
          ),
          const _ConsentPoint(
            icon: Icons.remove_red_eye,
            text: 'Look straight at the camera. Remove glasses or hats.',
          ),
          const _ConsentPoint(
            icon: Icons.volume_up,
            text:
                'You may be asked to read a short sentence aloud to confirm liveness.',
          ),
          const Spacer(),
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  controller.isProcessing ? null : controller.requestPermissions,
              child: controller.isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('I consent & allow camera access'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
