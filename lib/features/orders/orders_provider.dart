import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final ordersListProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.instance.get('/orders');
  return response.data['data']['data'] ?? []; // Assuming paginated
});

final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final response = await ApiClient.instance.get('/orders/$id');
  final rawData = response.data['data'];
  if (rawData is Map<String, dynamic>) {
    if (rawData.containsKey('order') && rawData['order'] is Map<String, dynamic>) {
      final nested = Map<String, dynamic>.from(rawData['order'] as Map);
      if (rawData.containsKey('viewer_offer')) {
        nested['viewer_offer'] = rawData['viewer_offer'];
      }
      return nested;
    }
    return rawData;
  }
  return {};
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
          'content': txt,
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

  Future<bool> awardOffer(int orderId, int offerId) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/orders/$orderId/award',
        data: {'offer_id': offerId},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error awarding offer', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> startWork(int orderId) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post('/orders/$orderId/start');
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error starting order', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deliverWork(int orderId, {String? deliveryNote}) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/orders/$orderId/deliver',
        data: {'delivery_note': deliveryNote},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error delivering order', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> requestRevision(int orderId, String revisionNote) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/orders/$orderId/revision',
        data: {'revision_note': revisionNote},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error requesting revision', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> completeOrder(int orderId, {int? rating, String? review}) async {
    state = const AsyncValue.loading();
    try {
      final payload = <String, dynamic>{};
      if (rating != null) payload['rating'] = rating;
      if (review != null) payload['review'] = review;

      final response = await ApiClient.instance.post(
        '/orders/$orderId/complete',
        data: payload,
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error completing order', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelOrder(int orderId, {String? note}) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/orders/$orderId/cancel',
        data: {'note': note},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error cancelling order', StackTrace.current);
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
