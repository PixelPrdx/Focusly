# Firebase Setup Guide - Focusly

Bu rehber, Focusly uygulamasını Firebase Firestore ile entegre etmek için adımları anlatır.

## 1. Firebase Projesi Oluştur

1. [Firebase Console](https://console.firebase.google.com) adresine git
2. **Yeni Proje Oluştur** butonuna tıkla
3. Proje adını gir (örn: "focusly")
4. Proje ayarlarını tamamla

## 2. Firestore Veritabanı Oluştur

1. Firebase Console'da proje seç
2. Sol menüden **Firestore Database** seç
3. **Veritabanı Oluştur** butonuna tıkla
4. Test Mode seçimini yapıp başlat (veya güvenlik kurallarını ayarla)

## 3. Firebase Config'i Güncelle

### iOS için:
1. Firebase Console'da **Proje Ayarları** > **iOS uygulaması ekle**
2. iOS Bundle ID: `com.example.focusly`
3. GoogleService-Info.plist dosyasını indir
4. Xcode'da iOS Runner projesine ekle

### Android için:
1. Firebase Console'da **Proje Ayarları** > **Android uygulaması ekle**
2. Android Package Name: `com.example.focusly` (veya pubspec.yaml'daki değer)
3. google-services.json dosyasını indir
4. `android/app/` klasörüne kopyala

### Web için:
1. Firebase Console'da **Proje Ayarları** > **Web uygulaması ekle**
2. Config bilgilerini kopyala
3. `lib/firebase_options.dart` dosyasını güncelle

## 4. firebase_options.dart Dosyasını Güncelle

`lib/firebase_options.dart` dosyasında yer alan placeholder değerleri gerçek Firebase bilgilerinizle değiştirin:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',  // Firebase Console'dan al
  appId: '1:YOUR_NUMERIC_ID:android:YOUR_HASH',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',  // Proje adı
  databaseURL: 'https://your-project-id.firebaseio.com',
  storageBucket: 'your-project-id.appspot.com',
);
```

## 5. Firestore Güvenlik Kurallarını Ayarla

Geliştirme aşamasında test mode kullanın, veya bu kuralları ayarlayın:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{document=**} {
      allow read, write: if true; // Geliştirme için
    }
  }
}
```

Üretim ortamı için daha güvenli kurallar:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

## 6. Paket Yükle

```bash
flutter pub get
```

## 7. Uygulamayı Çalıştır

```bash
flutter run
```

## Firestore Koleksyon Yapısı

`tasks` koleksiyonunda her belge aşağıdaki yapıda olmalıdır:

```json
{
  "userId": "user_1",
  "text": "Görev açıklaması",
  "completed": false,
  "createdAt": "2026-01-02T10:30:00Z"
}
```

## Sorun Giderme

### "FirebaseCore" plugin not found hatası
```bash
flutter clean
flutter pub get
flutter pub cache repair
```

### Firestore bağlantı hatası
- Firebase Console'da doğru proje seçildiğini kontrol et
- İnternet bağlantısını kontrol et
- Güvenlik kurallarını kontrol et

### google-services.json eksik
Android için `android/app/` klasörüne google-services.json dosyasını kopyala

