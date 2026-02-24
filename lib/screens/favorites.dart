import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class favorites extends StatelessWidget {
  favorites({super.key});

  final fav = FavoritesService();

  void _showFavoriteDetail(BuildContext context, String title, String text) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(18),
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Tam metin (scroll)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.65,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Created by AI",
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(216, 199, 250, 1),
      appBar: AppBar(
        title: const Text("Favoriler"),
        backgroundColor: const Color.fromRGBO(216, 199, 250, 1),
      ),
      body: StreamBuilder(
        stream: fav.favoritesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Henüz favori yok"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final placeName = (data['placeName'] ?? '').toString();
              final aiText = (data['aiText'] ?? '').toString();

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  highlightColor: const Color.fromRGBO(216, 199, 250, 1),
                  focusColor: const Color.fromRGBO(216, 199, 250, 1),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showFavoriteDetail(context, placeName, aiText),
                  child: ListTile(
                    title: Text(
                      placeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      aiText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => fav.removeFavorite(d.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
