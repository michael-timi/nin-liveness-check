import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/verification_controller.dart';

class NinEntryStep extends StatefulWidget {
  const NinEntryStep({super.key});

  @override
  State<NinEntryStep> createState() => _NinEntryStepState();
}

class _NinEntryStepState extends State<NinEntryStep> {
  final _formKey = GlobalKey<FormState>();
  final _ninController = TextEditingController();

  @override
  void dispose() {
    _ninController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify your identity',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your 11-digit National Identification Number (NIN) to begin the liveness verification process.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _ninController,
              decoration: const InputDecoration(
                labelText: 'NIN',
                border: OutlineInputBorder(),
                hintText: '12345678901',
              ),
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'NIN is required';
                }
                if (value.length != 11) {
                  return 'NIN must be 11 digits';
                }
                return null;
              },
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.isProcessing
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        controller.submitNin(_ninController.text);
                      }
                    },
              child: controller.isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start verification'),
            ),
          ),
        ],
      ),
    );
  }
}
