import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myads_app/core/widgets/formatted_content_widget.dart';
import 'package:myads_app/l10n/app_localizations.dart';

void main() {
  Widget createTestWidget({
    required Widget child,
    Locale locale = const Locale('ar'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: child,
          ),
        ),
      ),
    );
  }

  group('FormattedContentWidget Expandable Tests', () {
    testWidgets('Short text does not show See More button in Arabic', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const FormattedContentWidget(
            content: 'منشور قصير جداً للتجربة فقط',
            isExpandable: true,
            collapsedMaxLines: 5,
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('منشور قصير جداً للتجربة فقط'), findsOneWidget);
      expect(find.text('رؤية المزيد'), findsNothing);
      expect(find.text('See more'), findsNothing);
    });

    testWidgets('Long text shows "رؤية المزيد" in Arabic and toggles expansion', (tester) async {
      const longArabicText = '''هذا نص منشور طويل جداً يحتوي على عدة أسطر وفقرات متعددة.
السطر الثاني من المنشور للاختبار.
السطر الثالث للمنشور لمعرفة ما إذا كان يقتطع النص بشكل سليم.
السطر الرابع يحتوي على تفاصيل إضافية مفيدة للمستخدمين.
السطر الخامس للتأكد من تجاوز الحد الأقصى للأعمدة المحددة.
السطر السادس لمزيد من النصوص والمعلومات.
السطر السابع والنهائي للمنشور للتأكد من عمل زر رؤية المزيد وتمديد النص بالكامل.''';

      await tester.pumpWidget(
        createTestWidget(
          child: const FormattedContentWidget(
            content: longArabicText,
            isExpandable: true,
            collapsedMaxLines: 4,
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the "رؤية المزيد" button
      expect(find.text('رؤية المزيد'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap on "رؤية المزيد"
      await tester.tap(find.text('رؤية المزيد'));
      await tester.pumpAndSettle();

      // Should now show "رؤية أقل"
      expect(find.text('رؤية أقل'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

      // Tap on "رؤية أقل"
      await tester.tap(find.text('رؤية أقل'));
      await tester.pumpAndSettle();

      // Should return to "رؤية المزيد"
      expect(find.text('رؤية المزيد'), findsOneWidget);
    });

    testWidgets('Long text shows "See more" in English and toggles expansion', (tester) async {
      const longEnglishText = '''This is a very long post content that spans multiple lines and paragraphs for testing purposes.
Line 2 with additional post details.
Line 3 to verify proper truncation and expand functionality.
Line 4 with even more information.
Line 5 to ensure exceeding the collapsed max lines limit.
Line 6 to make sure full content is displayed upon expansion.
Line 7 final test line for verification.''';

      await tester.pumpWidget(
        createTestWidget(
          child: const FormattedContentWidget(
            content: longEnglishText,
            isExpandable: true,
            collapsedMaxLines: 4,
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the "See more" button
      expect(find.text('See more'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap on "See more"
      await tester.tap(find.text('See more'));
      await tester.pumpAndSettle();

      // Should now show "See less"
      expect(find.text('See less'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    });
  });
}
