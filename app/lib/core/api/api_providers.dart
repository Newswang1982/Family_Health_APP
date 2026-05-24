import 'api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for the singleton ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});
