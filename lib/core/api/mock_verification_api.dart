import 'dart:math';

import '../../features/verification/models/verification_models.dart';

class MockVerificationApi {
  Future<VerificationSession> createSession({required String nin}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final prompts = <LivenessPrompt>[
      const LivenessPrompt(
        type: LivenessPromptType.blink,
        description: 'Blink twice while looking at the camera.',
      ),
      const LivenessPrompt(
        type: LivenessPromptType.headTurnLeft,
        description: 'Turn your head slowly to the left.',
      ),
      const LivenessPrompt(
        type: LivenessPromptType.speakPhrase,
        description: 'Say: “I confirm this is my NIN verification”.',
      ),
    ];

    return VerificationSession(
      sessionId: 'SESSION-${DateTime.now().millisecondsSinceEpoch}',
      prompts: prompts,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  Future<void> uploadEvidence({
    required String sessionId,
    required List<int> selfieBytes,
    required Map<String, dynamic> metadata,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<VerificationResult> fetchResult({required String sessionId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final passed = Random().nextBool();

    return VerificationResult(
      passed: passed,
      reason: passed
          ? 'Liveness confirmed and NIN record matched.'
          : 'Face mismatch detected. Please retry in a well-lit environment.',
      referenceId: 'VRF-${Random().nextInt(999999).toString().padLeft(6, '0')}',
    );
  }
}
