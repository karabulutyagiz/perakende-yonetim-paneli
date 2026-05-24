# ParaSende — Play Console Production Yayını Kopyala-Yapıştır Rehberi

Hedef: 5 form + Production release. Toplam ~25 dakika.

Tüm dosyalar bu klasörde (`store-builds/play-store-assets/`).
Sol menü adlarını Play Console'un Türkçe karşılıklarıyla yazdım.

---

## 🚦 ÖN HAZIRLIK (Console'a girmeden bunlar yapılmalı)

### A) Yeni AAB üret (zorunlu)
Mevcut AAB (`store-builds/mobile-aab/app-release.aab`, 2026-05-21) **in-app account deletion içermiyor.** Google Play 15 Mayıs 2026'dan itibaren her hesap-yaratan uygulamada **in-app silme** zorunlu — eski AAB ile yüklersen red yersin.

```bash
# 1. Keystore'u yerleştir (sende lokal)
#    mobile/android/key.properties + .jks dosyaları
ls mobile/android/key.properties mobile/android/*.jks

# 2. AAB üret
cd mobile
flutter clean && flutter pub get
flutter build appbundle --release
# çıktı: build/app/outputs/bundle/release/app-release.aab

# 3. Repo'ya kopyala
cp build/app/outputs/bundle/release/app-release.aab \
   ../store-builds/mobile-aab/app-release.aab
```

### B) Reviewer test hesabı aç (App access için zorunlu)
Production backend'de bir tenant + tenant_owner yarat:
```bash
ssh -i ~/.ssh/toptanperakende.pem ubuntu@18.197.130.173
docker exec -it tp-backend python -m app.scripts.create_admin
# E-posta: playreview@toptanpanel.com
# Ad:     Play Review
# Parola: (güçlü bir parola seç, Console'da gireceksin)
```
> Not: `create_admin` PLATFORM_OWNER yapıyorsa onun yerine tenant_owner için sudo panel üzerinden yeni işletme yarat → owner şifresini al.

### C) EBS encryption durumu (Data Safety formu için)
```bash
# Lokal makinende AWS CLI ile (region eu-central-1):
aws ec2 describe-volumes \
  --filters Name=attachment.instance-id,Values=<INSTANCE_ID> \
  --query 'Volumes[*].[VolumeId,Encrypted]' --output table
```
- `Encrypted = True` → Data Safety'de ✅ "Data is encrypted at rest"
- `Encrypted = False` → kapalı bırak (yalan beyan = red)

### D) "Hesabı sil" akışını cihazda dene
TestFlight veya yeni AAB'yi internal test'e atıp:
1. Login ol → Hesabım → Hesabımı sil → parola + "SİL" → silindi mesajı
2. Aynı hesapla tekrar login → reddedilmeli
3. Bu screen recording'i Console > **Setup > App content > Data deletion** kanıtı olarak hazırda tut (Google bazen istiyor).

---

## 1) Main store listing

**Yer:** Sol menü → "Yayın özeti" altında değil, daha aşağıda → **"Mağazada görünüm" → "Mağaza girişi"** (veya direkt sol menüde "Store listings" arat)

Doğrudan URL kalıbı:
```
https://play.google.com/console/u/2/developers/6543133820910729056/app/<APP_ID>/main-store-listing
```
`<APP_ID>` için ParaSende açıkken URL'den oku.

### Doldur:

#### Uygulama adı (max 30)
```
ParaSende: Stok & Sipariş
```

#### Kısa açıklama (max 80)
```
Ürün, müşteri, sipariş, fatura ve borç takibi tek uygulamada.
```

