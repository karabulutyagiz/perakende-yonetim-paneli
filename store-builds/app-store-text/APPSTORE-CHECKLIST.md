# App Store Connect — Submit for Review Checklist (ParaSende)

> Önceki red'leri tekrar yememek için hem **Apple guideline'larından bilinen tetikleyiciler** hem **mevcut repo durumu** birlikte taranmıştır. Her madde için ✅ (hazır), ⚠️ (kullanıcının elle yapması gereken), ❌ (eksik — koda eklendi) işareti.

---

## 0. Bu submission'da yeni olan
- ✅ **Apple 5.1.1(v) in-app account deletion eklendi** (`backend/.../auth.py` DELETE `/auth/account`, mobile `account_screen.dart`). Bu, ileride Apple'ın "review notes ile email rotası kabul ettik" ayrıcalığını kaldırması durumunda korur.
- ✅ **Login ekranı brand**: "Toptan perakende paneli" → **ParaSende** + market ikonu yerine `assets/icon/parasende.png` logosu.
- ✅ **Splash brand**: aynı logo (`main.dart` _BootSplash).

> Yeni IPA üretmen ZORUNLU (mevcut `ParaSende.ipa` 2026-05-19 tarihli, bu düzeltmeleri içermez). TestFlight'a yeni build atıp Production'a onu seç.

---

## 1. Binary / Build

| Kontrol | Durum | Not |
|---|---|---|
| `pubspec.yaml` versiyonu | ✅ 1.0.0+4 | TestFlight'taki ile çakışırsa **1.0.0+5'e bump et** ve yeniden archive |
| `CFBundleDisplayName` = ParaSende | ✅ `Info.plist:14` |  |
| `CFBundleName` = ParaSende | ✅ `Info.plist:18` |  |
| `LSRequiresIPhoneOS` = true | ✅ | iPhone-only (TARGETED_DEVICE_FAMILY=1) |
| `ITSAppUsesNonExemptEncryption` = false | ✅ | Export compliance otomatik geçer |
| ATS (App Transport Security) | ✅ | Sadece `localhost` exception; production HTTPS (`toptanperakende.online`) için ek key yok |
| `NSPhotoLibraryUsageDescription` (TR) | ✅ | Fatura dekontu kaydı için |
| `NSPhotoLibraryAddUsageDescription` (TR) | ✅ | Galeri'ye yazma |
| `NSCameraUsageDescription` | n/a | `image_picker.camera` kullanılmıyor (`grep ImageSource` boş) |
| `NSLocationWhenInUseUsageDescription` | n/a | Konum kullanılmıyor |
| Bitcode | n/a | Xcode 14+'da kaldırıldı |

---

## 2. Apple'ın EN SIK red sebepleri ve durumumuz

### 2.1 Guideline 5.1.1(v) — Account Deletion
> "Apps that support account creation **must offer account deletion within the app**."
- ✅ Bu submission'la birlikte **in-app silme akışı eklendi** (Hesabım → Hesabımı sil → parola + "SİL" onayı).
- ✅ Web seçeneği de mevcut: `https://toptanperakende.online/legal/delete-account.html`.
- ⚠️ App Privacy → Privacy Choices section'da "Account Deletion" linklerini gir.

### 2.2 Guideline 2.1 — Information Needed (Demo Account)
- ✅ `mobile/ios/fastlane/metadata/review_information/` içinde `demo_user.txt`, `demo_password.txt`, `notes.txt` var.
- ⚠️ **Demo hesabın production'da gerçekten login olabildiğinden emin ol.** Bozulduysa yeni tenant aç. Aşağıda komut.

### 2.3 Guideline 2.3 — Accurate Metadata
- ✅ `tr.txt`'deki description ile uygulama özellikleri birebir uyuşuyor.
- ✅ Screenshot'lar gerçek UI ekranları (`app-store-screenshots/iphone-67/`), mockup değil.
- ⚠️ Screenshot'larda görünen veriler **gerçekçi olmalı** (Lorem ipsum yok). Mevcut görseller gerçek mock data ile dolu — ✅.

### 2.4 Guideline 2.5.1 — Software Requirements / Private APIs
- ✅ Sadece Flutter + onaylı plugin'ler (dio, riverpod, go_router, fl_chart, pdf, image_gallery_saver_plus, share_plus, permission_handler, secure_storage). Hepsi App Store'a uyumlu.

### 2.5 Guideline 4.0 — Design / 4.2 Minimum Functionality
- Risk düşük: uygulama tam işlevsel CRUD + ödeme akışı + raporlar.

### 2.6 Guideline 1.5 — Developer Information (Support URL)
- ✅ `tr.txt` `supportUrl = https://toptanperakende.online/legal/support.html`. Açılır olduğunu **şimdi tarayıcıdan doğrula.**

### 2.7 Guideline 5.1.1(i) — Privacy Policy
- ✅ `appInfo/tr.txt` `privacyPolicyUrl = https://toptanperakende.online/legal/privacy.html`. Açılır olduğunu doğrula.

### 2.8 Guideline 3.1.1 — In-App Purchase
- n/a: hiçbir IAP yok, dış ödeme akışı yok. ParaSende b2b işletme yönetimidir — Apple "consumer'a fiziksel hizmet" diye sınıflar, 3.1.3 dışındadır.

### 2.9 ATS / HTTPS
- ✅ Production HTTPS aktif (Caddy + Let's Encrypt).
- ⚠️ `RUNBOOK.md`'de "iOS ATS plain-HTTP IP exception ile çalışıyor (geçici)" notu var **ama Info.plist'te artık böyle bir exception yok**. Eski not artık güncel değil — durum temiz.

### 2.10 App Tracking Transparency
- n/a: Hiçbir third-party tracker/SDK yok (analytics, ads, attribution sıfır). ATT prompt gerekmez.

---

## 3. App Privacy (Connect form'u)

App Store Connect → App Privacy → **Data Collection** seç:

**Data Used to Track You:** None (hiç).

**Data Linked to You:** (her biri için "App Functionality" + ilgili kategori)
- Contact Info → Name, Email Address, Phone Number, Physical Address
- Financial Info → Other Financial Info (fatura/borç)
- User Content → Photos or Videos (ürün görseli), Other User Content (fatura PDF)
- Identifiers → User ID
- Usage Data → Product Interaction (analytics + functionality)
- Diagnostics → Crash Data, Performance Data, Other Diagnostic Data

**Data Not Linked to You:** None.

---

## 4. Submission öncesi son kontrol (5 dakika)

1. `https://toptanperakende.online/legal/privacy.html` aç → 200 dönüyor ✅
2. `https://toptanperakende.online/legal/support.html` aç → 200 ✅
3. `https://toptanperakende.online/legal/delete-account.html` aç → 200 ✅
4. Demo hesapla TestFlight build'e login ol → ürün listesini gör → Hesabım → "Hesabımı sil" butonu görünüyor mu → İptal et.
5. App Store Connect → My Apps → ParaSende → version 1.0 → Build seç → Submit for Review.

---

## 5. Sık unutulan rejection sebepleri (referans)

- Test reviewer'ın IP'sini geofence ile bloklamak → red. (Bizde geofence yok ✅)
- Demo hesabı CAPTCHA / OTP'ye düşürmek → red. (Bizde yok ✅)
- App Store'da bahsedilmeyen üçüncü taraf hesap zorunluluğu → red. (Bizde signup ve login açıkça anlatılmış ✅)
- Beta / "coming soon" yazıları → red. (Description'da yok ✅)
- Crash → red. Build'i TestFlight'ta en az 5 dk gez, crash logu yok.
