import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final storeProductsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.instance.get('/store/products');
  return response.data['data'] ?? []; // Assuming paginated response
});

final productDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final response = await ApiClient.instance.get('/store/products/$id');
  return response.data['data'];
});

final knowledgebaseProvider = FutureProvider.family<List<dynamic>, int>((ref, productId) async {
  final response = await ApiClient.instance.get('/store/products/$productId/knowledgebase');
  return response.data['data']?['data'] ?? []; // Assuming paginated
});
