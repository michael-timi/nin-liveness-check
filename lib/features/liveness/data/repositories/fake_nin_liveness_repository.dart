import 'dart:math';

import '../../domain/entities/liveness_action.dart';
import '../../domain/models/nin_liveness_result.dart';
import '../../domain/models/nin_liveness_submission.dart';
import '../../domain/repositories/nin_liveness_repository.dart';

class FakeNinLivenessRepository implements NinLivenessRepository {
  FakeNinLivenessRepository({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Future<NinLivenessResult> verifyLiveness(
    NinLivenessSubmission submission,
  ) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final hasRequiredActions = submission.actions.contains(LivenessAction.blink) &&
        submission.actions.contains(LivenessAction.turnHeadLeft) &&
        submission.actions.contains(LivenessAction.turnHeadRight);

    final isLive = hasRequiredActions && submission.videoBytes.isNotEmpty;

    final confidence = isLive ? 0.85 + _random.nextDouble() * 0.1 : 0.0;

    return NinLivenessResult(
      isLive: isLive,
      confidenceScore: double.parse(confidence.toStringAsFixed(3)),
      referenceId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      message: isLive
          ? 'Liveness confirmed. Ready for verification.'
          : 'Liveness check failed. Ensure all prompts are completed.',
      verifiedAt: DateTime.now().toUtc(),
    );
  }
}
