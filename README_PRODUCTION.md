# GameTopup — دليل الإعداد والنشر

## 📦 المتطلبات

| الأداة | الإصدار |
|--------|---------|
| Flutter | 3.16+ |
| Dart | 3.0+ |
| Node.js | 18+ (للـ seed script) |
| حساب Firebase | مجاني يكفي للبدء |

---

## 🔥 الخطوة 1 — إنشاء مشروع Firebase

1. اذهب إلى [console.firebase.google.com](https://console.firebase.google.com)
2. **Create a project** → أدخل اسم المشروع (مثال: `game-topup`)
3. فعّل **Google Analytics** (اختياري)

### تفعيل الخدمات:
- **Authentication** → Sign-in method → فعّل **Email/Password**
- **Firestore Database** → Create database → ابدأ بـ **production mode**
- **Storage** → Get started → production mode
- **Cloud Messaging** → لا يحتاج إعداد يدوي

---

## 📱 الخطوة 2 — ربط التطبيق بـ Firebase

```bash
# ثبّت FlutterFire CLI
dart pub global activate flutterfire_cli

# من داخل مجلد المشروع
cd game_topup
flutterfire configure
```

هذا الأمر سيفعل:
- ✅ إنشاء `lib/firebase_options.dart` بالقيم الحقيقية
- ✅ إنشاء `android/app/google-services.json`
- ✅ إنشاء `ios/Runner/GoogleService-Info.plist`

---

## 🌱 الخطوة 3 — تعبئة قاعدة البيانات

```bash
# من مجلد المشروع (بجانب firestore_seed.js)
npm install firebase-admin

# حمّل Service Account Key من Firebase Console:
# Project Settings → Service Accounts → Generate new private key
# احفظه بالاسم: serviceAccountKey.json

# شغّل السكريبت
node firestore_seed.js
```

يضيف السكريبت:
- 4 ألعاب (PUBG, Free Fire, eFootball, EA FC Mobile) مع باقاتها
- 3 بنرات للصفحة الرئيسية
- إعدادات الدفع الافتراضية

---

## 🔐 الخطوة 4 — نشر Security Rules

### Firestore Rules:
1. Firebase Console → Firestore Database → **Rules**
2. انسخ محتوى ملف `firestore.rules` والصق

### Storage Rules:
1. Firebase Console → Storage → **Rules**
2. انسخ محتوى ملف `storage.rules` والصق

---

## 👑 الخطوة 5 — إنشاء حساب الأدمن

1. سجّل في التطبيق بحساب جديد
2. اذهب إلى Firebase Console → Firestore
3. في collection `users` ابحث عن حسابك
4. عدّل حقل `role` من `"user"` إلى `"admin"`

**مثال:**
```json
{
  "uid": "ABC123",
  "email": "admin@example.com",
  "role": "admin",   ← غيّر هذا
  "name": "المدير"
}
```

---

## 💳 الخطوة 6 — إعداد حسابات الدفع

من داخل التطبيق (بعد تسجيل الدخول كأدمن):
- لوحة الإدارة → تبويب **الدفع**
- أدخل أرقام حسابات Bankily / Masrivi / Sedad

---

## 🔔 الخطوة 7 — إعداد إشعارات FCM

لإرسال إشعارات من السيرفر للمستخدمين، يجب استخدام **Cloud Functions** أو **backend** خاص بك.

### مثال Cloud Function (Node.js):

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { tokens, title, body, data: msgData } = data;
  
  const message = {
    notification: { title, body },
    data: msgData || {},
    tokens: tokens,
  };
  
  const response = await admin.messaging().sendMulticast(message);
  return { success: response.successCount };
});
```

### نشر Cloud Function:
```bash
npm install -g firebase-tools
firebase login
firebase deploy --only functions
```

ثم في `notification_service.dart`، فعّل استدعاء الـ Function بدلاً من التعليق الموجود.

---

## 🏗️ الخطوة 8 — البناء والنشر

### Android APK (debug):
```bash
flutter build apk --debug
# الملف: build/app/outputs/flutter-apk/app-debug.apk
```

### Android APK (release):
```bash
# أولاً أنشئ keystore (مرة واحدة):
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# أنشئ android/key.properties:
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=key
storeFile=/Users/YOU/key.jks

# أضف في android/app/build.gradle قبل android {}:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}

# ابنِ APK:
flutter build apk --release

