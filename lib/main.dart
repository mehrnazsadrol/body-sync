import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/app_store.dart';
import 'data/notification_service.dart';
import 'firebase_options.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/settings/recovery_screen.dart';
import 'screens/shell.dart';
import 'theme/bs_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final store = AppStore();
  final notifications = NotificationService();
  notifications.init();

  store.load().then((_) {
    notifications.sync(store);
    FirebaseAuth.instance
        .authStateChanges()
        .listen((user) => store.setUser(user?.uid));
  });

  var lastSettings = store.settings;
  store.addListener(() {
    if (!identical(store.settings, lastSettings)) {
      lastSettings = store.settings;
      notifications.sync(store);
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>.value(value: store),
        Provider<NotificationService>.value(value: notifications),
      ],
      child: const BodySyncApp(),
    ),
  );
}

class BodySyncApp extends StatelessWidget {
  const BodySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final themeMode = switch (store.settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: 'BodySync',
      debugShowCheckedModeBanner: false,
      theme: BSTheme.light(),
      darkTheme: BSTheme.dark(),
      themeMode: themeMode,
      home: !store.loaded || !store.authKnown
          ? const _Splash()
          : store.uid == null
              ? const SignInScreen()
              : store.syncingInitial
                  ? const _Splash()
                  : store.recoveryNeeded
                      ? const RecoveryScreen()
                      : store.onboarded
                          ? const HomeShell()
                          : const OnboardingFlow(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
