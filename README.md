# **🌍✨ WHere? — AI-Powered Cultural Location Guide**
**WHere?** is an intelligent mobile companion designed to transform GPS coordinates into rich cultural narratives. By merging real-time location data with Generative AI, it provides users with deep insights into the history, naming logic, and socio-cultural fabric of their surroundings.

## **🚀 Key Features**
* **AI Cultural Insights:** Uses Gemini 1.5 Flash to generate context-specific descriptions of your exact location, avoiding generic responses.
* **Intelligent Data Fusion:** Aggregates data from Wikipedia, OpenStreetMap (Overpass API), and Nominatim for high factual accuracy.
* **Interactive Exploration:** Tap anywhere on the integrated OpenStreetMap to unlock the cultural identity of that point instantly.
* **Personal Cultural Archive:** Securely save your favorite location narratives to your profile using Firebase Firestore.
* **Urban AI Chatbot:** A dedicated assistant focused on city culture and local history to answer your specific queries.
* **Smart Location Notifications:** Proactive system that detects when location services are active and asks if you'd like to receive cultural insights about your current coordinates.
* **Cloud Profile Management:** Dynamic user profiles with avatar hosting powered by Cloudinary.

## **🛠️ Technology Stack**

| Category                | Technology                                      |
|-------------------------|-------------------------------------------------|
| Framework               | Flutter (Dart)                                  |
| Artificial Intelligence | Google Gemini 1.5 Flash                         |
| Backend & Auth          | Firebase (Auth, Firestore)                      |
| Mapping & GIS           | Flutter Map & OpenStreetMap                     |
| Data Sources            | Overpass API, Wikipedia REST API, Nominatim     |
| Media Hosting           | Cloudinary                                      |
| Local Services          | Geolocator, Flutter Local Notifications         |

## **📂 Project Structure**
```text
where/
├── .dart_tool/          # Dart tool configurations
├── .idea/               # VS Code / Android Studio settings
├── android/             # Android platform-specific files
├── assets/              # Application resources
│   └── logo.png         # App logo
├── build/               # Build output directory
├── ios/                 # iOS platform-specific files
├── lib/                 # Main source code directory
│   ├── screens/         # UI pages of the application
│   │   ├── chatbot.dart     # AI chatbot screen
│   │   ├── favorites.dart   # Favorites list screen
│   │   ├── login.dart       # Login screen
│   │   ├── map.dart         # Map and discovery screen
│   │   ├── profile.dart     # Profile and settings screen
│   │   ├── register.dart    # Registration screen
│   │   └── splash.dart      # Splash (launch) screen
│   ├── services/        # Business logic and external services
│   │   ├── ai_service.dart          # Gemini AI integration logic
│   │   ├── favorites_service.dart   # Firestore database operations
│   │   ├── firebase_options.dart    # Firebase configuration template
│   │   └── notification_service.dart # Local notification management
│   └── main.dart        # Entry point of the application
├── linux/               # Linux platform-specific files
├── macos/               # MacOS platform-specific files
├── test/                # Unit and widget tests
├── web/                 # Web platform-specific files
├── windows/             # Windows platform-specific files
├── .gitignore           # List of files to be ignored by Git
├── analysis_options.yaml# Dart analysis and linting rules
├── firebase.json        # Firebase CLI configuration
├── pubspec.yaml         # Package dependencies and asset definitions
└── README.md            # Project documentation
```

## **⚙️ Installation & Integration Guide**
Follow these steps to set up the development environment and run WHeRe? on your local machine.

### **1. Prerequisites**
* **Flutter SDK (Latest Stable Version):** Latest stable version installed.
* **Dart SDK:** Included with Flutter.
* **Firebase Project:** A project created on the Firebase Console.
* **Gemini API Key:** Obtained from Google AI Studio.
* **Cloudinary Account:** For managing user profile avatars.

### **2. Clone the Repository**
```bash
git clone https://github.com/KbrPrmk/WHere-flutter-app.git
cd WHere-flutter-app
```

### **3. Dependency Installation**
The project relies on a comprehensive set of packages to handle AI, mapping, and cloud services. Install them using the command below:
```bash
flutter pub get
```
**Key Dependencies:**
* **AI & Networking:** `http` (For Gemini API and Reverse Geocoding).
* **Mapping:** `flutter_map` (OpenStreetMap integration) and latlong2.
* **Firebase Suite:** `firebase_core`, `firebase_auth`, `cloud_firestore`, and `firebase_storage`.
* **Location Services:** `geolocator` (Real-time GPS tracking).
* **User Media:** `image_picker` (For profile photo selection).
* **Local Management:** `shared_preferences` (Local data caching) and `permission_handler` (System permission management).
* **Notifications:** `flutter_local_notifications`.

### **4. Configuration**
Follow these detailed steps to integrate the required services and permissions for **WHere?**.

#### **A. Firebase Integration**
The `lib/services/firebase_options.dart` file is excluded from this repository for security. You must generate your own configuration:
1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Run the configuration command: `flutterfire configure`
3. Setup Services: Ensure Authentication, Cloud Firestore, and Firebase Storage are enabled in your Firebase Console.

#### **B. Gemini AI Setup**
To enable the cultural storytelling features:
1. Obtain an API key from Google AI Studio.
2. Open `lib/services/ai_service.dart`.
3. Replace the placeholder with your key:
```bash
// Bu kısıma kullanacağınız API key'i yapıştırın.
// Paste the API key you will use here.
  final String apiKey =
      "YOUR_GEMINI_API_KEY";
```

#### **C. Android Manifest Settings**
To support GPS tracking, notifications, and image uploads, ensure `android/app/src/main/AndroidManifest.xml` includes these configurations:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/xml">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.CAMERA" />

    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application ...>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

#### **D. iOS Configuration (Info.plist)**
If deploying to iOS, add the following keys to `ios/Runner/Info.plist` to handle permissions:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>WHere? needs access to your location to provide cultural insights about your surroundings.</string>
<key>NSCameraUsageDescription</key>
<string>WHere? requires camera access to let you capture and upload a profile picture.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>WHere? requires photo library access to let you choose a profile picture.</string>
```

#### **E. Assets & Branding**
Confirm that your application branding is correctly mapped in `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/
    - assets/logo.png
```

### **5. Running the Application**
Connect a physical device or start an emulator, then run:
```bash
flutter run
```
