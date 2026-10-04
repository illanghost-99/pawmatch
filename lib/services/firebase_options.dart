import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    throw UnsupportedError('Firebase är bara kopplat för iPhone.');
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBiiK5CkdiQmuDf2aOVjdqAO0rCdsyhx6s',
    appId: '1:597702536143:ios:b1c9c000b3de2d3a3c40ba',
    messagingSenderId: '597702536143',
    projectId: 'pawmatch-404e5',
    storageBucket: 'pawmatch-404e5.firebasestorage.app',
    iosBundleId: 'app.pawmatch',
  );
}
