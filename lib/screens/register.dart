import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class register extends StatefulWidget {
  const register({super.key});

  @override
  State<register> createState() => _registerState();
}

class _registerState extends State<register> {
  final _emailCtrl = TextEditingController();
  final _userNameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String _error = "";

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();
    final userName = _userNameCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;

    setState(() {
      _error = "";
      _loading = true;
    });

    // Basit doğrulamalar
    if (email.isEmpty || userName.isEmpty || pass.isEmpty || pass2.isEmpty) {
      setState(() {
        _loading = false;
        _error = "E-posta, Kullanıcı Adı ve şifre alanları boş olamaz.";
      });
      return;
    }

    if (pass.length < 6) {
      setState(() {
        _loading = false;
        _error = "Şifre en az 6 karakter olmalı.";
      });
      return;
    }

    if (pass != pass2) {
      setState(() {
        _loading = false;
        _error = "Şifreler uyuşmuyor.";
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      await cred.user?.updateDisplayName(userName);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı. Şimdi giriş yapabilirsin.")),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _error = "Bu e-posta zaten kayıtlı.";
            break;
          case 'invalid-email':
            _error = "Geçersiz e-posta adresi.";
            break;
          case 'weak-password':
            _error = "Şifre çok zayıf. En az 6 karakter yap.";
            break;
          default:
            _error = "Kayıt başarısız: ${e.message ?? e.code}";
        }
      });
    } catch (e) {
      setState(() => _error = "Beklenmeyen hata: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userNameCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(216, 199, 250, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset("assets/logo.png", width: 220),
              const SizedBox(height: 20),

              // Kullanıcı Adı
              TextField(
                controller: _userNameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: "Kullanıcı Adı",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: "E-posta",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Şifre
              TextField(
                controller: _passCtrl,
                obscureText: _obscure1,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: "Şifre (min 6 karakter)",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                    icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Şifre tekrar
              TextField(
                controller: _pass2Ctrl,
                obscureText: _obscure2,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _register(),
                decoration: InputDecoration(
                  hintText: "Şifre tekrar",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                    icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(64, 18, 104, 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text(
                    "Kayıt Ol",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text("Zaten hesabın var mı? Giriş Yap"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
