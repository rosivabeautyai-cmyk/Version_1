// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcome => 'مرحباً بك في ROSIVA';

  @override
  String get chooseLanguage => 'اختر لغتك المفضلة';

  @override
  String get continueButton => 'استمرار';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدئي الآن';

  @override
  String get onboardingTitle1 => 'اكتشفي عالم الجمال بالذكاء الاصطناعي';

  @override
  String get onboardingDescription1 => 'مساعدكِ الذكي يساعدكِ على العثور على أفضل منتجات العناية بالبشرة والمكياج المناسبة لكِ.';

  @override
  String get onboardingTitle2 => 'نصائح مخصصة لكِ';

  @override
  String get onboardingDescription2 => 'تحدثي مع ROSIVA في أي وقت للحصول على نصائح وروتين عناية يناسب احتياجاتكِ.';

  @override
  String get onboardingTitle3 => 'تسوقي بثقة';

  @override
  String get onboardingDescription3 => 'اكتشفي منتجات موثوقة وتسوقي بسهولة وأمان.';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get loginSubtitle => 'سجلي الدخول لمتابعة رحلتك مع ROSIVA';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخلي كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيتِ كلمة المرور؟';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get orContinueWith => 'أو تابعي باستخدام';

  @override
  String get dontHaveAccount => 'ليس لديكِ حساب؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get registerSubtitle => 'انضمي إلى ROSIVA وابدئي روتين جمالك';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameHint => 'الاسم بالكامل';

  @override
  String get createStrongPassword => 'أنشئي كلمة مرور قوية';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordHint => 'أعيدي إدخال كلمة المرور';

  @override
  String get createAccountButton => 'إنشاء الحساب';

  @override
  String get alreadyHaveAccount => 'لديكِ حساب بالفعل؟';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get agreeTermsMessage => 'يرجى الموافقة على شروط الاستخدام وسياسة الخصوصية.';

  @override
  String get registrationFailed => 'فشل إنشاء الحساب، يرجى المحاولة مرة أخرى.';

  @override
  String get loginFailed => 'فشل تسجيل الدخول، يرجى المحاولة مرة أخرى.';

  @override
  String get termsOfService => 'شروط الاستخدام';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get forgotPasswordTitle => 'نسيتِ كلمة المرور؟';

  @override
  String get forgotPasswordSubtitle => 'لا داعي للقلق، سنرسل لكِ تعليمات إعادة التعيين.';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get checkYourInbox => 'تحققي من بريدك';

  @override
  String resetLinkSentMessage(String email) {
    return 'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى $email. اتبعي التعليمات لإنشاء كلمة مرور جديدة.';
  }

  @override
  String get forgotPasswordFailed => 'فشل إرسال رسالة إعادة التعيين.';

  @override
  String get continueWithGoogle => 'تابعي باستخدام Google';

  @override
  String get continueWithApple => 'تابعي باستخدام Apple';

  @override
  String get agreeToThe => 'أوافق على ';

  @override
  String get termsAnd => ' و';

  @override
  String get signedInAndVerified => 'تم تسجيل دخولكِ والتحقق من حسابكِ.';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get appName => 'ROSIVA';

  @override
  String get verifyYourEmail => 'تحققي من بريدكِ الإلكتروني';

  @override
  String verifyEmailMessage(String email) {
    return 'لقد أرسلنا رابط تحقق إلى\n$email.\nاضغطي على الرابط الموجود في الرسالة لتفعيل حسابكِ.';
  }

  @override
  String get openMailApp => 'فتح تطبيق البريد';

  @override
  String get iveVerified => 'لقد قمت بالتحقق';

  @override
  String get sending => 'جارٍ الإرسال...';

  @override
  String resendInSeconds(int seconds) {
    return 'إعادة الإرسال خلال $seconds ثانية';
  }

  @override
  String get resendEmailPrompt => 'لم تستلمي البريد؟ إعادة الإرسال';

  @override
  String get openMailManually => 'يرجى فتح تطبيق البريد يدويًا.';

  @override
  String get emailNotVerifiedYet => 'لم يتم التحقق من بريدكِ الإلكتروني بعد. يرجى الضغط على الرابط الذي أرسلناه لكِ.';

  @override
  String get resendEmailFailed => 'فشل في إعادة إرسال البريد.';

  @override
  String get verificationEmailSent => 'تم إرسال رسالة التحقق!';

  @override
  String get yourEmailFallback => 'بريدكِ الإلكتروني';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get emailInvalid => 'أدخلي بريدًا إلكترونيًا صحيحًا';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordMinLength => 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get passwordUppercase => 'أضيفي حرفًا كبيرًا واحدًا على الأقل';

  @override
  String get passwordLowercase => 'أضيفي حرفًا صغيرًا واحدًا على الأقل';

  @override
  String get passwordNumber => 'أضيفي رقمًا واحدًا على الأقل';

  @override
  String get passwordSpecialChar => 'أضيفي رمزًا خاصًا واحدًا على الأقل';

  @override
  String get loginPasswordMinLength => 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get confirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get fullNameInvalid => 'أدخلي اسمًا كاملاً صحيحًا';

  @override
  String get fullNameLettersOnly => 'يجب أن يحتوي الاسم على حروف فقط';
}
