enum VerificationStep {
  ninEntry,
  consent,
  capture,
  uploading,
  result,
  failure,
}

class VerificationSession {
  VerificationSession({
    required this.sessionId,
    required this.prompts,
    required this.expiresAt,
  });

  final String sessionId;
  final List<LivenessPrompt> prompts;
  final DateTime expiresAt;
}

class LivenessPrompt {
  const LivenessPrompt({
    required this.type,
    required this.description,
  });

  final LivenessPromptType type;
  final String description;
}

enum LivenessPromptType {
  blink,
  smile,
  headTurnLeft,
  headTurnRight,
  speakPhrase,
}

class VerificationResult {
  const VerificationResult({
    required this.passed,
    required this.reason,
    this.referenceId,
  });

  final bool passed;
  final String reason;
  final String? referenceId;
}
