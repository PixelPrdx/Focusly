# Firebase Bilgilerini Bulma Rehberi - Android API Key & Messaging Sender ID

Bu rehber, Firebase Console'dan Android için gerekli **API Key** ve **Messaging Sender ID** bilgilerini nasıl bulacağınızı anlatır.

## 📍 Adım 1: Firebase Console'a Erişim

1. [Firebase Console](https://console.firebase.google.com) adresine git
2. Projene ("focusly-9e177") tıkla

## 📍 Adım 2: google-services.json Dosyasından Bilgi Alma (En Hızlı Yol)

### Eğer google-services.json dosyan varsa:

1. Firebase Console → **Proje Ayarları** (⚙️) → **Uygulamalar** sekmesi
2. **Android** uygulamasını bul
3. **google-services.json indir** butonuna tıkla
4. İndirilen dosyayı aç (herhangi bir metin editörü ile)
5. Aşağıdaki bilgileri bul:

```json
{
  "project_info": {
    "project_id": "focusly-9e177"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcd1234efgh5678"  // ← Bu APP ID
      },
      "api_key": [
        {
          "current_key": "AIzaSyDxxxxxYYYYzzzzzWWWWvvvvuuuu"  // ← Bu API Key
        }
      ]
    }
  ]
}
```

### Bulduğun bilgileri:
- **FIREBASE_ANDROID_API_KEY** = `"current_key"` değeri
- **FIREBASE_ANDROID_APP_ID** = `"mobilesdk_app_id"` değeri
- **FIREBASE_ANDROID_MESSAGING_SENDER_ID** = `"project_number"` değeri (project_info içinde)

---

## 🔧 Adım 3: Firebase Console'dan Manuel Bulma

### API Key Bulma:

1. Firebase Console → **Proje Ayarları** (⚙️)
2. **API'ler ve Hizmetler** tab'ı
3. **API Anahtarı** sekmesi
4. "Android apps" API key'ini bul veya oluştur
5. Kopyala

### Messaging Sender ID Bulma:

1. Firebase Console → **Proje Ayarları** (⚙️)
2. **Genel** tab'ında **Proje Numarası**'nı bul
3. Bu numarayı **FIREBASE_ANDROID_MESSAGING_SENDER_ID** olarak kullan

---

## 🔐 Adım 4: Bilgileri .env Dosyasına Ekle

1. Proje klasöründe `.env` dosyası oluştur (`.env.example` dan kopyala)
2. Aşağıdaki şekilde doldurun:

```env
FIREBASE_PROJECT_ID=focusly-9e177

# Android
FIREBASE_ANDROID_API_KEY=AIzaSyDxxxxxYYYYzzzzzWWWWvvvvuuuu
FIREBASE_ANDROID_APP_ID=1:123456789:android:abcd1234efgh5678
FIREBASE_ANDROID_MESSAGING_SENDER_ID=123456789
FIREBASE_ANDROID_DATABASE_URL=https://focusly-9e177.firebaseio.com
FIREBASE_ANDROID_STORAGE_BUCKET=focusly-9e177.appspot.com
```

3. Dosyayı kaydet

---

## 📋 Bilgilerin Konumları Özeti

| Bilgi | Nereden Bulacak | Dosya/Yer |
|-------|-----------------|-----------|
| **API Key** | google-services.json | `client[0].api_key[0].current_key` |
| **App ID** | google-services.json | `client[0].client_info.mobilesdk_app_id` |
| **Messaging Sender ID** | google-services.json | `project_info.project_number` |
| **Project ID** | Firebase Console | Proje Ayarları → Genel |
| **Database URL** | Firebase Console | Firestore → Bağlantı Adı |

---

## ✅ Kontrol Listesi

- [ ] google-services.json dosyasını indirdim
- [ ] .env dosyasını oluşturdum
- [ ] FIREBASE_ANDROID_API_KEY'i doldurdum
- [ ] FIREBASE_ANDROID_APP_ID'yi doldurdum
- [ ] FIREBASE_ANDROID_MESSAGING_SENDER_ID'yi doldurdum
- [ ] .env dosyasını .gitignore'a ekledim (gizli tutmak için)
- [ ] `flutter pub get` komutunu çalıştırdım

---

## 🆘 Sorun Giderme

### "FileNotFound: .env" hatası
- `.env` dosyasının proje kök dizininde olduğundan emin ol
- `.env` ve `pubspec.yaml` aynı seviyede olmalı

### "null" değerleri görmek
- `.env` dosyasında boş alanlar var
- Tüm değerleri Firebase Console'dan kontrol et

### Uygulama Firebase'e bağlanmıyor
1. `.env` dosyasının doğru olduğundan emin ol
2. `flutter clean` ve `flutter pub get` çalıştır
3. Uygulamayı yeniden derle: `flutter run`

