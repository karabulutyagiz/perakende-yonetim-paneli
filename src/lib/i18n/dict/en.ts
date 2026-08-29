import type { Dictionary } from "./tr";

export const en: Dictionary = {
  meta: {
    brand: "Zirve Toptan",
    tagline:
      "Inventory, invoicing, debt tracking and reporting for wholesale and retail businesses.",
    description:
      "Zirve Toptan is a free SaaS app that helps small and medium wholesale/retail businesses manage products, customers, orders, invoices and credit-sales debt — all from a single panel, on mobile and web.",
  },
  nav: {
    home: "Home",
    features: "Features",
    pricing: "Pricing",
    about: "About",
    faq: "FAQ",
    contact: "Contact",
    signIn: "Sign in",
    download: "Download",
    language: "Language",
  },
  hero: {
    eyebrow: "Management panel for wholesale & retail",
    title: "Run your stock, invoices and customer debt from one place.",
    subtitle:
      "Zirve Toptan is a free, mobile + web management panel designed for small and medium wholesale and retail businesses. Add products, invoice customers, track credit sales, close the day with clean reports.",
    primaryCta: "Sign in to the panel",
    secondaryCta: "See features",
    badge: "Completely free · No ads · No in-app purchases",
  },
  highlights: {
    title: "A clean, field-tested admin experience",
    subtitle:
      "The mobile app — available on Apple App Store and Google Play — lives at the counter; the web admin panel is built for the owner/manager at the office.",
    items: [
      {
        title: "Inventory management",
        body:
          "Categories, products, images, prices, stock counts. Stock changes propagate to every device instantly.",
      },
      {
        title: "Customers & invoicing",
        body:
          "Customer cards, fast invoice creation, cash or credit sales, automatic stock deduction.",
      },
      {
        title: "Credit-sales debt tracking",
        body:
          "Each credit invoice has a 15-day default term. Live status in green/yellow/red/overdue colors.",
      },
      {
        title: "Live sync",
        body:
          "A change on the web panel shows up on the mobile instantly. Built on WebSocket, no refreshing.",
      },
      {
        title: "Reports",
        body:
          "Daily/monthly revenue, top customers, sales by category, total open debt.",
      },
      {
        title: "Secure sign-in",
        body:
          "JWT-based sessions, Argon2id password hashing, automatic sign-out on every device on password change.",
      },
    ],
  },
  forWho: {
    title: "Who is it for?",
    body:
      "Grocers, mini-markets, butchers, greengrocers, hardware stores, stationery shops, auto-parts dealers, food wholesalers — any small/medium business that has stock, customers and credit sales.",
    points: [
      "Manages a single business's products, customers and invoices.",
      "Multi-device: cashier on mobile, owner on the web panel — same data.",
      "Turkish-first interface, designed around Turkish retail workflows.",
    ],
  },
  pricing: {
    title: "Pricing",
    subtitle: "Zirve Toptan is completely free.",
    bigStatement: "$0",
    bigCaption: "Monthly · Yearly · Always",
    description:
      "Every feature in the app is free. There is no monthly subscription, no plans, no add-on modules, no per-user pricing and no in-app purchase. We do not show ads and we do not sell user data.",
    included: [
      "Unlimited products, customers and invoices",
      "Credit-sales debt tracking and reports",
      "Mobile + web admin panel access",
      "Live sync",
      "Email support",
      "Self-service account deletion",
    ],
    notIncluded: [
      "No in-app purchases",
      "No subscriptions",
      "No advertising",
      "No premium/locked features",
    ],
    cta: "Sign in to the panel",
    footnote:
      "Zirve Toptan is a small project run by a single developer, treated as both a real product and a long-form portfolio piece. If sustainability ever changes, we'll announce it; existing features will keep working without charging users.",
  },
  features: {
    title: "Features",
    subtitle:
      "Designed to cover the full daily workflow of a single small/medium business.",
    sections: [
      {
        title: "Products & stock",
        body:
          "Category-based product catalog, an image per product (stored privately on S3 with presigned upload URLs), price and stock count. Stock decreases automatically with each invoice/order.",
        bullets: ["Category-based listing", "Image upload", "Fast search", "Stock tracking"],
      },
      {
        title: "Customer management",
        body:
          "Customer cards with name, phone, address and open-debt balance. Selecting a customer shows their history and total debt.",
        bullets: ["Customer card", "Invoice history", "Open balance summary"],
      },
      {
        title: "Orders & invoices",
        body:
          "Pick a customer, add products, create an invoice in seconds — from mobile or web. Mark it cash or credit; if credit, a debt record is created.",
        bullets: [
          "Cash / credit toggle",
          "Automatic stock deduction",
          "Invoice history",
          "Inline customer creation",
        ],
      },
      {
        title: "Debt tracking",
        body:
          "Default 15-day term for each credit invoice. The system recomputes daily; status is shown in green/yellow/red/overdue. Collected payments reduce the balance.",
        bullets: [
          "≥ 8 days: green (safe)",
          "4–7 days: yellow (approaching)",
          "0–3 days: red (urgent)",
          "Past due: dark red + days overdue",
        ],
      },
      {
        title: "Reports",
        body:
          "Dashboard with daily/monthly revenue, total open debt, top customers and category share. Clean charts via fl_chart.",
        bullets: [
          "Daily & monthly revenue",
          "Top 5 customers",
          "Sales by category",
          "Open debt summary",
        ],
      },
      {
        title: "Live sync",
        body:
          "A WebSocket connection means a product/price/debt change on the web panel appears on every mobile device immediately. Multiple users/devices can run the same business in parallel.",
        bullets: ["Live data stream", "Multi-device support", "No manual refresh"],
      },
      {
        title: "Security",
        body:
          "Passwords are hashed with Argon2id. Sessions are JWT-based; changing a password invalidates every session on every device. Data is stored on private infrastructure and is never shared with third parties for advertising.",
        bullets: [
          "Argon2id password hashing",
          "JWT + refresh rotation",
          "Tenant isolation (each business sees only its own data)",
          "Account & data deletion request",
        ],
      },
      {
        title: "In-app account creation and deletion",
        body:
          "A business owner can apply for an account directly from the mobile sign-in screen and can request account deletion from inside the app. Deleting the account removes every record associated with the business.",
        bullets: ["In-app sign-up", "In-app account deletion", "Data export on request"],
      },
    ],
  },
  about: {
    title: "About",
    lead:
      "Zirve Toptan is a small, focused project built by a single developer to solve a real, everyday problem.",
    paragraphs: [
      "Many small businesses in Turkey track their products in one notebook, invoices in another and credit-sales debt mostly from memory. Zirve Toptan was built to bring all three into one place, accessible from both phone and computer at the same time.",
      "The mobile app is built with Flutter, the web admin panel uses Flutter Web, and the backend is written in Python (FastAPI) on top of PostgreSQL. Data is stored on secure cloud infrastructure; it is not sold to third parties and is not processed for advertising.",
      "Zirve Toptan is not sold commercially and does not charge users. It is also, openly, a learning and portfolio project for the developer behind it — product design, architecture and operational ownership in one piece.",
    ],
    contact: {
      title: "Contact",
      email: "destek@toptanpanel.com",
      legal: "Legal pages",
    },
  },
  faq: {
    title: "FAQ",
    subtitle:
      "These answers explain how Zirve Toptan works, who it's for, how the business model is structured, what data is collected and how it is stored. App Store review teams and any future compliance review will find every relevant answer on this page.",
    groups: [
      {
        title: "Business model & App Store rules",
        items: [
          {
            q: "Is Zirve Toptan paid?",
            a: "No. None of the app's features are paid. There is no monthly or yearly subscription, no plan tier, no per-user/per-device fee and no in-app purchase. We do not show ads, do not sell user data and do not display sponsorships.",
          },
          {
            q: "Is any payment flow present anywhere in the app?",
            a: "No. There is no payment, subscription, credit pack, unlock, premium upgrade, virtual currency or other purchase flow anywhere in the app. Nothing is sold through App Store / Google Play billing either. No third-party payment integration (Stripe, PayPal, iyzico, etc.) is wired up.",
          },
          {
            q: "Are there any 'previously purchased' features unlocked in the app?",
            a: "No. Zirve Toptan is not sold through any channel — no web store, no enterprise sales, no phone orders, no distributors. There is no 'previously purchased', 'unlocked by your premium subscription' or similar content, feature or service in the app.",
          },
          {
            q: "Is any digital content unlocked from outside the App Store / Google Play?",
            a: "No. No digital content is unlocked from any external store, web payment or organizational subscription. All features are available to every signed-up user, for free, from the moment the account is approved.",
          },
          {
            q: "Is this an enterprise service? Was it built for a single company?",
            a: "No. Zirve Toptan is not an internal enterprise tool built for one specific organization. Any small/medium wholesale or retail business owner in Turkey can download the app from the App Store or Google Play and apply for an account from the in-app 'Open a business account' screen. There is no invite code, enterprise contract, license key or partnership requirement.",
          },
          {
            q: "Who pays for the service?",
            a: "Nobody. The developer runs Zirve Toptan both to provide a free tool to small businesses and as a long-form product/cloud-ops learning project. AWS infrastructure costs are covered by the developer; no fee is ever requested from end users.",
          },
        ],
      },
      {
        title: "Account, sign-up and sign-in",
        items: [
          {
            q: "How do I create an account?",
            a: "From the mobile app's sign-in screen, tap 'Don't have an account? · Open a business account'. On the sign-up screen, enter business name, full name, email, optional phone and a password. Tapping 'Create account' submits the application to the server. An administrator reviews and approves it — usually within the same business day.",
          },
          {
            q: "Is there a pre-approved test/demo account?",
            a: "Yes. A pre-approved demo account is maintained specifically so App Store / Google Play review teams can fully test the app end-to-end. Demo credentials are provided in the 'App Review Notes' of App Store Connect, and on request via destek@toptanpanel.com. We do not publish the demo credentials publicly on this site because the account contains a real business's data.",
          },
          {
            q: "Why are new sign-ups gated by admin approval?",
            a: "Approval prevents abuse (fake businesses, automation, spam) and keeps real businesses working on top of a clean dataset. It mirrors the 'business onboarding' step used by most banking, fintech and B2B SaaS products. Approval normally completes within the same business day.",
          },
          {
            q: "I forgot my password — what do I do?",
            a: "Email destek@toptanpanel.com from the address you signed up with and request a password reset. An in-app 'Forgot password' flow is also planned for an upcoming release.",
          },
          {
            q: "How do I sign in to the web admin?",
            a: "Use the 'Sign in' link at the top right of this site, or go directly to toptanperakende.online/#/y/giris. The same email and password you use in the mobile app work in the web admin.",
          },
          {
            q: "Can I use the same account from multiple devices at the same time?",
            a: "Yes. A single business account can be signed in to multiple mobile devices and web browsers simultaneously. Changes on any device propagate live to the others over a WebSocket connection.",
          },
        ],
      },
      {
        title: "Data, privacy and deletion",
        items: [
          {
            q: "What personal data is collected?",
            a: "Only what is strictly required for the app to work: business name, full name, email, optional phone, a hashed password, session logs (device type and last sign-in), the business records you create inside the app (products, customers, invoices, debts) and the product images you upload. No location, contacts, microphone, health or other sensitive permissions are requested.",
          },
          {
            q: "Is my data shared with third parties?",
            a: "No. Your data is never sold or shared for advertising, marketing or analytics. The only data sharing is with the infrastructure providers strictly required to run the service (AWS — servers, database, file storage) and with legal authorities when required by law.",
          },
          {
            q: "Where and how is my data stored?",
            a: "Data is stored on AWS in the European region (eu-central-1, Germany). Passwords are hashed irreversibly using Argon2id. Product images are stored in a private S3 bucket and only ever exposed via short-lived presigned URLs. The database runs in a private, isolated subnet with no public access.",
          },
          {
            q: "Can my business see other businesses' data? How does tenant isolation work?",
            a: "No. Every business has its own tenant ID, and every server-side query is filtered by it. A user from one business cannot access another business's products, customers, invoices or debt records. This isolation is also covered by backend tests.",
          },
          {
            q: "Can I delete my account and data?",
            a: "Yes — three ways: (1) start the account-deletion flow from inside the mobile app, (2) open a deletion request from the 'My Account' area of the web admin, or (3) email destek@toptanpanel.com. Active data is removed within 14 days, backups within 30 days. Details: /legal/delete-account.html",
          },
          {
            q: "Is the app aimed at children?",
            a: "No. Zirve Toptan is aimed at business owners 18+; it contains no content or marketing aimed at children or students and collects no data from children.",
          },
          {
            q: "Does the app request location, contacts, microphone or other sensitive permissions?",
            a: "No. The app only requests photo/gallery access — and only when the user explicitly triggers it, for example when uploading a product image. No location, contacts, microphone, always-on camera, health data or App Tracking Transparency consent is requested.",
          },
        ],
      },
      {
        title: "Features, usage and tech",
        items: [
          {
            q: "Does the app need an internet connection?",
            a: "Yes. Because Zirve Toptan provides live sync, multi-device usage and secure session management, an active internet connection is required. On temporary network drops the app will retry and resync from the server.",
          },
          {
            q: "Which devices does it run on?",
            a: "Mobile: iPhone and iPad (iOS 15+ recommended), Android phones and tablets (Android 7+). Web admin: current Chrome, Safari, Firefox and Edge. The same business account can be used in parallel from all of these.",
          },
          {
            q: "How does the credit-sales debt tracker work?",
            a: "When an invoice is marked as 'credit', a debt record is created with a default 15-day term. The system recomputes every debt daily at 01:00 Turkey time and colors it by remaining days: ≥ 8 green (safe), 4–7 yellow (approaching), 0–3 red (urgent), past due dark red + days overdue. When the customer pays, the payment is subtracted from the debt and the remaining balance is updated.",
          },
          {
            q: "Is there a PDF / printed invoice?",
            a: "Invoices are shown inside the app — each invoice lists its line items, total and customer. PDF export is on the roadmap. If you need it sooner, please request it via support.",
          },
          {
            q: "What technologies power the backend and infrastructure?",
            a: "Backend: Python 3.11 + FastAPI + SQLAlchemy 2.0 + Alembic migrations. Database: PostgreSQL 16 (AWS RDS, private subnet). Storage: AWS S3 (private bucket + presigned URLs). Auth: JWT access + refresh rotation, Argon2id password hashing. Live sync: WebSocket. Cron: AWS EventBridge → daily debt-status recompute. Container: AWS ECS Fargate + ALB. CDN: AWS CloudFront. All credentials live in AWS Secrets Manager.",
          },
          {
            q: "What about the mobile and web clients?",
            a: "Mobile: Flutter (Dart), Riverpod for state, Dio for HTTP, go_router for routing. Web admin: Flutter Web on top of the same state layer. Marketing site (this site): Next.js 15 + Tailwind CSS + shadcn/ui.",
          },
          {
            q: "Does the app send push notifications?",
            a: "Not at this time. The app registers with no push notification service and sends no advertising/marketing notifications. In the future, only critical operational notifications (e.g. 'debt due soon') may be added, strictly opt-in.",
          },
          {
            q: "Is it open source?",
            a: "The repository is published publicly and can be inspected as a portfolio piece. For commercial use, redistribution under the Zirve Toptan name or brand usage, please get in touch.",
          },
        ],
      },
      {
        title: "Support and updates",
        items: [
          {
            q: "How do I get support?",
            a: "Email destek@toptanpanel.com. Support requests are usually answered within 3 business days; account security and data-deletion requests are prioritized.",
          },
          {
            q: "How do I report a bug?",
            a: "Email destek@toptanpanel.com with subject 'Bug report' and a short description of what you did, what you expected and what happened. A screenshot or short screen recording helps a lot with diagnosis.",
          },
          {
            q: "How are updates released?",
            a: "Mobile releases ship through the App Store and Google Play under the normal store update flow. Backend updates are deployed continuously and do not interrupt existing sessions. Backwards compatibility is maintained; any breaking change is announced on this site and via support email.",
          },
        ],
      },
    ],
  },
  contact: {
    title: "Contact",
    lead:
      "Reach out for help with account, usage, bugs, data export or deletion requests.",
    emailLabel: "General support",
    email: "destek@toptanpanel.com",
    privacyLabel: "Privacy requests",
    legal: {
      privacy: "Privacy Policy",
      support: "Support page",
      delete: "Account & Data Deletion",
    },
    responseTime:
      "Support requests are usually answered within 3 business days; account security and data-deletion requests are prioritized.",
  },
  footer: {
    builtBy: "Built by Yağız Karabulut.",
    rights: "All rights reserved.",
    legal: "Legal",
    product: "Product",
    company: "Company",
    privacy: "Privacy Policy",
    support: "Support Center",
    delete: "Account & Data Deletion",
    terms: "Terms of Use",
    kvkk: "KVKK Notice (Turkey)",
    cookies: "Cookie Policy",
  },
  support: {
    title: "Support Center",
    lead:
      "We help with every Zirve Toptan account, usage, bug, privacy or data-deletion request. Below you'll find self-service answers for the most common issues, the direct contact channels and a bug-report template.",
    contact: {
      title: "Direct contact",
      emailLabel: "Support email",
      email: "destek@toptanpanel.com",
      altEmailLabel: "Privacy & account deletion",
      altEmail: "destek@toptanpanel.com",
      hoursLabel: "Working hours",
      hours: "Monday – Friday · 09:00 – 18:00 (Türkiye time, UTC+3)",
      slaLabel: "Response time",
      sla: "General requests: within 3 business days at the latest. Account security, password reset and data deletion: same business day.",
      languagesLabel: "Languages",
      languages: "Turkish (primary), English",
    },
    issues: {
      title: "Common issues",
      subtitle: "Try the steps below first; if your issue persists, open a support request with the same subject.",
      items: [
        {
          q: "I can't sign in",
          steps: [
            "Make sure your email is lowercase and has no extra whitespace.",
            "If you recently changed your password, every existing session has been signed out — sign in with the new password.",
            "Check your internet connection — the app requires a stable connection.",
            "If your account is not active yet, you'll see a 'pending approval' message — new business accounts are reviewed by an admin (usually within the same business day).",
            "Still stuck? Email destek@toptanpanel.com with subject 'Sign-in issue'.",
          ],
        },
        {
          q: "My new account isn't approved yet",
          steps: [
            "To prevent abuse, new business accounts are reviewed by an admin before becoming active.",
            "Approval usually completes within the same business day; sign-ups outside business hours / weekends may take until the next business day.",
            "Watch the inbox of the email address you used to sign up — confirmation arrives there.",
            "If it has been more than 24 hours, email destek@toptanpanel.com with subject 'Waiting for approval'.",
          ],
        },
        {
          q: "I forgot my password",
          steps: [
            "Email destek@toptanpanel.com from the account's registered address with subject 'Password reset'.",
            "Include your business name and account email to speed things up.",
            "The reset email is usually sent the same business day, latest by the next business day.",
            "An in-app 'Forgot password' flow is on the roadmap.",
          ],
        },
        {
          q: "I want to delete my account and data",
          steps: [
            "Mobile app: open profile/settings and start the 'Delete my account' flow.",
            "Web admin panel: open the 'My account' area and start a deletion request.",
            "Or email destek@toptanpanel.com with subject 'Zirve Toptan Account Deletion' and include your account email and business name.",
            "Active data is removed within 14 days, backups within 30 days. Details: /legal/delete-account.html",
          ],
        },
        {
          q: "Debt amount or due date looks wrong",
          steps: [
            "Open the invoice and check each line item — wrong quantity or unit price is the most common cause.",
            "Due-date recomputation runs once a day at 01:00 Türkiye time for every open debt; short intraday delays are normal.",
            "If payment was received but debt didn't drop, check the payment record under 'Customer > Payments'.",
            "If the discrepancy persists, email support with the invoice number and a screenshot.",
          ],
        },
        {
          q: "Product image isn't uploading",
          steps: [
            "Make sure the image is under 5 MB and is JPG or PNG.",
            "The app requests photo/gallery permission — enable it for Zirve Toptan in your system settings.",
            "Uploads may take longer on slow networks; don't close the screen mid-upload.",
            "If it still won't upload, email support with the file attached — we'll add it manually.",
          ],
        },
        {
          q: "Stock count looks inconsistent",
          steps: [
            "Stock decreases automatically with each invoice/order; another device may have made a sale.",
            "Open the product's 'sales history' and look for recent movements.",
            "If you entered a wrong invoice, cancelling it will add the stock back.",
            "For manual fixes, you can update the stock count from the product edit screen.",
          ],
        },
        {
          q: "I can't sign in to the web admin",
          steps: [
            "Open https://toptanperakende.online/#/y/giris in a current browser (Chrome, Safari, Firefox, Edge).",
            "Clear your browser cache or try a private window.",
            "Use the same email and password as the mobile app.",
            "If the page doesn't load at all, check your internet connection and the spelling in the address bar.",
          ],
        },
        {
          q: "Two devices show different data",
          steps: [
            "Zirve Toptan syncs live over WebSocket; brief delays during connection drops are normal.",
            "Toggle device airplane mode off, then reopen the app.",
            "Use pull-to-refresh to fetch the latest state.",
            "If it persists, sign out from one device and sign back in.",
          ],
        },
        {
          q: "I want to report a bug",
          steps: [
            "Email destek@toptanpanel.com with subject 'Bug report'.",
            "Include: device (e.g. iPhone 14, iOS 17.5), app version, the screen, what you did, what you expected, what actually happened.",
            "If possible attach a screenshot or a short screen recording — it dramatically speeds up diagnosis.",
            "Confirmed bugs are fixed in the next app update; we'll share the roadmap in our reply.",
          ],
        },
      ],
    },
    operational: {
      title: "Operational information",
      items: [
        { label: "Developer / responsible party", value: "Yağız Karabulut (individual developer)" },
        { label: "Country", value: "Türkiye" },
        { label: "Contact email", value: "destek@toptanpanel.com" },
        { label: "Website", value: "toptanperakende.online" },
        { label: "App Store version", value: "1.0 (latest version on the App Store listing)" },
        { label: "Google Play version", value: "1.0 (latest version on the Play Store listing)" },
        { label: "Escalation", value: "If no resolution within 5 business days of first reply, reply with 'escalation' in the same email thread." },
      ],
    },
    bugTemplate: {
      title: "Bug report template",
      subtitle: "Copy the template below and paste it into your support email.",
      template:
        "Subject: Bug report — [short title]\n\nDevice: \nOS & version: \nApp version: \nScreen / flow: \nSteps I took:\n  1. \n  2. \n  3. \nExpected result: \nActual result: \nScreenshot / video: (yes/no)\nAdditional notes: ",
    },
    reviewerNote: {
      title: "Note for App Store / Google Play review teams",
      body:
        "Pre-approved demo account credentials are shared in App Store Connect → App Review → Notes. You can also request them via destek@toptanpanel.com with subject 'Reviewer demo credentials' — we'll reply the same business day.",
    },
    quickLinks: {
      title: "Related pages",
      items: [
        { href: "/legal/privacy.html", label: "Privacy Policy" },
        { href: "/legal/terms.html", label: "Terms of Use" },
        { href: "/legal/kvkk.html", label: "KVKK Notice (Türkiye)" },
        { href: "/legal/cookies.html", label: "Cookie Policy" },
        { href: "/legal/delete-account.html", label: "Account & Data Deletion" },
        { href: "/en/faq", label: "FAQ" },
      ],
    },
  },
  storeBadges: {
    appStore: "Download on the App Store",
    playStore: "Get it on Google Play",
    soon: "Coming soon",
  },
};
