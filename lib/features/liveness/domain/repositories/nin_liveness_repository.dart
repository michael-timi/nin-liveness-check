import '../models/nin_liveness_result.dart';
import '../models/nin_liveness_submission.dart';

abstract class NinLivenessRepository {
  Future<NinLivenessResult> verifyLiveness(NinLivenessSubmission submission);
}