# ابنِ AAB (للـ Play Store):
flutter build appbundle --release
```

### iOS IPA:
```bash
# يتطلب Mac + Xcode + Apple Developer Account
flutter build ipa --release
```

---

## 🗂️ هيكل المشروع

```
lib/
├── core/
│   ├── constants/    # AppColors, AppTheme
│   ├── router/       # GoRouter configuration
│   ├── theme/        # Dark theme
│   ├── utils/        # Validators
│   └── widgets/      # LoadingWidget, ErrorWidget, EmptyState
├── data/
│   └── services/
│       ├── firebase_service.dart     # كل تعاملات Firebase
│       └── notification_service.dart # FCM + Local notifications
├── domain/
│   ├── entities/
│   │   ├── game.dart    # GameModel, PackageModel, BannerModel
│   │   └── order.dart   # OrderModel, OrderStatus
│   └── providers/
│       ├── auth_provider.dart
│       ├── games_provider.dart      # StreamProvider للألعاب والبنرات
│       └── orders_provider.dart     # OrderFormNotifier
└── presentation/
    ├── screens/
    │   ├── admin/         # Dashboard + ManageGames + ManageBanners + PaymentSettings
    │   ├── auth/          # Login + Register
    │   ├── confirmation/
    │   ├── home/          # Carousel + Games grid
    │   ├── orders/        # My orders
    │   ├── payment/       # Payment methods + proof upload
    │   ├── splash/
    │   ├── support/
    │   └── topup/         # Package selection
    └── widgets/
        ├── game_card.dart
        └── order_status_badge.dart
```

---

## 🔄 دورة الطلب الكاملة

```
المستخدم اختار لعبة
    ↓
اختار باقة + أدخل Player ID + واتساب
    ↓
اختار طريقة الدفع + رفع صورة إثبات
    ↓
تأكيد الطلب → حفظ في Firestore + رفع الصورة إلى Storage
    ↓
إشعار FCM → الأدمن
    ↓
الأدمن راجع الطلب + صورة الإثبات
    ↓
الأدمن غيّر الحالة (processing / completed / rejected)
    ↓
إشعار FCM → المستخدم
    ↓
المستخدم يرى التحديث مباشرة (Realtime Stream)
```

---

## ✅ قائمة ميزات المشروع

### Authentication
- [x] تسجيل دخول بالبريد وكلمة المرور
- [x] إنشاء حساب مع حفظ FCM Token
- [x] تسجيل خروج مع حذف FCM Token
- [x] نظام أدوار (user / admin)

### الصفحة الرئيسية
- [x] بنرات ترويجية من Firestore (Carousel)
- [x] قائمة ألعاب من Firestore
- [x] بحث فوري في الألعاب
- [x] شاشة تحميل عند جلب البيانات

### نظام الطلبات
- [x] اختيار لعبة وباقة من Firestore
- [x] إدخال Player ID + رقم واتساب مع validation
- [x] اختيار طريقة الدفع (Bankily / Masrivi / Sedad)
- [x] عرض معلومات الدفع من Firestore (settings)
- [x] رفع صورة إثبات الدفع إلى Firebase Storage
- [x] حفظ الطلب في Firestore
- [x] تتبع حالة الطلب في الوقت الفعلي

### الإشعارات
- [x] حفظ FCM Token عند تسجيل الدخول
- [x] إشعار للأدمن عند طلب جديد
- [x] إشعار للمستخدم عند تغيير حالة الطلب
- [x] دعم إشعارات الخلفية (Background)
- [x] قناة إشعارات Android مخصصة

### لوحة الإدارة
- [x] عرض جميع الطلبات
- [x] بحث وفلترة الطلبات
- [x] عرض صورة إثبات الدفع
- [x] تغيير حالة الطلب مع ملاحظة للعميل
- [x] إشعار تلقائي للمستخدم عند التحديث
- [x] إدارة الألعاب (إضافة/تعديل/حذف)
- [x] إدارة الباقات لكل لعبة
- [x] إدارة البنرات الترويجية
- [x] إعداد حسابات الدفع

### Security
- [x] Firestore Security Rules احترافية
- [x] Storage Security Rules مع حماية صور الإثبات
- [x] منع وصول غير المصرح

---

## ❓ مشاكل شائعة

### `firebase_options.dart` فارغ
← نفّذ `flutterfire configure` داخل مجلد المشروع

### `google-services.json` غير موجود
← FlutterFire CLI ينشئه تلقائياً عند تشغيل `flutterfire configure`

### الإشعارات لا تصل
← تأكد من إعداد Cloud Functions أو Backend لإرسال FCM
← تأكد من تفعيل Cloud Messaging في Firebase Console

### خطأ في Storage Rules عند رفع الصورة
← تأكد من نشر `storage.rules` في Firebase Console

### لا يظهر زر الأدمن
← تأكد من أن حقل `role` في Firestore يساوي `"admin"` بالضبط
