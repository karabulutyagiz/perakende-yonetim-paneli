export const tr = {
  meta: {
    brand: "Zirve Toptan",
    tagline: "Toptan ve perakende işletmeler için stok, fatura, borç ve raporlama paneli.",
    description:
      "Zirve Toptan; ürün, müşteri, sipariş, fatura ve borç süreçlerini tek panelden yönetmek isteyen küçük ve orta ölçekli toptan/perakende işletmeleri için ücretsiz bir SaaS uygulamasıdır.",
  },
  nav: {
    home: "Ana sayfa",
    features: "Özellikler",
    pricing: "Fiyatlandırma",
    about: "Hakkımızda",
    faq: "SSS",
    contact: "İletişim",
    signIn: "Panele giriş",
    download: "İndir",
    language: "Dil",
  },
  hero: {
    eyebrow: "Toptan & perakende için yönetim paneli",
    title: "İşletmenizin stok, fatura ve borcunu tek panelden yönetin.",
    subtitle:
      "Zirve Toptan küçük ve orta ölçekli toptan/perakende işletmeler için tasarlanmış, mobil ve web tabanlı, tamamen ücretsiz bir yönetim panelidir. Ürünleri ekleyin, müşteriye fatura kesin, vadeli borçları takip edin, raporlardan günü kapatın.",
    primaryCta: "Panele giriş yap",
    secondaryCta: "Özellikleri incele",
    badge: "Tamamen ücretsiz · Reklam yok · Uygulama içi satın alma yok",
  },
  highlights: {
    title: "Sahada test edilmiş, sade bir yönetim deneyimi",
    subtitle:
      "Apple App Store ve Google Play üzerinden indirilebilen mobil uygulama, gün içinde gişe başında; web admin paneli ise ofiste sahibi/yöneticisi için tasarlandı.",
    items: [
      {
        title: "Stok yönetimi",
        body: "Kategori, ürün, görsel, fiyat ve stok adedi. Stok değişiklikleri tüm cihazlara anlık yansır.",
      },
      {
        title: "Müşteri ve faturalama",
        body: "Müşteri kartı, hızlı fatura kesimi, peşin veya vadeli satış, otomatik stok düşümü.",
      },
      {
        title: "Vadeli borç takibi",
        body: "Her vadeli fatura için 15 günlük vade. Yeşil/sarı/kırmızı/gecikti renkleriyle anlık durum.",
      },
      {
        title: "Canlı senkronizasyon",
        body: "Web paneldeki bir değişiklik mobilde anında görünür. WebSocket tabanlı, sayfa yenileme yok.",
      },
      {
        title: "Raporlar",
        body: "Günlük/aylık satış, en çok alan müşteri, kategori dağılımı, açık borç toplamı.",
      },
      {
        title: "Güvenli giriş",
        body: "JWT tabanlı oturum, Argon2id parola hashleme, parola değişiminde tüm cihazlardan otomatik çıkış.",
      },
    ],
  },
  forWho: {
    title: "Kimler için?",
    body:
      "Bakkal, market, kasap, manav, kuruyemişçi, tekel bayisi, hırdavatçı, tuhafiyeci, oto yedek parça, kırtasiyeci, gıda toptancısı… Kısaca elinde stoğu, müşterisi ve vadeli alacağı olan her küçük/orta ölçekli işletme.",
    points: [
      "Tek bir işletmenin kendi ürünlerini, müşterilerini, faturalarını yönetir.",
      "Birden fazla cihazdan aynı anda kullanılabilir; gişe mobilde, sahip web panelde.",
      "Türkçe arayüz, Türk perakende akışına göre tasarım.",
    ],
  },
  pricing: {
    title: "Fiyatlandırma",
    subtitle: "Zirve Toptan tamamen ücretsizdir.",
    bigStatement: "0 ₺",
    bigCaption: "Aylık · Yıllık · Her zaman",
    description:
      "Uygulamanın tüm özellikleri ücretsizdir. Aylık abonelik, paket satışı, ekstra modül ücreti, kullanıcı başına ücret veya uygulama içi satın alma yoktur. Reklam göstermiyoruz, kullanıcı verisini satmıyoruz.",
    included: [
      "Sınırsız ürün, müşteri ve fatura",
      "Vadeli borç takibi ve raporlar",
      "Mobil + web admin panel erişimi",
      "Canlı senkronizasyon",
      "E-posta destek",
      "Hesabınızı istediğiniz an silebilme",
    ],
    notIncluded: [
      "Uygulama içi satın alma yok",
      "Abonelik yok",
      "Reklam yok",
      "Premium/kilitli özellik yok",
    ],
    cta: "Panele giriş yap",
    footnote:
      "Zirve Toptan bireysel bir geliştirici tarafından yürütülen, açık kaynak ilkelerine yakın bir portfolyo + ürün projesidir. Ücretsiz oluşu sürdürülebilirliği etkileyebilecek bir büyüme olursa duyurulur; mevcut özellikler kullanıcılardan ücret talep edilmeden çalışmaya devam eder.",
  },
  features: {
    title: "Özellikler",
    subtitle:
      "Tek bir işletmenin gün içindeki tipik tüm akışlarını karşılayacak şekilde tasarlandı.",
    sections: [
      {
        title: "Ürün ve stok",
        body:
          "Kategorilere bölünmüş ürün kataloğu, ürün başına görsel (S3 üzerinde private depolama, presigned URL ile güvenli yükleme), stok adedi, satış fiyatı. Stok her fatura/sipariş ile otomatik düşer.",
        bullets: [
          "Kategori bazlı listeleme",
          "Görsel yükleme",
          "Hızlı arama",
          "Stok adedi takibi",
        ],
      },
      {
        title: "Müşteri yönetimi",
        body:
          "Müşteri kartlarında ad, telefon, adres, açık borç bakiyesi. Müşteri seçince geçmiş faturalar ve toplam borç görünür.",
        bullets: [
          "Müşteri kartı",
          "Geçmiş faturalar",
          "Açık bakiye özeti",
        ],
      },
      {
        title: "Sipariş ve fatura",
        body:
          "Mobilden veya web panelden müşteri seçip ürün ekleyerek hızlıca fatura kesilir. Peşin veya vadeli olarak işaretlenir; vadeli ise borç kaydı oluşur.",
        bullets: [
          "Peşin / vadeli ayrımı",
          "Otomatik stok düşümü",
          "Fatura geçmişi",
          "Hızlı müşteri ekleme",
        ],
      },
      {
        title: "Borç takibi",
        body:
          "Her vadeli fatura için varsayılan 15 günlük vade. Sistem her gün yeniden hesaplar; durum yeşil/sarı/kırmızı/gecikti olarak işaretlenir. Tahsil edilen ödemeler düşülür.",
        bullets: [
          "≥ 8 gün: yeşil (güvenli)",
          "4–7 gün: sarı (yaklaşıyor)",
          "0–3 gün: kırmızı (acil)",
          "Vade geçmiş: koyu kırmızı + gecikme günü",
        ],
      },
      {
        title: "Raporlama",
        body:
          "Dashboard üzerinde günlük/aylık ciro, açık borç toplamı, en çok alan müşteriler, kategori bazlı satış dağılımı. Sade grafikler, fl_chart ile.",
        bullets: [
          "Günlük & aylık satış",
          "En çok alan 5 müşteri",
          "Kategori dağılımı",
          "Açık borç özeti",
        ],
      },
      {
        title: "Canlı senkronizasyon",
        body:
          "WebSocket bağlantısıyla web paneldeki bir ürün/fiyat/borç değişikliği mobilde anında görünür. Birden fazla kullanıcı/cihaz aynı işletmeyi aynı anda kullanabilir.",
        bullets: [
          "Anlık veri akışı",
          "Çoklu cihaz desteği",
          "Sayfa yenileme yok",
        ],
      },
      {
        title: "Güvenlik",
        body:
          "Parolalar Argon2id ile hashlenir. Oturumlar JWT tabanlıdır; parola değişiminde tüm cihazlardaki oturumlar geçersizleşir. Veriler özel sunucularda saklanır, üçüncü taraflarla paylaşılmaz.",
        bullets: [
          "Argon2id parola hashleme",
          "JWT + refresh rotation",
          "Tenant izolasyonu (her işletmenin verisi ayrı)",
          "Hesap ve veri silme talebi",
        ],
      },
      {
        title: "Uygulama içinde hesap oluşturma ve silme",
        body:
          "Mobil uygulamada giriş ekranından doğrudan işletme hesabı başvurusu yapılır; aynı uygulama içinden hesap silme talebi başlatılabilir. Hesap silme ile birlikte işletmeye ait tüm veriler kaldırılır.",
        bullets: [
          "Uygulama içi kayıt",
          "Uygulama içi hesap silme",
          "Veri dışa aktarma (talep üzerine)",
        ],
      },
    ],
  },
  about: {
    title: "Hakkımızda",
    lead:
      "Zirve Toptan, gerçek bir ihtiyaçtan doğmuş, bireysel bir geliştirici tarafından yürütülen küçük ve odaklı bir projedir.",
    paragraphs: [
      "Türkiye'deki birçok küçük işletme; ürünlerini bir deftere, faturalarını bir başka deftere, vadeli borçlarını ise çoğunlukla akıldan takip ediyor. Zirve Toptan bu üçünü tek bir yerde, telefondan ve bilgisayardan aynı anda erişilebilir şekilde toplamak için tasarlandı.",
      "Uygulama; mobil tarafta Flutter, web admin tarafında yine Flutter Web, sunucu tarafında Python (FastAPI) ve PostgreSQL ile yazılmıştır. Veriler güvenli bulut altyapısında saklanır; üçüncü taraflara satılmaz, reklam amaçlı işlenmez.",
      "Zirve Toptan ticari amaçla satılmayan, kullanıcılarından hiçbir ücret talep etmeyen bir uygulamadır. Aynı zamanda geliştirici için ürün geliştirme, mimari kurma ve operasyonel sahiplik anlamında bir öğrenme ve portfolyo çalışmasıdır.",
    ],
    contact: {
      title: "İletişim",
      email: "destek@toptanpanel.com",
      legal: "Yasal sayfalar",
    },
  },
  faq: {
    title: "Sıkça Sorulan Sorular",
    subtitle:
      "Aşağıdaki sorular Zirve Toptan'Ä±n işleyişini, iş modelini, gizlilik yaklaşımını ve teknik altyapısını detaylı şekilde açıklar. Apple App Review veya başka bir denetim mekanizmasının sorabileceği her temel sorunun cevabı bu sayfada vardır.",
    groups: [
      {
        title: "İş modeli ve App Store kuralları",
        items: [
          {
            q: "Zirve Toptan ücretli mi?",
            a: "Hayır. Uygulamanın hiçbir özelliği ücretli değildir. Aylık veya yıllık abonelik, paket satışı, kullanıcı/cihaz başına ücret veya uygulama içi satın alma (In-App Purchase) yoktur. Reklam göstermiyoruz, kullanıcı verisi satmıyoruz, sponsorluk göstermiyoruz.",
          },
          {
            q: "Uygulama içinde herhangi bir ödeme akışı var mı?",
            a: "Hayır. Uygulamanın hiçbir ekranında ücret, abonelik, kredi paketi, kilit açma, premium yükseltme, sanal para veya başka bir satın alma akışı yoktur. App Store / Google Play faturalandırması üzerinden de hiçbir satış yapılmaz. Hiçbir üçüncü taraf ödeme entegrasyonu (Stripe, PayPal, iyzico vb.) eklenmemiştir.",
          },
          {
            q: "Daha önce başka bir yerden satın alınmış bir özellik var mı?",
            a: "Hayır. Zirve Toptan için hiçbir kanalda — web sitesi, mağaza, kurumsal satış, telefon siparişi, distribütör vb. — satış yapılmaz. Uygulamada 'önceden satın alınmış', 'premium aboneliğinizle açılır' veya benzeri bir içerik, özellik veya hizmet yoktur.",
          },
          {
            q: "App Store / Google Play dışından açılan dijital içerik var mı?",
            a: "Hayır. Uygulama dışındaki bir mağazadan, web ödemesinden veya kuruluş aboneliğinden açılan hiçbir dijital içerik yoktur. Bütün özellikler her kullanıcıya, kayıt anından itibaren ücretsiz şekilde açıktır.",
          },
          {
            q: "Kurumsal (enterprise) bir hizmet mi? Tek bir şirket için mi yapıldı?",
            a: "Hayır. Zirve Toptan belirli bir şirket için yazılmış kurumsal bir iç araç değildir. Türkiye'deki herhangi bir küçük/orta ölçekli toptan veya perakende işletme sahibi App Store veya Google Play'den uygulamayı indirip 'İşletme hesabı aç' ekranından kayıt başvurusu gönderebilir. Davet kodu, kurumsal sözleşme, lisans anahtarı veya iş ortaklığı şartı yoktur.",
          },
          {
            q: "Kim ödüyor? Hizmet bedeli kimden alınıyor?",
            a: "Kimseden. Geliştirici Zirve Toptan'Ä± hem küçük işletmelere ücretsiz bir araç sağlamak hem de ürün geliştirme ve cloud operasyon deneyimi için yürütmektedir. Altyapı maliyetleri (AWS) geliştirici tarafından karşılanır; son kullanıcıdan hiçbir şekilde ücret istenmez.",
          },
        ],
      },
      {
        title: "Hesap, kayıt ve giriş",
        items: [
          {
            q: "Hesap nasıl açılır?",
            a: "Mobil uygulama giriş ekranındaki 'Hesabın yok mu? · İşletme hesabı aç' bağlantısına dokunulur. Açılan kayıt ekranında işletme adı, ad-soyad, e-posta, isteğe bağlı telefon ve parola girilir. 'Hesap aç' butonu başvuruyu sunucuya iletir. Başvuru bir yönetici tarafından kontrol edilip onaylandıktan sonra hesap aktif edilir; bu çoğunlukla aynı iş günü içinde tamamlanır.",
          },
          {
            q: "Onaylı bir test/demo hesabı var mı?",
            a: "Evet. App Store / Google Play inceleme ekipleri uygulamayı uçtan uca test edebilsin diye önceden onaylanmış bir demo hesabı tutulmaktadır. Demo bilgileri App Store Connect üzerindeki 'App Review Notes' kısmında ve gerektiğinde destek@toptanpanel.com adresinden talep edilerek sağlanır. Demo hesap public olarak burada paylaşılmaz çünkü gerçek bir işletmenin verilerini içerir.",
          },
          {
            q: "Yeni kayıt olunca direkt giriş yapılabiliyor mu, neden onay var?",
            a: "Yeni kayıtlar admin onayı bekler. Bu adım kötüye kullanımı (sahte işletmeler, otomasyon, suistimal) önlemek ve gerçek işletmelerin temiz bir veri ortamında çalışmasını sağlamak içindir. Banka, fintech ve B2B SaaS dünyasındaki standart 'business onboarding' adımıyla aynı mantıkta çalışır. Onay genellikle aynı iş günü içinde tamamlanır.",
          },
          {
            q: "Şifremi unuttum, ne yapmalıyım?",
            a: "destek@toptanpanel.com adresine, hesap açtığınız e-posta ile birlikte parola sıfırlama talebi gönderebilirsiniz. Yakın tarihte uygulama içi 'Parolamı unuttum' akışı da eklenecektir.",
          },
          {
            q: "Web admin panele nasıl girilir?",
            a: "Bu sitenin sağ üstündeki 'Panele giriş' bağlantısından veya doğrudan toptanperakende.online/#/y/giris adresinden ulaşabilirsiniz. Mobil uygulamada kullandığınız e-posta ve parola ile aynı hesaptan giriş yaparsınız.",
          },
          {
            q: "Birden fazla cihazdan aynı anda kullanabilir miyim?",
            a: "Evet. Bir işletme hesabı, aynı anda birden fazla mobil cihaz ve web tarayıcısından kullanılabilir. WebSocket tabanlı canlı senkronizasyon sayesinde bir cihazda yapılan değişiklik diğer cihazlarda anında görünür.",
          },
        ],
      },
      {
        title: "Veriler, gizlilik ve silme",
        items: [
          {
            q: "Hangi kişisel veriler toplanıyor?",
            a: "Yalnızca uygulamanın çalışması için zorunlu olan veriler: işletme adı, ad-soyad, e-posta, isteğe bağlı telefon, hashlenmiş parola, oturum kayıtları (cihaz tipi ve son giriş gibi), uygulama içinde sizin oluşturduğunuz iş verileri (ürünler, müşteriler, faturalar, borçlar) ve yüklediğiniz ürün görselleri. Konum, kişiler, mikrofon, sağlık verisi vb. hiçbir hassas izin istenmez.",
          },
          {
            q: "Verilerim üçüncü taraflarla paylaşılıyor mu?",
            a: "Hayır. Verileriniz reklam, pazarlama veya analiz amacıyla satılmaz veya paylaşılmaz. Sadece hizmetin çalışması için zorunlu altyapı sağlayıcılarıyla (AWS — sunucu, veritabanı, dosya depolama) ve yasal yükümlülük halinde yetkili kamu kurumlarıyla paylaşım söz konusu olabilir.",
          },
          {
            q: "Verilerim nerede ve nasıl saklanıyor?",
            a: "Veriler AWS üzerinde Almanya / Avrupa bölgesindeki sunucularda saklanır (eu-central-1). Parolalar Argon2id ile geri döndürülemez biçimde hashlenir. Ürün görselleri AWS S3'te private bucket içinde tutulur ve sadece presigned URL ile geçici erişime açılır. Veritabanı public erişime kapalı, izole bir alt ağda çalışır.",
          },
          {
            q: "Başka bir işletmenin verisini görebilir miyim? Tenant izolasyonu nasıl çalışır?",
            a: "Hayır. Her işletme kendi 'tenant' kimliğine sahiptir ve sunucu tarafındaki her sorgu bu kimlikle filtrelenir. Bir işletmenin kullanıcısı diğer bir işletmenin ürünlerine, müşterilerine, faturalarına veya borç kayıtlarına erişemez. Bu izolasyon backend testleriyle de doğrulanır.",
          },
          {
            q: "Hesabımı ve verilerimi silebilir miyim?",
            a: "Evet. Üç yol vardır: (1) Mobil uygulama içinden hesap silme akışını başlatabilirsiniz. (2) Web admin paneldeki 'Hesabım' alanından silme talebi açabilirsiniz. (3) destek@toptanpanel.com adresine e-posta gönderebilirsiniz. Aktif veriler en geç 14 gün içinde, yedekler en geç 30 gün içinde kaldırılır. Detaylar: /legal/delete-account.html",
          },
          {
            q: "Çocuklara yönelik mi?",
            a: "Hayır. Zirve Toptan 18 yaş üstü işletme sahiplerine yöneliktir; çocuklara veya öğrencilere yönelik içerik veya pazarlama içermez, çocuklardan veri toplamaz.",
          },
          {
            q: "Konum, kişiler, mikrofon gibi hassas izin istiyor mu?",
            a: "Hayır. Uygulama yalnızca, sadece kullanıcının kendisi tetiklediğinde — örneğin bir ürün görseli yüklerken — fotoğraf/galeri erişimi isteyebilir. Bunun dışında konum, kişiler, mikrofon, kamera (sürekli erişim), sağlık verisi, takip (App Tracking Transparency kapsamında) gibi hiçbir hassas izin istenmez.",
          },
        ],
      },
      {
        title: "Özellikler, kullanım ve teknik",
        items: [
          {
            q: "Çalışmak için internet gerekli mi?",
            a: "Evet, Zirve Toptan canlı senkronizasyon, çoklu cihaz desteği ve güvenli oturum yönetimi sunduğu için aktif bir internet bağlantısı gerektirir. Geçici bağlantı kesintilerinde uygulama yeniden bağlanmayı dener ve son durumu sunucudan tazeler.",
          },
          {
            q: "Hangi cihazlarda çalışıyor?",
            a: "Mobil: iPhone ve iPad (iOS 15+ önerilir), Android telefon ve tabletler (Android 7+). Web admin: güncel Chrome, Safari, Firefox, Edge tarayıcılarında. Aynı işletme hesabı bütün bu cihazlardan eş zamanlı kullanılabilir.",
          },
          {
            q: "Vadeli borç takibi nasıl çalışıyor?",
            a: "Bir fatura 'vadeli' olarak işaretlenirse, varsayılan 15 günlük vade ile bir borç kaydı oluşur. Sistem her gün TRT 01:00'de tüm borçları yeniden hesaplar ve duruma göre renklendirir: ≥ 8 gün yeşil (güvenli), 4–7 gün sarı (yaklaşıyor), 0–3 gün kırmızı (acil), vade geçmişse koyu kırmızı + kaç gün geçtiği. Müşteriden tahsilat alındığında ödeme borçtan düşülür ve kalan bakiye güncellenir.",
          },
          {
            q: "Fatura PDF veya yazıcı çıktısı var mı?",
            a: "Faturalar uygulama içinde görüntülenir; her faturanın kalemleri, toplamı ve müşterisi listelenir. PDF dışa aktarımı yol haritasında olan bir özelliktir. İhtiyaç olursa destek e-postası üzerinden talep edebilirsiniz.",
          },
          {
            q: "Backend ve altyapı hangi teknolojiler?",
            a: "Backend: Python 3.11 + FastAPI + SQLAlchemy 2.0 + Alembic migrasyonları. Veritabanı: PostgreSQL 16 (AWS RDS, private subnet). Storage: AWS S3 (private bucket + presigned URL). Auth: JWT access + refresh rotation, Argon2id parola hashleme. Canlı senkron: WebSocket. Cron: AWS EventBridge → günlük borç durumu yeniden hesaplama. Container: AWS ECS Fargate + ALB. CDN: AWS CloudFront. Bütün kimlik bilgileri AWS Secrets Manager'da tutulur.",
          },
          {
            q: "Mobil ve web istemcileri hangi teknolojilerde?",
            a: "Mobil uygulama: Flutter (Dart), Riverpod state yönetimi, Dio HTTP istemcisi, go_router. Web admin panel: Flutter Web, aynı state yönetimi katmanı. Marketing sitesi (bu site): Next.js 15 + Tailwind CSS + shadcn/ui.",
          },
          {
            q: "Bildirim (push notification) gönderiyor mu?",
            a: "Şu an hayır. Uygulama herhangi bir push bildirim hizmetine kayıt olmaz ve reklam/pazarlama bildirimi göndermez. İleride sadece kritik operasyonel bildirimler (örn. 'borç vadesi yaklaştı') için, kullanıcı açıkça izin vermek koşuluyla eklenebilir.",
          },
          {
            q: "Açık kaynak mı?",
            a: "Repo public olarak yayımlanmıştır ve mimari bir portfolyo projesi olarak incelenebilir. Ticari kullanım, fork edilen versiyonların Zirve Toptan adıyla yayımlanması veya marka kullanımı için iletişime geçilmesi rica edilir.",
          },
        ],
      },
      {
        title: "Destek ve güncellemeler",
        items: [
          {
            q: "Destek nasıl alınır?",
            a: "destek@toptanpanel.com adresine e-posta göndererek destek alabilirsiniz. Destek talepleri genellikle 3 iş günü içinde yanıtlanır; hesap güvenliği ve veri silme talepleri öncelikli değerlendirilir.",
          },
          {
            q: "Hatalı bir şey gördüm, nasıl bildiririm?",
            a: "destek@toptanpanel.com adresine konu satırında 'Bug raporu' yazıp; hangi ekranda, ne yaptığınızda ve ne beklediğinizi kısaca açıklayan bir e-posta gönderebilirsiniz. Mümkünse ekran görüntüsü veya kısa bir video eklemek tanıyı çok hızlandırır.",
          },
          {
            q: "Güncellemeler nasıl yayımlanıyor?",
            a: "Mobil sürümler App Store ve Google Play üzerinden yayımlanır, normal mağaza güncelleme akışıyla cihazınıza iner. Backend güncellemeleri ise kesintisiz olarak deploy edilir; mevcut oturumlar etkilenmez. Geriye dönük uyumluluk gözetilir, bilinmesi gereken değişiklikler bu sitedeki duyurularda ve destek e-postalarında belirtilir.",
          },
        ],
      },
    ],
  },
  contact: {
    title: "İletişim",
    lead:
      "Hesap, kullanım, hata, veri dışa aktarma veya silme talepleriniz için bize ulaşın.",
    emailLabel: "Genel destek",
    email: "destek@toptanpanel.com",
    privacyLabel: "Gizlilik talepleri",
    legal: {
      privacy: "Gizlilik Politikası",
      support: "Destek sayfası",
      delete: "Hesap ve Veri Silme",
    },
    responseTime:
      "Destek talepleri genellikle 3 iş günü içinde yanıtlanır; hesap güvenliği ve veri silme talepleri öncelikli değerlendirilir.",
  },
  footer: {
    builtBy: "Yağız Karabulut tarafından geliştirildi.",
    rights: "Tüm hakları saklıdır.",
    legal: "Yasal",
    product: "Ürün",
    company: "Şirket",
    privacy: "Gizlilik Politikası",
    support: "Destek Merkezi",
    delete: "Hesap ve Veri Silme",
    terms: "Kullanım Koşulları",
    kvkk: "KVKK Aydınlatma Metni",
    cookies: "Çerez Politikası",
  },
  support: {
    title: "Destek Merkezi",
    lead:
      "Zirve Toptan ile ilgili her türlü hesap, kullanım, hata, gizlilik veya veri silme talebinde size yardımcı oluruz. Aşağıda en sık karşılaşılan sorunların çözümü, doğrudan iletişim yolları ve hata bildirme şablonu vardır.",
    contact: {
      title: "Doğrudan iletişim",
      emailLabel: "Destek e-posta",
      email: "destek@toptanpanel.com",
      altEmailLabel: "Gizlilik & hesap silme",
      altEmail: "destek@toptanpanel.com",
      hoursLabel: "Çalışma saatleri",
      hours: "Pazartesi – Cuma · 09:00 – 18:00 (TRT)",
      slaLabel: "Yanıt süresi",
      sla: "Genel talepler: en geç 3 iş günü içinde. Hesap güvenliği, parola sıfırlama ve veri silme: aynı iş günü içinde.",
      languagesLabel: "Diller",
      languages: "Türkçe (birincil), İngilizce",
    },
    issues: {
      title: "Sık karşılaşılan sorunlar",
      subtitle: "Önce buradaki adımları deneyin; sorununuz çözülmezse aynı başlık altında destek talebi açabilirsiniz.",
      items: [
        {
          q: "Giriş yapamıyorum",
          steps: [
            "E-postanızı küçük harflerle ve fazladan boşluk olmadan yazdığınızdan emin olun.",
            "Parolanızı son zamanlarda değiştirdiyseniz, eski oturumların kapanmış olabileceğini unutmayın.",
            "İnternet bağlantınızı kontrol edin; uygulama hızlı bir bağlantı ister.",
            "Hesabınız aktif değilse 'henüz onaylanmadı' uyarısı gelir — yeni kayıtlar admin tarafından onaylanır (genellikle aynı iş günü).",
            "Hâlâ giremiyorsanız destek@toptanpanel.com adresine 'Giriş sorunu' konusuyla e-posta gönderin.",
          ],
        },
        {
          q: "Yeni açtığım hesabım henüz onaylanmadı",
          steps: [
            "Yeni işletme hesapları, sahteciliği önlemek için bir admin tarafından kontrol edildikten sonra aktif olur.",
            "Onay genellikle aynı iş günü içinde tamamlanır; mesai dışı / hafta sonu kayıtlarda ertesi iş gününe kadar sürebilir.",
            "Başvuruda verdiğiniz e-posta hesabını kontrol etmenizi öneririz — bilgi maili oradan gelir.",
            "24 saatten uzun süredir bekliyorsanız destek@toptanpanel.com'a 'Onay bekliyorum' konusuyla yazın.",
          ],
        },
        {
          q: "Şifremi unuttum",
          steps: [
            "destek@toptanpanel.com adresine, hesabınıza kayıtlı e-postadan parola sıfırlama isteği gönderin.",
            "Talebi hızlandırmak için işletme adınızı ve hesap e-postanızı belirtin.",
            "Sıfırlama e-postası genellikle aynı iş günü içinde, en geç ertesi iş günü içinde gönderilir.",
            "Uygulama içi 'Parolamı unuttum' akışı yol haritasında — yakında eklenecek.",
          ],
        },
        {
          q: "Hesabımı ve verilerimi silmek istiyorum",
          steps: [
            "Mobil uygulamada: profil/ayarlar bölümünden 'Hesabımı sil' akışını başlatabilirsiniz.",
            "Web admin panelden: 'Hesabım' alanında silme talebi açabilirsiniz.",
            "E-posta ile: destek@toptanpanel.com'a 'Zirve Toptan Hesap Silme Talebi' konusuyla yazın, hesap e-postanızı ve işletme adınızı belirtin.",
            "Aktif veriler 14 gün içinde, yedekler 30 gün içinde tamamen silinir. Detay: /legal/delete-account.html",
          ],
        },
        {
          q: "Borç tutarı veya vade tarihi hatalı görünüyor",
          steps: [
            "İlgili faturayı açıp 'kalemler' kısmından satır satır kontrol edin — yanlış adet, yanlış birim fiyat olabilir.",
            "Vade hesaplama tüm açık borçlar için her gün TRT 01:00'de yeniden çalıştırılır; gün içinde küçük gecikmeler olabilir.",
            "Ödeme yapıldığı halde borç düşmediyse, ödeme kaydını 'Müşteri > Ödemeler' altında kontrol edin.",
            "Tutarsızlık devam ediyorsa destek@toptanpanel.com'a fatura numarası ve ekran görüntüsüyle ulaşın.",
          ],
        },
        {
          q: "Ürün görseli yüklenmiyor",
          steps: [
            "Görselin 5 MB'tan küçük ve JPG/PNG formatında olduğundan emin olun.",
            "Uygulama görsel için fotoğraf/galeri izni ister — sistem ayarlarından Zirve Toptan için bu izni açın.",
            "Yavaş bağlantıda yükleme uzayabilir; sayfayı kapatmadan bekleyin.",
            "Hâlâ yükleyemiyorsanız destek e-postasına dosyayı ek olarak gönderin, biz manuel ekleyelim.",
          ],
        },
        {
          q: "Stok adedi tutarsız görünüyor",
          steps: [
            "Stok adedi her fatura/sipariş kaydında otomatik düşer; başka bir cihazdan yapılan satış olabilir.",
            "İlgili ürünün 'satış geçmişi' bölümünden son hareketleri kontrol edin.",
            "Yanlış girdiğiniz bir fatura varsa onu iptal ederek stok geri eklenir.",
            "Manuel düzeltme gerekiyorsa ürün düzenleme ekranından stok adedini güncelleyebilirsiniz.",
          ],
        },
        {
          q: "Web admin paneline giremiyorum",
          steps: [
            "https://toptanperakende.online/#/y/giris adresini güncel bir tarayıcıda (Chrome, Safari, Firefox, Edge) açın.",
            "Tarayıcı önbelleğini temizleyin veya gizli pencere ile deneyin.",
            "Mobil uygulamadakiyle aynı e-posta + parolayı kullanın.",
            "Sayfa hiç yüklenmiyorsa internet bağlantınızı ve adres çubuğundaki yazımı kontrol edin.",
          ],
        },
        {
          q: "İki cihazdaki veri farklı görünüyor",
          steps: [
            "Zirve Toptan WebSocket ile canlı senkronize çalışır; bağlantı kesintisinde geçici olarak gecikme olabilir.",
            "Cihazı kapatıp internet bağlantısını kontrol edin, uygulamayı tekrar açın.",
            "Pull-to-refresh (aşağı kaydırarak yenileme) ile son veriyi tazeleyebilirsiniz.",
            "Sorun devam ederse bir cihazdan çıkış yapıp tekrar giriş yapın.",
          ],
        },
        {
          q: "Bir hata (bug) bildirmek istiyorum",
          steps: [
            "destek@toptanpanel.com adresine, konu satırı 'Bug raporu' olacak şekilde yazın.",
            "Şu bilgileri ekleyin: cihaz (örn. iPhone 14, iOS 17.5), uygulama sürümü, hangi ekranda, ne yaptınız, ne bekliyordunuz, ne oldu.",
            "Mümkünse ekran görüntüsü veya kısa video ekleyin — tanı süresini önemli ölçüde kısaltır.",
            "Onaylanan bug'lar bir sonraki uygulama güncellemesinde düzeltilir; size cevap dönerken yol haritası bilgisi paylaşılır.",
          ],
        },
      ],
    },
    operational: {
      title: "Operasyonel bilgiler",
      items: [
        { label: "Geliştirici / sorumlu", value: "Yağız Karabulut (bireysel geliştirici)" },
        { label: "Ülke", value: "Türkiye" },
        { label: "İletişim e-posta", value: "destek@toptanpanel.com" },
        { label: "Web", value: "toptanperakende.online" },
        { label: "App Store sürümü", value: "1.0 (en güncel sürüm App Store sayfasında)" },
        { label: "Google Play sürümü", value: "1.0 (en güncel sürüm Play Store sayfasında)" },
        { label: "Eskalasyon", value: "İlk yanıttan 5 iş günü içinde çözüm gelmezse aynı e-posta zincirinde 'eskalasyon' yazarak hatırlatma yapabilirsiniz." },
      ],
    },
    bugTemplate: {
      title: "Hata bildirim şablonu",
      subtitle: "Aşağıdaki şablonu kopyalayıp destek e-postasına yapıştırabilirsiniz.",
      template:
        "Konu: Bug raporu — [kısa başlık]\n\nCihaz: \nİşletim sistemi & sürümü: \nUygulama sürümü: \nEkran / akış: \nYaptığım adımlar:\n  1. \n  2. \n  3. \nBeklediğim sonuç: \nOluşan sonuç: \nEkran görüntüsü / video: (var/yok)\nEk notlar: ",
    },
    reviewerNote: {
      title: "App Store / Google Play inceleme ekibi için not",
      body:
        "Önceden onaylanmış demo hesap bilgileri App Store Connect → App Review → Notes alanında paylaşılmıştır. İhtiyaç halinde destek@toptanpanel.com adresine 'Reviewer demo credentials' konusuyla yazarak da talep edebilirsiniz; aynı iş günü içinde dönüş yaparız.",
    },
    quickLinks: {
      title: "İlgili sayfalar",
      items: [
        { href: "/legal/privacy.html", label: "Gizlilik Politikası" },
        { href: "/legal/terms.html", label: "Kullanım Koşulları" },
        { href: "/legal/kvkk.html", label: "KVKK Aydınlatma Metni" },
        { href: "/legal/cookies.html", label: "Çerez Politikası" },
        { href: "/legal/delete-account.html", label: "Hesap ve Veri Silme" },
        { href: "/sss", label: "Sıkça Sorulan Sorular" },
      ],
    },
  },
  storeBadges: {
    appStore: "App Store'dan indir",
    playStore: "Google Play'den indir",
    soon: "Yakında",
  },
} as const;

// Map the literal-typed Turkish dictionary to a structural type with `string`
// values so other locales can satisfy the same shape without matching the exact
// Turkish strings.
type DeepWiden<T> = T extends string
  ? string
  : T extends readonly (infer U)[]
    ? DeepWiden<U>[]
    : T extends object
      ? { -readonly [K in keyof T]: DeepWiden<T[K]> }
      : T;

export type Dictionary = DeepWiden<typeof tr>;
