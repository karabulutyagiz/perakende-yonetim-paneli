# App Review Yanıtı — Submission 0300b0e6-ba95-48ea-8abc-03522bcf9acf

> ⚠️ **GÜNCEL DEĞİL (önceki tur — 2.3.10 / 1.5 / 3.2).** Bu yanıt, signup'ın
> "admin onayı bekler" olduğu döneme aittir. O turdan SONRA Apple **2.1 / 2.1(a)**
> ile reddetti (release build localhost'a düşüyordu) ve düzeltmeyle birlikte
> **signup artık instant** oldu (onay beklemez). Yeni gönderimde Apple'a giden
> asıl metin için `mobile/ios/fastlane/metadata/review_information/notes.txt`
> kullanılır. Bu dosya yalnızca geçmiş kaydı olarak tutulmaktadır — aşağıdaki
> "DO NOT register a new account" uyarısı artık geçersizdir.

> App Store Connect → My Apps → ParaSende → App Review → Resolution Center
> sayfasında **"Reply"** butonuna basıp aşağıdaki İngilizce metni yapıştır.

---

## REPLY (İngilizce — Apple reviewer'ı için)

```
Hello App Review Team,

Thank you for the detailed feedback. We have addressed all three issues
in build 1.0.0 (7) which has just been uploaded to TestFlight.

---

GUIDELINE 2.3.10 — Non-iOS status bar / menu bar in screenshots

You are correct. The previous screenshots were captured on an Android
emulator during early development and were uploaded by mistake. We have
replaced all 4 iPhone 6.7" screenshots with new images. The new screenshots:

- Are based on real screenshots taken on iOS (no Android system UI).
- Contain only the app's own UI inside an Apple-style device frame on a
  neutral brand background, with short Turkish captions describing the
  feature shown.
- Highlight the app's main features (product catalog, incoming orders,
  sales reports, color-coded debt tracking).

The new screenshots are already attached to version 1.0.0 in App Store
Connect.

---

GUIDELINE 1.5 — Support URL

The previous Support URL (https://toptanperakende.online) pointed to the
landing page, not a support page. We have updated the Support URL in App
Store Connect to:

  https://toptanperakende.online/support

This page lists our support email (destek@toptanperakende.online), the
business address, and direct links to the privacy policy and the in-app
account deletion instructions. The page is live and returns HTTP 200.

---

GUIDELINE 3.2 — Business

We respectfully believe the assessment may have been based on the
previous screenshots, which did not clearly show that any Turkish
wholesale or retail business owner can create their own account.

ParaSende is a general-public B2B SaaS product, not an internal tool
for a specific organization. To make this clearer in build 1.0.0 (9) we
have added an explicit in-app sign-up flow:

  Login screen → tap "Hesabın yok mu? İşletme hesabı aç" → opens the
  Sign-up screen → enter business name, full name, email, optional phone
  and password → tap "Hesap aç" → application is recorded and the user
  is informed it will be activated after admin approval (typically same
  business day, similar to how Stripe / Plaid / many B2B platforms
  onboard new businesses).

⚠️ FOR THE REVIEWER: please DO NOT register a new account from the
sign-up screen — a brand-new account waits for admin approval and
cannot log in immediately. Instead, please use the pre-approved demo
account (playreview@toptanpanel.com / pZ4S7MikKv81soRO) for the full
end-to-end review. The sign-up screen exists to demonstrate that the
public can apply; the approval workflow is just our standard onboarding
practice for business accounts.

To answer your specific questions:

1. Is the app restricted to users who are part of a single company or
   organization?
   No. ParaSende is offered to the general public. Any wholesale or
   retail business owner in Turkey can download the app, create an
   account from the new in-app sign-up screen, and start using the
   product immediately. There is no invitation, pre-approval or
   affiliation requirement.

2. Is the app designed for use by a limited or specific group of
   companies or organizations?
   No. Our target audience is small and medium retail and wholesale
   businesses anywhere in Turkey (and any other Turkish-speaking
   market in the future). Any business can become a customer.

3. What features in the app, if any, are intended for use by the
   general public?
   All features are: the product catalog, cart, invoice creation, color
   -coded debt tracking, sales reports, customer management, in-app
   account creation and in-app account deletion.

4. How do users obtain an account?
   In two equivalent ways:
   - In the app: Login screen → "İşletme hesabı aç" → fill the form
     → application is submitted → admin approves (same-day during
     business hours) → user logs in.
   - On the web: https://toptanperakende.online (same backend, same
     application flow).
   Approval is a short business-vetting step, not a private allowlist —
   any legitimate Turkish wholesale or retail business is accepted.

5. Is there any paid content in the app and if so who pays for it?
   The app is free to download and use. There are no in-app purchases,
   no subscriptions, no ads, and no third-party tracking. The business
   owner only pays for the wholesale goods they exchange with their own
   customers — those payments are recorded in the app but happen outside
   of Apple's payment system (cash, card, debt-on-account between two
   real-world Turkish businesses, not digital content).

---

HOW TO TEST IN BUILD 1.0.0 (7)

Demo account on our production backend (please use this one, it has
full tenant_owner permissions):

  Email:    playreview@toptanpanel.com
  Password: pZ4S7MikKv81soRO

In-app sign-up (Guideline 3.2 verification): On the login screen, tap
"Hesabın yok mu? İşletme hesabı aç" and create a fresh account with
your own email — sign-in happens automatically.

In-app account deletion (Guideline 5.1.1(v)): Tap the "Hesabım"
(Account) icon on the products screen → scroll to "Tehlikeli bölge" →
"Hesabımı sil" → enter the account password and the word "SİL" → the
account, business, customers, products, orders, invoices and debts are
permanently deleted on our backend.

Thank you for your time. Please let us know if any further information
would help with the review.

— ParaSende Team
```

---

## YEDEK — Türkçe özet (App Store Connect İngilizce yanıt ister; sadece
kendi notlar için bırakıyorum)

Apple 3 sebepten reddetti:
- **2.3.10** screenshot'ta Android UI vardı → 4 yeni iPhone mockup PNG
  yüklendi (1290x2796, Apple stilinde bezel + Türkçe başlık).
- **1.5** support URL ana sayfaya gidiyordu → `/support` page'i
  kullanılıyor artık (legal/support.html canlı).
- **3.2** "spesifik organizasyona özel mi" → in-app signup eklendi
  + Resolution Center'da "genel public B2B SaaS, herkes açabilir"
  diye açıklama gönderildi.

Build 1.0.0+7 TestFlight'a yüklendi, processing bittikten sonra
otomatik review'a düşer.
