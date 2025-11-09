import 'package:dio/dio.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../domain/models/nin_liveness_result.dart';
import '../../domain/models/nin_liveness_submission.dart';

class NinLivenessApiClient {
  NinLivenessApiClient(this._dio, {required this.baseUrl});

  final Dio _dio;
  final String baseUrl;

  Future<NinLivenessResult> verify(NinLivenessSubmission submission) async {
    final formData = FormData.fromMap({
      ...submission.toJson(),
      'video': MultipartFile.fromBytes(
        submission.videoBytes,
        filename: submission.fileName,
      ),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/liveness/verify',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final payload = response.data ?? <String, dynamic>{};
      final verifiedAtRaw = payload['verified_at'] as String?;
      return NinLivenessResult(
        isLive: payload['is_live'] as bool? ?? false,
        confidenceScore: (payload['confidence'] as num?)?.toDouble() ?? 0,
        referenceId: payload['reference_id'] as String? ?? '',
        message: payload['message'] as String? ?? 'No response message provided.',
        verifiedAt: verifiedAtRaw != null
            ? DateTime.tryParse(verifiedAtRaw) ?? DateTime.now().toUtc()
            : DateTime.now().toUtc(),
      );
    } on DioException catch (error, stackTrace) {
      final message = error.response?.data?['message']?.toString() ??
          'Unable to verify liveness at this time.';
      throw AppException(message, cause: error, stackTrace: stackTrace);
    } catch (error, stackTrace) {
      throw AppException(
        'Unexpected error occurred while verifying liveness.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
