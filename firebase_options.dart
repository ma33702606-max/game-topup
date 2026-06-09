// =====================================================================
//  ⚠️ تحذير مهم: هذا الملف template فارغ
//  يجب استبداله بالملف المولّد من Firebase Console
//  راجع تعليمات الإعداد في README.md
// =====================================================================
//
// خطوات توليد هذا الملف:
// 1. ثبّت Firebase CLI: npm install -g firebase-tools
// 2. ثبّت FlutterFire CLI: dart pub global activate flutterfire_cli
// 3. سجّل الدخول: firebase login
// 4. شغّل: flutterfire configure
//    سيتم توليد هذا الملف تلقائياً
// =====================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured. Run: flutterfire configure');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not configured.');
    }
  }

  // ⚠️ استبدل هذه القيم بالقيم الحقيقية من Firebase Console
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.gameTopup',
  );
}
