import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {

  // Bu kısıma kullanacağınız API key'i yapıştırın.
  // Paste the API key you will use here.
  final String apiKey =
      "YOUR_GEMINI_API_KEY";

  String? _lastKey;
  String? _lastResult;

  DateTime? _lastCallTime;

  bool _canCallAI() {
    if (_lastCallTime == null) return true;
    return DateTime.now().difference(_lastCallTime!).inSeconds > 20;
  }

  Future<String> getPlaceLabel(double lat, double lon) async {
    final parts = await _reverseGeocodeParts(lat, lon);
    return _pickBestPlaceLabel(parts);
  }

  Future<String> getCulturalInfo(double lat, double lon) async {
    final cacheKey = "${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}";
    if (_lastKey == cacheKey && _lastResult != null) return _lastResult!;

    if (!_canCallAI()) {
      return "Biraz yavaş 🙂 Yapay zekâ çok sık çağrıldı. Lütfen 20 sn sonra tekrar dene.";
    }
    _lastCallTime = DateTime.now();

    final parts = await _reverseGeocodeParts(lat, lon);
    final placeLabel = _pickBestPlaceLabel(parts);

    final wikiText = await _getBestWikipediaText(parts);

    final pois = await _fetchNearbyPois(lat, lon, radiusMeters: 1200);

    final adminNames = await _fetchAdminBoundaries(
      lat,
      lon,
      radiusMeters: 1600,
    );


    final prompt = _buildUnifiedPrompt(
      placeLabel: placeLabel,
      lat: lat,
      lon: lon,
      wikiText: wikiText,
      pois: pois,
      adminNames: adminNames,
    );

    final result = await _callGemini(prompt);

    _lastKey = cacheKey;
    _lastResult = result;
    return result;
  }


  Future<String> _callGemini(String prompt) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        return "Şu an çok istek attık 😅 1 dakika bekleyip tekrar dener misin?";
      }
      return "Yapay zeka şu anda cevap veremedi. (HTTP ${response.statusCode})";
    }


    try {
      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      if (text is String && text.trim().isNotEmpty) return text.trim();
      return "Bu konum için yanıt üretilemedi.";
    } catch (_) {
      return "Yapay zeka cevabı işlerken hata oluştu.";
    }
  }

  String _buildUnifiedPrompt({
    required String placeLabel,
    required double lat,
    required double lon,
    required String? wikiText,
    required List<Map<String, dynamic>> pois,
    required List<String> adminNames,
  }) {
    final wikiBlock = (wikiText != null && wikiText.trim().isNotEmpty)
        ? "Kaynak metin (Wikipedia özeti):\n$wikiText"
        : "Wikipedia özeti bulunamadı. Kesin yıl/tarih verme, temkinli anlat.";

    final poiLines = pois.isNotEmpty
        ? pois
              .take(12)
              .map((p) {
                final name = p["name"] ?? "İsimsiz";
                final type = p["type"] ?? "poi";
                final dist = p["distance_m"];
                return "- $name ($type) ~${dist}m";
              })
              .join("\n")
        : "(Yakında kayda değer yer listesi bulunamadı.)";

    final adminBlock = adminNames.isNotEmpty
        ? adminNames.take(10).map((e) => "- $e").join("\n")
        : "(İdari sınır (boundary) verisi bulunamadı.)";

    return """
Aşağıdaki konum için Türkçe, bilgi açısından DERİN ve KONUMA ÖZGÜ bir metin üret.
Bu bir bilgi alma uygulamasıdır; yüzeysel, her yere uyacak anlatımdan kaçın.

KONUM VERİLERİ:
Konum etiketi: $placeLabel
Koordinat: ($lat, $lon)

Wikipedia (varsa):
$wikiBlock

Yakındaki yerler (OpenStreetMap POI):
$poiLines

İdari sınır ipuçları (boundary=administrative, Overpass):
$adminBlock


KATI KURALLAR (ÇOK ÖNEMLİ):
- UYDURMA YOK: Wikipedia/POI/İdari sınır'da olmayan kesin yıl, tarih, olay, kişi, kuruluş, yer adı uydurma.
- GENEL CÜMLE YOK: “Burası sakin bir yerleşim alanıdır” gibi her mahalleye uyacak cümleleri tek başına kullanma.
  Her cümle, bu konumu ayırt eden bir ipucuna dayanmalı (konum etiketi, koordinat bağlamı, wiki, POI, admin sınır ipuçları).
- TEK NOKTA YASAK: Konumu tek bir yapı (sadece cami / sadece okul / sadece üniversite / sadece park) üzerinden anlatamazsın.
  Metin; en az 2 farklı mekân türüne dayanmak zorundadır:
  (1) kamusal/kültürel/sosyal alan örneği VE (2) gündelik yaşam/yerleşim/ulaşım/ticaret bağlamı.
- POI’LERİ MUTLAKA DEĞERLENDİR:
  Eğer POI listesi tek tipe yığılmışsa (ör. çoğu ibadet yeri) bunu açıkça belirt:
  "Harita verisi şu an daha çok X türü noktaları gösteriyor" gibi dürüstçe yaz ve anlatımı çeşitlendirmek için
  admin sınır + isimlendirme mantığı + çevresel bağlamı kullan.
- İDARİ SINIRLAR:
  Eğer idari sınır ipuçlarında birden fazla merkez/ilçe benzeri isim görünüyorsa
  bunu "kesişim/çoklu idari etki olabilir" diye TEMKİNLİ ifade et. Kesin hüküm verme.

ÇIKTI BİÇİMİ:
- Madde işareti KULLANMA.
- Düz metin yaz.
- 3 bölüm olacak: (1) Genel Özet paragrafı, (2) Yakındaki Yerler paragrafı, (3) Kısa öneri satırı.
- Yakındaki yerler bölümünde en fazla 5 yer adı geçsin. Yer adlarını aynen POI listesinden kullan.

GÖREVLER:

1) GENEL ÖZET (6–9 cümle):
- Bu konumun yerel bağlamını anlat: çevredeki kullanım (yerleşim/ticaret/eğitim/ulaşım/sosyal) hangi yönde yoğunlaşıyor?
- “İlçe/mahalle/sokak isimleri nasıl verilir?” konusunu GENEL isimlendirme mantığıyla açıkla:
  ilçe isimleri (idari-tarihsel-coğrafi), mahalle isimleri (eski yerleşim/doğal unsurlar/toplumsal izler),
  sokak/cadde isimleri (yön/meslek/kişiler/yerel özellikler).
  Ancak bunu bu konum etiketiyle ilişkilendir:
  - İdari sınır ipuçları birden fazlaysa, yerel yönetim sınırlarının yakın olabileceğini temkinli anlat.
- Market/okul/durak gibi adların neden çoğunlukla işlevsel ve kolay bulunabilirlik odaklı verildiğini açıkla.
- Wikipedia metni yoksa “kaynaklarda spesifik tarihsel kayıt sınırlı” gibi dürüst bir cümle ekle;
  ama metni boş bırakma, çevreyi anlamaya yarayan açıklayıcı bağlam üret.

2) YAKINDAKİ YERLER (POI varsa):
- POI listesinden en fazla 5 yer seç.
- Seçilen yerler AYNI TÜR olmamalı (ör. sadece ibadet yapısı seçme).
  En az 2 farklı türden örnek olmalı (örn. park + eğitim / ulaşım + kültürel / sağlık + meydan vb.).
- Her seçtiğin yer için 1 cümle yaz:
  “Bu yer, bu çevreyi tanımak açısından neden bilgilendiricidir?” sorusuna cevap ver.
- Eğer listede güçlü kamusal/kültürel yer yoksa, bunu belirt ve seçimini
  “gündelik yaşamı anlamaya yardım eden noktalar” üzerinden yap (ör. ulaşım, eğitim, park, yoğun kullanılan alanlar).

3) SON SATIR:
Metnin son satırı mutlaka şu formatta olsun:
“Kısa öneri: …”
- Yaklaşık yürüyüş mesafesi veya süresi ver (örn. 200–400 metre / 3–6 dakika gibi).
- Eğer park/kampüs/meydan gibi açık alan varsa, orada ne yapılabileceğini söyle.
- Yerel tat/deneyim önerisi verirken genelleme yap; özel yemek adı veya işletme uydurma.

Şimdi bu kurallara uyarak çıktıyı üret.
""";
  }

  String _pickBestPlaceLabel(Map<String, String> p) {
    final hood = [p["neighbourhood"], p["quarter"], p["suburb"]]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();

    final county = (p["county"] ?? "").trim();
    final city = (p["city"] ?? "").trim();
    final state = (p["state"] ?? "").trim();
    final country = (p["country"] ?? "").trim();

    if (hood.isNotEmpty && city.isNotEmpty) return "${hood.first}, $city";
    if (county.isNotEmpty && city.isNotEmpty) return "$county, $city";
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    if (country.isNotEmpty) return country;
    return "Bulunduğun konum";
  }

  Future<String?> _getBestWikipediaText(Map<String, String> parts) async {
    final hood = [parts["neighbourhood"], parts["quarter"], parts["suburb"]]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();

    final county = (parts["county"] ?? "").trim();
    final city = (parts["city"] ?? "").trim();
    final country = (parts["country"] ?? "").trim();

    if (hood.isNotEmpty) {
      final h = hood.first;
      final t1 = await _wikiSummaryTr(h);
      if (t1 != null) return t1;

      if (city.isNotEmpty) {
        final t2 = await _wikiSummaryTr("$h $city");
        if (t2 != null) return t2;
      }
    }

    if (county.isNotEmpty) {
      final t3 = await _wikiSummaryTr(county);
      if (t3 != null) return t3;

      if (city.isNotEmpty) {
        final t4 = await _wikiSummaryTr("$county $city");
        if (t4 != null) return t4;
      }
    }

    if (city.isNotEmpty) {
      final t5 = await _wikiSummaryTr(city);
      if (t5 != null) return t5;
    }

    if (country.isNotEmpty) {
      final t6 = await _wikiSummaryTr(country);
      if (t6 != null) return t6;
    }

    return null;
  }

  Future<String?> _wikiSummaryTr(String title) async {
    final encoded = Uri.encodeComponent(title);
    final url = Uri.parse(
      "https://tr.wikipedia.org/api/rest_v1/page/summary/$encoded",
    );

    final res = await http.get(
      url,
      headers: {"User-Agent": "com.example.where"},
    );

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    final extract = data["extract"];
    if (extract is String && extract.trim().isNotEmpty) return extract;

    return null;
  }

  Future<Map<String, String>> _reverseGeocodeParts(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1",
    );

    final res = await http.get(
      url,
      headers: {
        "User-Agent": "com.example.where (contact: seninmail@gmail.com)",
        "Accept-Language": "tr",
      },
    );

    if (res.statusCode != 200) return {};

    final data = jsonDecode(res.body);
    final addr = data["address"] ?? {};

    String pick(dynamic v) => v is String ? v : "";

    return {
      "neighbourhood": pick(addr["neighbourhood"]),
      "suburb": pick(addr["suburb"]),
      "quarter": pick(addr["quarter"]),
      "county": pick(addr["county"]),
      "city": pick(addr["city"] ?? addr["town"]),
      "state": pick(addr["state"]),
      "country": pick(addr["country"]),
    };
  }

  Future<List<String>> _fetchAdminBoundaries(
    double lat,
    double lon, {
    int radiusMeters = 1600,
  }) async {
    final overpassUrl = Uri.parse("https://overpass-api.de/api/interpreter");

    final query =
        """
[out:json][timeout:25];
(
  relation(around:$radiusMeters,$lat,$lon)["boundary"="administrative"]["name"];
);
out tags;
""";

    try {
      final res = await http.post(
        overpassUrl,
        headers: {"Content-Type": "text/plain"},
        body: query,
      );
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final elements = (data["elements"] as List?) ?? [];

      final names = <String>{};
      for (final el in elements) {
        final tags = el["tags"];
        final name = tags?["name:tr"] ?? tags?["name"];
        if (name is String && name.trim().isNotEmpty) {
          names.add(name.trim());
        }
      }

      return names.toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNearbyPois(
    double lat,
    double lon, {
    int radiusMeters = 1200,
  }) async {
    final overpassUrl = Uri.parse("https://overpass-api.de/api/interpreter");

    final query =
        """
[out:json][timeout:25];
(
  // Turistik / kültürel
  node(around:$radiusMeters,$lat,$lon)["tourism"~"attraction|museum|gallery|viewpoint|information"];
  way(around:$radiusMeters,$lat,$lon)["tourism"~"attraction|museum|gallery|viewpoint|information"];
  relation(around:$radiusMeters,$lat,$lon)["tourism"~"attraction|museum|gallery|viewpoint|information"];

  // Tarihi
  node(around:$radiusMeters,$lat,$lon)["historic"];
  way(around:$radiusMeters,$lat,$lon)["historic"];
  relation(around:$radiusMeters,$lat,$lon)["historic"];

  // Park / açık alan
  node(around:$radiusMeters,$lat,$lon)["leisure"~"park|garden"];
  way(around:$radiusMeters,$lat,$lon)["leisure"~"park|garden"];
  relation(around:$radiusMeters,$lat,$lon)["leisure"~"park|garden"];

  // Eğitim / sağlık / kamu / pazar / kültür
  node(around:$radiusMeters,$lat,$lon)["amenity"~"theatre|place_of_worship|school|university|library|hospital|clinic|marketplace|townhall|police"];
  way(around:$radiusMeters,$lat,$lon)["amenity"~"theatre|place_of_worship|school|university|library|hospital|clinic|marketplace|townhall|police"];
  relation(around:$radiusMeters,$lat,$lon)["amenity"~"theatre|place_of_worship|school|university|library|hospital|clinic|marketplace|townhall|police"];

  // Ulaşım
  node(around:$radiusMeters,$lat,$lon)["highway"="bus_stop"];
  node(around:$radiusMeters,$lat,$lon)["railway"~"station|tram_stop|subway_entrance"];

  // Alışveriş
  node(around:$radiusMeters,$lat,$lon)["shop"~"supermarket|mall"];
  way(around:$radiusMeters,$lat,$lon)["shop"~"supermarket|mall"];
);
out center tags;
""";

    try {
      final res = await http.post(
        overpassUrl,
        headers: {"Content-Type": "text/plain"},
        body: query,
      );
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final elements = (data["elements"] as List?) ?? [];

      double approxDistanceMeters(double aLat, double aLon) {
        final dLat = (aLat - lat).abs();
        final dLon = (aLon - lon).abs();
        return ((dLat + dLon) * 111000).roundToDouble();
      }

      final items = <Map<String, dynamic>>[];

      for (final el in elements) {
        final tags = el["tags"];
        if (tags == null) continue;

        final name = tags["name"] ?? tags["name:tr"] ?? tags["name:en"];
        if (name == null || (name is String && name.trim().isEmpty)) continue;

        final elLat = el["lat"] ?? el["center"]?["lat"];
        final elLon = el["lon"] ?? el["center"]?["lon"];
        if (elLat == null || elLon == null) continue;

        String type = "poi";
        if (tags["tourism"] != null)
          type = "tourism=${tags["tourism"]}";
        else if (tags["historic"] != null)
          type = "historic=${tags["historic"]}";
        else if (tags["amenity"] != null)
          type = "amenity=${tags["amenity"]}";
        else if (tags["leisure"] != null)
          type = "leisure=${tags["leisure"]}";
        else if (tags["shop"] != null)
          type = "shop=${tags["shop"]}";
        else if (tags["highway"] != null)
          type = "highway=${tags["highway"]}";
        else if (tags["railway"] != null)
          type = "railway=${tags["railway"]}";

        items.add({
          "name": name,
          "type": type,
          "distance_m": approxDistanceMeters(
            (elLat as num).toDouble(),
            (elLon as num).toDouble(),
          ).toInt(),
        });
      }

      items.sort(
        (a, b) => (a["distance_m"] as int).compareTo(b["distance_m"] as int),
      );
      return items;
    } catch (_) {
      return [];
    }
  }

  // CHATBOT
  Future<String> chat(String userMessage, {String? systemHint}) async {
    final prompt = """
    Sen bir şehir kültürü ve konum asistanısın. Türkçe cevap ver.
    - Uydurma bilgi verme.
    - Eğer kullanıcı özel bir yer adı söylüyorsa (ör. Alaaddin Tepesi), kısa ama dolu cevap ver.
    - Emin olmadığın yerel efsane/iddiaları “yerel anlatılarda…” gibi yumuşak ifadeyle belirt.
    - Cevapların 6-10 cümleyi geçmesin, anlaşılır ve faydalı olsun.
    
    Ek bağlam:
    ${systemHint ?? "(yok)"}
    
    Kullanıcı mesajı:
    $userMessage
    """;
    return _callGemini(prompt);
  }

}
