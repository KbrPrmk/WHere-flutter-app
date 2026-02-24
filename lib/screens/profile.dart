import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:where/screens/map.dart';
import 'package:where/screens/favorites.dart';
import 'package:where/screens/login.dart';


class profile extends StatefulWidget {
  const profile({super.key});

  @override
  State<profile> createState() => _profileState();
}

class _profileState extends State<profile> {
  static const _bg = Color.fromRGBO(216, 199, 250, 1);
  static const _primary = Color.fromRGBO(64, 18, 104, 1);

  String bildirim_yazisi = "🔔 Bildirim";
  static const String _cloudName = "dng3fuvmz";
  static const String _uploadPreset = "where_profile";

  bool _notificationsEnabled = true;
  bool _busy = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final v = (doc.data()?['notificationsEnabled'] as bool?) ?? false;

      if (!doc.exists || doc.data()?['notificationsEnabled'] == null) {
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

        await ref.set({'notificationsEnabled': false}, SetOptions(merge: true));

      }


      if (!mounted) return;
      setState(() {
        _notificationsEnabled = v;
        bildirim_yazisi = v ? "🔔 Bildirim" : "🔕 Bildirim";
      });
    } catch (_) {}
  }


  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const login()),
          (route) => false,
    );
  }

  Future<String> _uploadToCloudinary(File file) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final res = await req.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode != 200) {
      throw Exception("Cloudinary upload failed: $body");
    }

    final json = jsonDecode(body);
    return json['secure_url'];
  }

  Future<void> _pickAndSaveAvatar() async {
    if (_busy) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() => _busy = true);

    try {
      final file = File(picked.path);

      final url = await _uploadToCloudinary(file);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'photoUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.updatePhotoURL(url);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil fotoğrafı kaydedildi.")),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firebase hatası: ${e.message ?? e.code}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Foto kaydedilemedi: $e")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hesabı sil?"),
        content: const Text(
          "Bu işlem geri alınamaz.\nHesabın ve verilerin silinecek. Emin misin?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      await user.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hesap ve veriler silindi.")),
      );

      await _signOut();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Silmek için yeniden giriş yapman gerekiyor. Tekrar giriş yapıp tekrar dene."),
          ),
        );
        await _signOut();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hesap silinemedi: ${e.message ?? e.code}")),
        );
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firestore hatası: ${e.message ?? e.code}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme başarısız: $e")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: uid == null
                          ? null
                          : FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .snapshots(),
                      builder: (context, snap) {
                        final data = snap.data?.data();
                        final photoUrl = data?['photoUrl'] as String?;

                        return GestureDetector(
                          onTap: _busy ? null : _pickAndSaveAvatar,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 250,
                                    height: 250,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade400,
                                      image: (photoUrl != null &&
                                          photoUrl.isNotEmpty)
                                          ? DecorationImage(
                                        image: NetworkImage(photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                    ),
                                    child:
                                    (photoUrl == null || photoUrl.isEmpty)
                                        ? const Icon(Icons.person,
                                        size: 90, color: Colors.white)
                                        : null,
                                  ),
                                ),
                              ),

                              Positioned(
                                bottom: 18,
                                right: 18,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _primary,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        color: Colors.black.withOpacity(0.15),
                                      ),
                                    ],
                                  ),
                                  child: _busy
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    Text(
                      user?.displayName ?? "Kullanıcı",
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(64, 18, 104, 1),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    _MenuRow(
                      title: "🗺️ Harita",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const map()),
                        );
                      },
                    ),

                    _MenuRow(
                      title: "⭐️ Favoriler",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => favorites()),
                        );
                      },
                    ),


                    _SwitchRow(
                      title: bildirim_yazisi,
                      value: _notificationsEnabled,
                      onChanged: (v) async {
                        setState(() => _notificationsEnabled = v);

                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set(
                            {
                              'notificationsEnabled': v,
                            },
                            SetOptions(merge: true),
                          );
                        }

                        bildirim_yazisi = v ? "🔔 Bildirim" : "🔕 Bildirim";
                      },
                      activeColor: _primary,
                    ),


                    const SizedBox(height: 18),

                    // Çıkış
                    TextButton(
                      onPressed: _busy ? null : _signOut,
                      child: const Text(
                        "Çıkış Yap",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color.fromRGBO(64, 18, 104, 1),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // Hesabı Sil
                    TextButton(
                      onPressed: _busy ? null : _deleteAccount,
                      child: const Text(
                        "Hesabı Sil",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final Widget? trailing;

  const _MenuRow({
    required this.title,
    required this.onTap,
    this.danger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: danger ? Colors.redAccent : Colors.black,
                  ),
                ),
                const Spacer(),
                trailing ?? const Icon(Icons.chevron_right, size: 36),
              ],
            ),

          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}