import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_profile_model.dart';
import '../../core/network/api_client.dart';

// Profile Detail Provider using FutureProvider (highly compatible)
final profileDetailProvider = FutureProvider.family.autoDispose<UserProfileModel, String>((ref, username) async {
  final response = await ApiClient.instance.get('/profile/$username');
  final data = response.data;
  
  if (data is Map) {
    if (data.containsKey('data')) {
      return UserProfileModel.fromJson(data['data']);
    }
    return UserProfileModel.fromJson(data as Map<String, dynamic>);
  }
  throw Exception('Failed to parse profile data');
});
