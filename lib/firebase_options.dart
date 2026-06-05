// File generated for SoulFlow Health App Firebase integration.
// This file provides Firebase configuration options for all platforms.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDvMZVsSgX1k95AahmVUoFBpHp0LDqTPQE',
    appId: '1:711053109880:web:91de1c79e36911e30ddb8d',
    messagingSenderId: '711053109880',
    projectId: 'soulflow-health-app',
    authDomain: 'soulflow-health-app.firebaseapp.com',
    storageBucket: 'soulflow-health-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMPBEDuxAv1p_ctPvDeHQV4BlBY7dVXNQ',
    appId: '1:711053109880:android:b687a41fe513ff520ddb8d',
    messagingSenderId: '711053109880',
    projectId: 'soulflow-health-app',
    storageBucket: 'soulflow-health-app.firebasestorage.app',
  );
}
