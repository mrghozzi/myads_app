import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final questsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get('/quests');
  return response.data['data'];
});

class GamificationActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> claimQuest(int questId) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post('/quests/$questId/claim');
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Error claiming quest', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> transferPts(String username, int amount) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/pts/transfer',
        data: {'username': username, 'amount': amount},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Transfer failed', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createVoucher(int amount) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/pts/vouchers/create',
        data: {'amount': amount},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Voucher creation failed', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> claimVoucher(String code) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.post(
        '/pts/vouchers/claim',
        data: {'code': code},
      );
      if (response.data['success'] == true) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(response.data['message'] ?? 'Voucher claim failed', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final gamificationActionProvider = NotifierProvider<GamificationActionNotifier, AsyncValue<void>>(() {
  return GamificationActionNotifier();
});