#### Tam açıklama (max 4000)
```
ParaSende, toptan ve perakende satış yapan işletmeler için geliştirilmiş bütünleşik bir stok, müşteri, sipariş, fatura, borç ve raporlama yönetim uygulamasıdır. Günlük operasyonlarınızı tek bir yerden hızlı ve düzenli şekilde yönetin.

ÖNE ÇIKAN ÖZELLİKLER

• Ürün ve stok yönetimi
Ürünlerinizi kategorilere ayırın, fiyat ve stok bilgilerini güncel tutun. Stok düşüşleri fatura kesildikçe otomatik işlenir.

• Müşteri yönetimi
Müşterilerinizin iletişim bilgilerini, sipariş geçmişini ve borç durumunu tek ekrandan görün.

• Sipariş akışı
Müşteri uygulamasından gelen siparişleri inceleyin, onaylayın ve tek dokunuşla faturaya dönüştürün.

• Fatura ve dekont
Nakit, kart ve borç bileşenli ödeme dağılımı, otomatik stok düşümü ve hata payı bırakmayan ondalık aritmetik ile fatura kesin.

• Borç ve ödeme takibi
Vadesi yaklaşan ve geçmiş borçları renk kodlarıyla görün (yeşil/sarı/kırmızı/gecikmiş). Tahsilatları doğrudan borç kaydından girin.

• Satış ve borç raporları
Günlük, haftalık ve aylık satış grafikleri ile işletmenin nereye gittiğini hızlıca anlayın.

• Web panel ile canlı senkronizasyon
Mağazadaki tablet veya telefonda yapılan her hareket, web yönetim panelinde anında görünür. WebSocket tabanlı senkron sayesinde verileriniz hep güncel.

• Çok kiracılı güvenli yapı
Her işletmenin verisi izole edilir. Argon2id şifreleme, JWT oturum yönetimi ve yetki kontrolü ile ticari verileriniz korunur.

KİMLER KULLANIR

• Toptan satış yapan distribütörler ve bayiler
• Perakende mağazalar
• Çok kasalı ya da çok kullanıcılı işletmeler
• Saha satış ekibi olan firmalar

NASIL ÇALIŞIR

ParaSende, işletme sahibi tarafından açılmış yetkili bir hesap ile kullanılır. Hesap açılışı sonrası çalışanlar ve müşteriler için ayrı erişim seviyeleri tanımlanabilir. Müşteriler kendi cep telefonlarından sipariş atabilir, işletme sahibi siparişi onaylayıp faturaya çevirebilir.

GİZLİLİK

ParaSende verilerinizi yalnızca uygulamanın çalışması için işler, üçüncü taraflarla paylaşmaz. Hesabınızı ve verilerinizi istediğiniz zaman silme hakkına sahipsiniz.

Gizlilik politikası: https://toptanperakende.online/legal/privacy.html
Destek: https://toptanperakende.online/legal/support.html
Hesap silme: https://toptanperakende.online/legal/delete-account.html
```

### Görseller (sürükle-bırak):

| Alan | Dosya |
|---|---|
| Uygulama simgesi (512×512) | `app-icon-1024.png` (Play Console otomatik küçültür) |
| Öne çıkan grafik (1024×500) | `feature-graphic-1024x500.png` |
| Telefon ekran görüntüsü 1 | `01-products.png` |
| Telefon ekran görüntüsü 2 | `02-cart.png` |
| Telefon ekran görüntüsü 3 | `03-orders.png` |
| Telefon ekran görüntüsü 4 | `04-invoice.png` |
| Telefon ekran görüntüsü 5 | `05-debts.png` |
| Telefon ekran görüntüsü 6 | `06-reports.png` |

Sayfa altındaki **"Kaydet"**e bas.

---

## 2) Mağaza ayarları (Store settings)

**Yer:** Sol menü → "Mağazada görünüm" → **"Mağaza ayarları"** veya **"Store settings"**

#### Uygulama kategorisi
- **Uygulama veya oyun:** Uygulama
- **Kategori:** **İş** (Business)
- **Etiketler:** Boş bırak ya da `productivity`, `business`

#### İletişim bilgileri
- **E-posta:** `destek@toptanpanel.com` (mevcut privacy policy ile aynı)
- **Telefon:** boş bırak (zorunlu değil)
- **Web sitesi:** `https://toptanperakende.online`

#### Harici pazarlama (External marketing)
- Reklamım var mı? → **Hayır**

**Kaydet**.

---

## 3) Uygulama içeriği (App content)

**Yer:** Sol menü → **"Politika ve programlar"** veya **"Uygulama içeriği"**

Burada 7-8 alt form var. Sırayla:

### 3.1 Gizlilik politikası
- URL: `https://toptanperakende.online/legal/privacy.html`
- Kaydet.

### 3.2 Uygulama erişimi (App access)
Google reviewer'ı uygulamayı test edebilsin diye **test hesabı vermen gerek**.

