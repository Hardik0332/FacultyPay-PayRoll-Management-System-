import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAQLBW90YxNmQqTLakZJPGgFYRILGaI2qI",
    authDomain: "fixed-project-new.firebaseapp.com",
    projectId: "fixed-project-new",
    storageBucket: "fixed-project-new.appspot.com",
    messagingSenderId: "1078975084440",
    appId: "1:1078975084440:web:983036b2aae2cd4d0c5ded",
  );
}
