# Google Play Data Safety Formu — ParaSende Cevap Taslağı

Privacy policy ile uyumlu doldurulmuştur (`legal/privacy.html`). Play Console > App content > Data safety bölümüne bu cevaplarla gir.

---

## 1. Veri toplama ve paylaşma

**Does your app collect or share any of the required user data types?**
→ **Yes**

**Is all of the user data collected by your app encrypted in transit?**
→ **Yes** (HTTPS/TLS, WSS — Caddy + Let's Encrypt)

**Do you provide a way for users to request that their data be deleted?**
→ **Yes** — URL: https://toptanperakende.online/legal/delete-account.html

---

## 2. Toplanan veri türleri

Aşağıdakileri "Collected" olarak işaretle. Her biri için: **Toplanıyor mu / Paylaşılıyor mu / Optional mı / Amaç ne?**

### Personal info
| Veri | Toplanır | Paylaşılır | Optional | Amaç |
|---|---|---|---|---|
| Name (ad soyad) | ✅ | ❌ | Required | Account management |
| Email address | ✅ | ❌ | Required | Account management, Account creation, App functionality |
| User IDs | ✅ | ❌ | Required | Account management, App functionality |
| Phone number | ✅ | ❌ | Optional | App functionality (müşteri kayıtları) |
| Address | ✅ | ❌ | Optional | App functionality (müşteri kayıtları) |

### Financial info
| Veri | Toplanır | Paylaşılır | Optional | Amaç |
|---|---|---|---|---|
| Purchase history | ✅ | ❌ | Required | App functionality (fatura/sipariş kayıtları) |
| Other financial info | ✅ | ❌ | Required | App functionality (borç/tahsilat kayıtları — uygulamanın temel işlevi) |

> Not: Burada "purchase history" Google'ın in-app purchase sense'i değil — kullanıcı kendi işletme satışlarını giriyor. Açıklama alanına şunu yaz: **"İşletme sahibinin kendi müşterilerine kestiği faturalar ve borç kayıtları. Google Play ödemeleri ile ilgisi yoktur."**

### Photos and videos
| Veri | Toplanır | Paylaşılır | Optional | Amaç |
|---|---|---|---|---|
| Photos | ✅ | ❌ | Optional | App functionality (ürün görseli, işletme logosu, fatura PDF kaydı/paylaşımı) |

### Files and docs
| Veri | Toplanır | Paylaşılır | Optional | Amaç |
|---|---|---|---|---|
| Files and docs | ✅ | ❌ | Optional | App functionality (fatura PDF oluşturma/paylaşma) |

### App activity
| Veri | Toplanır | Paylaşılır | Optional | Amaç |
|---|---|---|---|---|
| App interactions | ✅ | ❌ | Required | Analytics, App functionality (oturum/erişim logları) |
| Other actions | ✅ | ❌ | Required | App functionality (sipariş/fatura akışı) |

### App info and performance
| Veri | Toplanır | Paylaşılır | Optional | Amaç |
|---|---|---|---|---|
| Crash logs | ✅ | ❌ | Required | App functionality, Diagnostics |
| Diagnostics | ✅ | ❌ | Required | App functionality, Diagnostics |

### Device or other IDs
| Veri | Toplanır | Paylaşılır | Optional | Amaç |
|---|---|---|---|---|
| Device or other IDs | ❌ |  |  | (toplamıyoruz — sadece uygulama içi user ID) |

---

## 3. TOPLAMADIĞIN — "No" işaretle

- ❌ Location (precise / approximate)
- ❌ Web browsing history
- ❌ Health and fitness
- ❌ Messages (SMS / e-mail / IM içerikleri)
- ❌ Audio (voice / sound recordings / music)
- ❌ Calendar events
- ❌ Contacts (telefon rehberi)
- ❌ Race & ethnicity / political / religious / sexual orientation
- ❌ Payment info (kart bilgisi — Google'ın istediği anlamda **ödeme bilgisi toplamıyoruz**)
- ❌ Credit info / Credit score

---

## 4. Güvenlik uygulamaları

- ✅ Data is encrypted in transit (TLS/WSS — Caddy + Let's Encrypt, prod HTTPS)
- ✅ Users can request that their data be deleted — **iki yöntem**:
  - **In-app:** Hesabım → Hesabımı sil (parola + "SİL" onayı ile kalıcı silme)
  - **Web:** https://toptanperakende.online/legal/delete-account.html
- ⚠️ Data is encrypted at rest — EBS encryption durumuna göre işaretle:
  ```
  aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=<ID> \
    --query 'Volumes[*].[VolumeId,Encrypted]' --output table
  ```
  Encrypted=True ise ✅ işaretle, False ise işaretleme (yalan beyan = red).
- ❌ Committed to follow Google Play Families Policy (uygulama çocuklara değil işletmelere yönelik)
- ❌ Independent security review (yapılmadı)

---

## 5. Eklenmesi gereken yan formlar

### Permissions Declaration (`permission_handler` + `image_gallery_saver_plus` + `share_plus` yüzünden)
AndroidManifest izinleri (kontrol: `mobile/android/app/src/main/AndroidManifest.xml`):
- `INTERNET` → standart, beyan gerekmez.
- `READ_MEDIA_IMAGES` (API 33+) → Photo and video permissions formu.
- `READ_EXTERNAL_STORAGE` (maxSdk=32) → eski Android için, kapsamlı erişim değil.
- `WRITE_EXTERNAL_STORAGE` (maxSdk=28) → çok eski Android için.

Console'da **Sensitive permissions and APIs** sayfası açılırsa:
- **Use case:** "Kullanıcı, kestiği faturanın PDF/JPG dekontunu cihaz galerisine kaydedebilir ve müşterisiyle paylaşabilir."
- **Alternative considered:** "Scoped storage / SAF kullanılıyor; geniş depolama erişimi yalnızca eski Android (≤28) için fallback olarak duruyor."
- Console kısa video isterse: Hesabım → Faturalar → bir faturayı aç → "Dekontu kaydet" akışını çek.

### Target audience and content
- **Target age:** 18+ (işletmelere yönelik)
- **Appeals to children:** No

### Content rating questionnaire (IARC)
- Cevaplar tamamen "No" gider (şiddet/cinsel/kumar/uyuşturucu hiçbiri yok) → **Everyone** alır
- Yine de "Users interact" sorusuna **Yes** dersen (sipariş akışı), **PEGI 3 / Everyone** çıkar.

### Government apps / Health apps / News apps
- Hiçbirine **No**

### Ads
- **Does your app contain ads?** → **No**

---

## Bonus: privacy.html'de eksik kalan tek nokta
Privacy policy'de **"crash logs / diagnostics topluyoruz"** açıkça yazmıyor (sadece "güvenlik logları, hata ve erişim zamanları" diyor — bu Diagnostics sayar). Bu yeterli ama istersen `legal/privacy.html`'ye bir cümle daha eklenebilir.
