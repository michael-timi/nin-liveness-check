import '../datasources/nin_liveness_api_client.dart';
import '../../domain/models/nin_liveness_result.dart';
import '../../domain/models/nin_liveness_submission.dart';
import '../../domain/repositories/nin_liveness_repository.dart';

class RemoteNinLivenessRepository implements NinLivenessRepository {
  RemoteNinLivenessRepository(this._apiClient);

  final NinLivenessApiClient _apiClient;

  @override
  Future<NinLivenessResult> verifyLiveness(
    NinLivenessSubmission submission,
  ) {
    return _apiClient.verify(submission);
  }
}