- **Tüm işlevsellik kısıtlamasız mı?** → **Hayır, bir kısmı kısıtlı**
- **Yönerge ekle:**
  - **Ad:** `Tenant Owner Test Hesabı`
  - **Kullanıcı adı:** `playreview@toptanpanel.com` (Ön hazırlık B'de açtığın hesap)
  - **Şifre:** _(o hesabın şifresi)_
  - **Yönergeler:**
    ```
    1) Uygulamayı başlatın.
    2) Giriş ekranında yukarıdaki e-posta ve parolayı girin → "Giriş yap".
    3) Hesap tenant_owner rolündedir; ürünler, müşteriler, siparişler, faturalar, borç ve raporlar sekmelerinin tamamına erişebilir.
    4) Hesap silme akışını test etmek için: sağ üstte "Hesabım" simgesi → "Hesabımı sil" → parola + "SİL" → kalıcı silme.
       (Test sonrası hesabı tekrar açmamız için, sildikten sonra bize haber vermenize gerek yok — script ile yeniden oluşturuyoruz.)
    ```
- Kaydet.

> **Önemli:** Bu test hesabını backend'de gerçekten oluşturmadan kaydetme. Yoksa Google review'ı reddeder.
> **Production admin'i (`admin@toptanpanel.com`) ASLA reviewer'a verme** — reviewer veriyi bozarsa production etkilenir.

### 3.3 Reklamlar (Ads)
- **Uygulamamda reklam yok** → seç
- Kaydet.

### 3.4 İçerik derecelendirmesi (Content rating)
**"Anketi başlat"**a tıkla.

- **E-posta:** otomatik dolar
- **Kategori:** **Yardımcı program, üretkenlik, iletişim veya diğer** seç (Verimlilik / Productivity)
- **Anket:** **TÜM SORULARA "HAYIR"** dersin (şiddet/cinsel/uyuşturucu/kumar/kullanıcı oluşturulan içerik vb. — hiçbiri yok)
  - "Uygulama, kullanıcıların birbiriyle iletişim kurmasına izin veriyor mu?" → **Hayır** (müşteri-tenant ilişkisi sınırlı, sosyal değil)
  - "Konum paylaşıyor mu?" → **Hayır**
  - "Kişisel bilgi topluyor mu?" → **Evet** (hesap için e-posta)
  - "Üçüncü taraf reklamları?" → **Hayır**
- "Anketi gönder" → IARC değerlendirmesi otomatik **3+** veya **Herkes** çıkar.

### 3.5 Hedef kitle ve içerik (Target audience)
- **Hedef yaş grubu:** Sadece **18 ve üzeri** seç
- **Çocuklara yönelik mi?** → **Hayır**
- **Reklamlar çocuklara yönelik tasarlandı mı?** → uygulanmıyor
- Kaydet.

### 3.6 Haber uygulaması (News app)
- **Haber uygulaması mı?** → **Hayır**

### 3.7 COVID-19 izleme ve durum uygulamaları
- **Hayır**

### 3.7.5 Hesap silme deklarasyonu (Account deletion) — YENİ ZORUNLU
**Yer:** Sol menü → **"Uygulama içeriği" → "Hesap silme"** (Account deletion)

- **Uygulamanızda kullanıcılar hesap oluşturabiliyor mu?** → **Evet**
- **Kullanıcılar hesabını ve verilerini silebiliyor mu?** → **Evet**
- **Hesap silme yöntemi (in-app)** → **Uygulama içinde Hesabım → Hesabımı sil**
- **Hesap silme web URL** → `https://toptanperakende.online/legal/delete-account.html`
- **Hangi veriler silinir?** (checkbox listesi) →
  - ✅ Hesap (e-posta, ad, parola hash, oturumlar)
  - ✅ İşletme/CRM verisi (müşteri, ürün, kategori)
  - ✅ İşlem verisi (sipariş, fatura, borç, ödeme)
  - ✅ Kullanıcı içerikleri (ürün görselleri — backend tarafında periyodik temizlik)

> **Bu form 15 Mayıs 2026'dan beri ZORUNLU. Bizim yeni AAB'de in-app silme akışı var, web URL de mevcut — iki şart da karşılanıyor.**

---

### 3.8 Veri güvenliği (Data Safety)
Bu en uzun form. `data-safety.md` dosyasındaki tabloyu adım adım uygula:

**Açılışta:**
- **Veri topluyor musunuz?** → **Evet**
- **Aktarımda şifreleme?** → **Evet**
- **Veri silme yolu var mı?** → **Evet** → URL: `https://toptanperakende.online/legal/delete-account.html`

**Veri türleri (Collected data types):**

✅ **Toplanır** olarak işaretle:

| Kategori | Veri | Optional? | Amaç |
|---|---|---|---|
| Personal info | Ad (Name) | Required | Account management |
| Personal info | E-posta | Required | Account management, App functionality |
| Personal info | User ID | Required | Account management, App functionality |
| Personal info | Telefon (Phone number) | Optional | App functionality |
| Personal info | Adres (Address) | Optional | App functionality |
| Financial info | Purchase history | Required | App functionality |
| Financial info | Other financial info | Required | App functionality |
| Photos and videos | Photos | Optional | App functionality |
| Files and docs | Files and docs | Optional | App functionality |
| App activity | App interactions | Required | Analytics, App functionality |
| App activity | Other actions | Required | App functionality |
| App info and performance | Crash logs | Required | App functionality, Diagnostics |
| App info and performance | Diagnostics | Required | App functionality, Diagnostics |

**Hiçbir veri üçüncü tarafla paylaşılmıyor (Shared = No).**

Diğer kategoriler için **"Hayır"** (Location, Web history, Health, Messages, Audio, Calendar, Contacts, Race/ethnicity, Payment info, Credit info, vb.).

**Güvenlik uygulamaları:**
- ✅ Data is encrypted in transit
- ✅ Users can request data deletion
- ❌ Independent security review (yok)

Form gönder.

### 3.9 Devlet uygulamaları (Government apps)
- **Devlet uygulaması mı?** → **Hayır**

### 3.10 Finansal özellikler (Financial features) — eğer sorulursa
- **Finansal hizmet sunuyor mu?** → **Hayır** (bizim uygulamamız işletmenin **kendi içi** muhasebesi, kullanıcıya ödeme veya kredi sunmuyor)

### 3.11 Sağlık uygulamaları
- **Hayır**

---

## 4) Üretim (Production) sürümü oluştur

**Yer:** Sol menü → **"Test edin ve yayınlayın"** → **"Üretim"**

Dahili'den promote etmek istersen:
- Sol menü → **"Dahili test"** → mevcut sürüm satırı → sağda **"Üret"** veya **"Sürümü tanıt"** butonu → **"Üretim"** seç → İncele → Roll out

Veya yeni Production release oluştur:
1. **Üretim** sayfasında **"Yeni sürüm oluştur"**
2. **App bundle** zaten kütüphanede → **"Kitaplıktan ekle"** → versionCode 3 seç
3. **Sürüm notları** (default dil):
   ```
   <tr-TR>
   ParaSende ile tanışın. Stok, müşteri, sipariş, fatura, borç ve raporları tek uygulamadan yönetin. Web panel ile canlı senkron.
   </tr-TR>
   ```
4. **Kaydet** → **İncele**

İnceleme ekranında **sağ üstte ülkeler/bölgeler** seçmen istenir:
- Tek tek seçeceksen: **Türkiye** + dilediğin diğerleri
- Ya da **Tüm ülkeler**

**"Üretime sun"** veya **"Send for review"** → onayla.

---

## 5) Sonrası

Google review süresi: 3-7 gün (ilk gönderim daha uzun olabilir). İncelendi → otomatik yayına çıkar.

Reddedilirse en sık nedenler:
- App access test hesabı çalışmıyor (en sık)
- Data Safety vs. privacy policy uyuşmazlığı
- "Restricted financial features" — uygulama kredi/borç ürünü sunmadığı için sorun olmaz ama Google soru sorabilir

---

## Hızlı dosya yolları

```
store-builds/play-store-assets/
  PLAYBOOK.md                       ← bu dosya
  app-icon-1024.png                 ← uygulama simgesi
  feature-graphic-1024x500.png      ← öne çıkan grafik
  01-products.png ... 06-reports.png ← telefon screenshot'ları
  feature-graphic-1024x500.png

store-builds/mobile-aab/app-release.aab   ← AAB (zaten upload edildi)
```
