import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import 'package:myads_app/features/settings/screens/settings_hub_screen.dart';
import 'package:myads_app/features/profile/profile_provider.dart';
import 'package:myads_app/core/models/user_profile_model.dart';

void main() {
  testWidgets('SettingsHubScreen displays correctly', (WidgetTester tester) async {
    final mockProfile = UserProfileModel(
      id: 1,
      username: 'testuser',
      name: 'Test User',
      avatar: '',
      pts: 0,
      verified: false,
      bio: '',
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      createdAt: '',
      online: true,
      cover: '',
      isFollowing: false,
      socialLinks: {},
      badges: [],
      profileBadgeColor: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileDetailProvider('me').overrideWith((ref) => mockProfile),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('ar'),
          ],
          home: SettingsHubScreen(),
        ),
      ),
    );

    // Initial state is loaded immediately due to mock
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('@testuser'), findsOneWidget);
    expect(find.text('Edit Profile'), findsNWidgets(2)); // One in header, one in list
    expect(find.text('Privacy'), findsOneWidget);
  });
}
