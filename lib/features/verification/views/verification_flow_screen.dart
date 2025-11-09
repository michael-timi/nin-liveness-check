import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/verification_controller.dart';
import '../models/verification_models.dart';
import 'widgets/capture_step.dart';
import 'widgets/consent_step.dart';
import 'widgets/failure_step.dart';
import 'widgets/nin_entry_step.dart';
import 'widgets/result_step.dart';
import 'widgets/upload_step.dart';

class VerificationFlowScreen extends StatelessWidget {
  const VerificationFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();

    final Widget body = switch (controller.step) {
      VerificationStep.ninEntry => const NinEntryStep(),
      VerificationStep.consent => const ConsentStep(),
      VerificationStep.capture => const CaptureStep(),
      VerificationStep.uploading => const UploadStep(),
      VerificationStep.result => const ResultStep(),
      VerificationStep.failure => const FailureStep(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('NIN Liveness Verification'),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: body,
        ),
      ),
    );
  }
}
