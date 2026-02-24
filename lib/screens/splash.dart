import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:where/screens/login.dart';
import 'package:where/screens/map.dart';

class splash extends StatefulWidget {
  const splash({super.key});

  @override
  State<splash> createState() => _splashState();
}

class _splashState extends State<splash> {
  @override
  void initState() {
    super.initState();
    _loadAndRoute();
  }

  Future<void> _loadAndRoute() async {
    await Future.delayed(const Duration(seconds: 3));

    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const login()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => map()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var ekranBilgisi = MediaQuery.of(context);

    return const Scaffold(
      backgroundColor: Color.fromRGBO(216, 199, 250, 1),
      body: Center(
        child: Image(
          image: AssetImage("assets/logo.png"),
          height: 300,
        ),
      ),
    );
  }
}
