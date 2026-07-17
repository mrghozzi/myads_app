import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final ordersListProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.instance.get('/orders');
  return response.data['data']['data'] ?? []; // Assuming paginated
});

final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final response = await ApiClient.instance.get('/orders/$id');
  return response.data['data'];
});

class OrderActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> submitOffer(int orderId, String txt, int price, int deliveryDays) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/orders/$orderId/offers',
        data: {
          'txt': txt,
          'price': price,
          'delivery_days': deliveryDays,
        },
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error submitting offer', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderActionProvider = NotifierProvider<OrderActionNotifier, AsyncValue<void>>(() {
  return OrderActionNotifier();
});
