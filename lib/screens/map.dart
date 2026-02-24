import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../services/ai_service.dart';
import '../services/favorites_service.dart';
import '../screens/profile.dart';
import 'chatbot.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class map extends StatefulWidget {
  const map({super.key});

  @override
  State<map> createState() => _mapState();
}

class _mapState extends State<map> {
  LatLng? currentLocation;
  LatLng? selectedLocation;
  bool isLoading = true;

  final ai = AIService();
  bool isAiLoading = false;

  final fav = FavoritesService();

  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => isLoading = false);
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();

    final here = LatLng(position.latitude, position.longitude);

    if (!mounted) return;
    setState(() {
      currentLocation = here;
      selectedLocation = here;
      isLoading = false;
    });

    await _askAI(here.latitude, here.longitude);
  }

  Future<void> _refreshAll() async {
    _hideSnackBar();
    _closeDialogIfOpen();

    if (!mounted) return;
    setState(() {
      isLoading = true;
      currentLocation = null;
      selectedLocation = null;
      isAiLoading = false;
    });

    await _getUserLocation();
  }

  void _showLoadingSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Yapay zekaya ulaşılıyor..."),
        duration: Duration(minutes: 1),
      ),
    );
  }

  void _hideSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }


  void _closeDialogIfOpen() {
    if (_isDialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogOpen = false;
    }
  }

  Future<void> _askAI(double lat, double lon) async {
    if (isAiLoading) return;

    _closeDialogIfOpen();

    if (!mounted) return;
    setState(() => isAiLoading = true);
    _showLoadingSnackBar();

    try {
      final response = await ai.getCulturalInfo(lat, lon);
      final placeName = await ai.getPlaceLabel(lat, lon);

      if (!mounted) return;
      _hideSnackBar();

      _showAIPopup(
        placeName: placeName,
        aiText: response,
        onFavorite: () async {
          await fav.addFavorite(
            placeName: placeName,
            aiText: response,
            lat: lat,
            lon: lon,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Favorilere eklendi ")),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _hideSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yapay zekaya ulaşılamadı.")),
      );
    } finally {
      if (mounted) setState(() => isAiLoading = false);
    }
  }

  void _showAIPopup({
    required String placeName,
    required String aiText,
    required VoidCallback onFavorite,
  }) {
    if (!mounted) return;

    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            height: 600,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color.fromRGBO(233, 227, 250, 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(216, 199, 250, 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.place,
                        color: Color.fromRGBO(64, 18, 104, 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Bulunduğun Yer",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: "Favorilere ekle",
                      onPressed: onFavorite,
                      icon: const Icon(Icons.star_border),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color.fromRGBO(45, 14, 71, 1),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 15),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 415),
                  child: SingleChildScrollView(
                    child: Text(
                      aiText,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.75,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(216, 199, 250, 1),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const chatbot()),
          );
        },
        child: Icon(Icons.insert_emoticon_sharp),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(216, 199, 250, 1),
        centerTitle: true,
        title: Image.asset("assets/logo.png", height: 90),
        actions: [
          IconButton(
            tooltip: "Yenile",
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const profile()),
              );
            },
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseAuth.instance.currentUser == null
                  ? null
                  : FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final photoUrl = data?['photoUrl'];

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                    (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),

        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentLocation == null) {
      return const Center(child: Text("Konum alınamadı."));
    }

    final pinPoint = selectedLocation ?? currentLocation!;

    return FlutterMap(
      options: MapOptions(
        initialCenter: currentLocation!,
        initialZoom: 15,
        onTap: (tapPosition, point) async {
          setState(() => selectedLocation = point);
          await _askAI(point.latitude, point.longitude);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.where',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: pinPoint,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () async {
                  await _askAI(pinPoint.latitude, pinPoint.longitude);
                },
                child: const Icon(
                  Icons.location_pin,
                  color: Color.fromRGBO(64, 18, 104, 1),
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
