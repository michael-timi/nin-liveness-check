import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/verification_controller.dart';

class ResultStep extends StatelessWidget {
  const ResultStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();
    final result = controller.result;

    if (result == null) {
      return const Center(child: Text('Awaiting result...'));
    }

    final color = result.passed ? Colors.green : Colors.orange;
    final icon = result.passed ? Icons.check_circle : Icons.warning_amber;
    final title = result.passed ? 'Verification succeeded' : 'Verification pending review';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: color),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            result.reason,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (result.referenceId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Reference: ${result.referenceId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: controller.retry,
            child: const Text('Start a new verification'),
          ),
        ],
      ),
    );
  }
}
