import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAVBD7hSc08Vjze3QXzA48DIcxMTbCFeDQ",
            authDomain: "felipe6-8e113e.firebaseapp.com",
            projectId: "felipe6-8e113e",
            storageBucket: "felipe6-8e113e.firebasestorage.app",
            messagingSenderId: "1077367182332",
            appId: "1:1077367182332:web:944e8ebd545f213a1e5879"));
  } else {
    await Firebase.initializeApp();
  }
}
