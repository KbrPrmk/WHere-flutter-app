import 'package:flutter/material.dart';
import 'package:where/screens/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:where/services/notification_service.dart';
import 'services/firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await notification_service.init();
  await notification_service.notifyIfLocationReallyEnabled();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: splash(),
    );
  }
}