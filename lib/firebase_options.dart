// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC0XP7J0tG-5GKHwWTW8hffwgw_xAwWUIg',
    appId: '1:813154581368:android:f8e11e60c0f1882662e68d',
    messagingSenderId: '813154581368',
    projectId: 'body-sync-51bb7',
    storageBucket: 'body-sync-51bb7.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDMWUJia_u9NzKv2d_ZqCcTitAkebVr09g',
    appId: '1:813154581368:ios:c12284648eb5e70162e68d',
    messagingSenderId: '813154581368',
    projectId: 'body-sync-51bb7',
    storageBucket: 'body-sync-51bb7.firebasestorage.app',
    iosBundleId: 'com.mehrnaz.bodysync',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDMWUJia_u9NzKv2d_ZqCcTitAkebVr09g',
    appId: '1:813154581368:ios:c12284648eb5e70162e68d',
    messagingSenderId: '813154581368',
    projectId: 'body-sync-51bb7',
    storageBucket: 'body-sync-51bb7.firebasestorage.app',
    iosBundleId: 'com.mehrnaz.bodysync',
  );
}
