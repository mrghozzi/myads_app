import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: MyAdsApp(),
    ),
  );
}

class MyAdsApp extends ConsumerStatefulWidget {
  const MyAdsApp({super.key});

  @override
  ConsumerState<MyAdsApp> createState() => _MyAdsAppState();
}

class _MyAdsAppState extends ConsumerState<MyAdsApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to media sharing when app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _handleSharedMedia(value);
    }, onError: (err) {
      if (kDebugMode) debugPrint("getIntentDataStream error: $err");
    });

    // Get initial media if app was opened via sharing
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void _handleSharedMedia(List<SharedMediaFile> value) {
    List<String> paths = [];
    String? textData;
    
    for (var file in value) {
      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
        textData = textData == null ? file.path : '$textData\n${file.path}';
      } else {
        paths.add(file.path);
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Map<String, dynamic> extra = {};
      if (paths.isNotEmpty) extra['filePaths'] = paths;
      if (textData != null) extra['text'] = textData;
      
      if (extra.isNotEmpty) {
        appRouter.push('/compose', extra: extra);
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'MYADS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Dynamic Light & Dark Mode
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
    );
  }
}
