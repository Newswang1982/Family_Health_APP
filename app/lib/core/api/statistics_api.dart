import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import 'api_client.dart';

final statisticsApiProvider = Provider<StatisticsApi>((ref) {
  return StatisticsApi(ref.read(apiClientProvider));
});

class StatisticsApi {
  final ApiClient _client;

  StatisticsApi(this._client);

  Future<Map<String, dynamic>> getStatistics(
    String profileId,
    String indicatorType, {
    String period = 'month',
  }) async {
    final response = await _client.get(
      '/statistics/$profileId/$indicatorType',
      queryParameters: {'period': period},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getKLine(
    String profileId,
    String indicatorType, {
    String period = 'day',
  }) async {
    final response = await _client.get(
      '/statistics/$profileId/$indicatorType/kline',
      queryParameters: {'period': period},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCorrelation(
    String profileId, {
    String period = 'month',
  }) async {
    final response = await _client.get(
      '/statistics/$profileId/correlation',
      queryParameters: {'period': period},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrends(
    String profileId, {
    String period = 'month',
  }) async {
    final response = await _client.get(
      '/statistics/$profileId/trends',
      queryParameters: {'period': period},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateReport(
    String profileId, {
    String period = 'month',
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{'period': period};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;
    final response = await _client.post(
      '/reports/generate/$profileId',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}
