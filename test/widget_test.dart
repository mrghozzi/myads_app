import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myads_app/core/models/status_model.dart';
import 'package:myads_app/core/models/user_model.dart';
import 'package:myads_app/core/providers/saved_posts_provider.dart';
import 'package:myads_app/features/posts/widgets/smart_autocomplete_overlay.dart';

void main() {
  group('StatusModel Tests', () {
    test('StatusModel copyWith works accurately for bookmark state', () {
      final user = UserModel(
        id: '1',
        username: 'testuser',
        name: 'Test User',
        avatarUrl: 'https://example.com/avatar.jpg',
        profileBadgeColor: '',
        isVerified: true,
      );

      final status = StatusModel(
        id: 42,
        text: 'Testing #laravel and @admin features',
        type: 'text',
        postKind: 'text',
        createdAt: 'Just now',
        user: user,
        likesCount: 10,
        commentsCount: 2,
        repostsCount: 1,
        hasLiked: false,
        groupedReactions: {},
        interactionSubjectId: 42,
        reactionType: 2,
        hasSaved: false,
      );

      expect(status.hasSaved, false);

      final updated = status.copyWith(hasSaved: true);
      expect(updated.hasSaved, true);
      expect(updated.id, 42);
      expect(updated.text, status.text);
      expect(updated.user.username, 'testuser');
      expect(status.hasSaved, false); // Original remains immutable
    });

    test('StatusModel.fromJson parses has_saved and is_saved properly', () {
      final json1 = {
        'id': 101,
        'text': 'Post with has_saved',
        'has_saved': true,
        'user': {'id': '1', 'username': 'alice'},
      };
      final model1 = StatusModel.fromJson(json1);
      expect(model1.hasSaved, true);

      final json2 = {
        'id': 102,
        'text': 'Post with is_saved',
        'is_saved': true,
        'user': {'id': '2', 'username': 'bob'},
      };
      final model2 = StatusModel.fromJson(json2);
      expect(model2.hasSaved, true);
    });
  });

  group('SavedPostsState Tests', () {
    test('Initial state is correct', () {
      final state = SavedPostsState.initial();
      expect(state.statuses, isEmpty);
      expect(state.currentPage, 1);
      expect(state.isLoading, true);
      expect(state.isLoadingMore, false);
      expect(state.error, isNull);
    });

    test('copyWith updates state correctly', () {
      final state = SavedPostsState.initial();
      final updated = state.copyWith(
        isLoading: false,
        error: 'Network Error',
      );
      expect(updated.isLoading, false);
      expect(updated.error, 'Network Error');
    });
  });

  group('SmartAutocomplete Widget Smoke Tests', () {
    testWidgets('SmartAutocompleteOverlay renders and reacts to controller', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: controller),
                SmartAutocompleteOverlay(controller: controller),
              ],
            ),
          ),
        ),
      );

      // Initially nothing shown
      expect(find.byType(SmartAutocompleteOverlay), findsOneWidget);
      expect(find.text('Suggested Users'), findsNothing);
      expect(find.text('Suggested Hashtags'), findsNothing);

      // Type a mention
      controller.text = '@adm';
      controller.selection = const TextSelection.collapsed(offset: 4);
      await tester.pump();

      // Ensure widget didn't crash
      expect(find.byType(SmartAutocompleteOverlay), findsOneWidget);
    });
  });
}
