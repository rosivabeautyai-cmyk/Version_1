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

  @override
  String get home => 'الرئيسية';

  @override
  String get explore => 'استكشاف';

  @override
  String get favorites => 'المفضلة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get homeStartHere => 'ابدأي من هنا';

  @override
  String get homeDiscoverMoreTitle => 'اكتشفي المزيد';

  @override
  String get homeDiscoverMoreDesc => 'استكشفي مميزات ROSIVA واكتشفي كل ما يمكن أن تقدمه لكِ.';

  @override
  String get homeFavoritesDesc => 'احتفظي بالأشياء التي تهمكِ للوصول إليها بسهولة.';

  @override
  String get homeMyAccountTitle => 'حسابي';

  @override
  String get homeMyAccountDesc => 'يمكنكِ إدارة بيانات حسابكِ وتفضيلاتكِ من هنا.';

  @override
  String welcomeGreeting(String name) {
    return 'أهلًا، $name';
  }

  @override
  String get rosivaUserFallback => 'مستخدمة ROSIVA';

  @override
  String get yourProfile => 'ملفكِ الشخصي';

  @override
  String get profileManageSubtitle => 'إدارة حسابك وتفضيلاتك.';

  @override
  String get favoritesSubtitle => 'ستظهر عناصرك المفضلة هنا.';

  @override
  String get noFavoritesYetTitle => 'لا توجد مفضلات بعد';

  @override
  String get noFavoritesYetDesc => 'ابدئي بإضافة العناصر المفضلة لديكِ وستظهر هنا.';

  @override
  String get exploreSubtitle => 'اكتشفي كل ما تقدمه ROSIVA.';

  @override
  String get exploreComingSoonTitle => 'قسم الاستكشاف قريبًا';

  @override
  String get exploreComingSoonDesc => 'سيتم إضافة قسم الاستكشاف هنا قريبًا.';

  @override
  String get adminDashboardTitle => 'لوحة تحكم الأدمن';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get verifiedEmails => 'إيميلات موثّقة';

  @override
  String get legalLastUpdatedPlaceholder => 'آخر تحديث: أضيفي التاريخ هنا';

  @override
  String get tosSection1Title => '١. الموافقة على الشروط';

  @override
  String get tosSection1Body => 'باستخدامك لتطبيق ROSIVA فإنك توافقين على هذه الشروط. إذا كنتِ لا توافقين عليها، يرجى عدم استخدام التطبيق.';

  @override
  String get tosSection2Title => '٢. استخدام التطبيق';

  @override
  String get tosSection2Body => 'يجب استخدام التطبيق للأغراض الشخصية المشروعة فقط، وعدم محاولة إساءة استخدامه أو الوصول غير المصرح به إلى حسابات أخرى.';

  @override
  String get tosSection3Title => '٣. الحساب والمسؤولية';

  @override
  String get tosSection3Body => 'أنتِ مسؤولة عن الحفاظ على سرية بيانات حسابك، وعن أي نشاط يتم من خلاله.';

  @override
  String get tosSection4Title => '٤. التعديلات على الخدمة';

  @override
  String get tosSection4Body => 'نحتفظ بحق تعديل أو إيقاف أي جزء من التطبيق في أي وقت دون إشعار مسبق.';

  @override
  String get tosSection5Title => '٥. إنهاء الحساب';

  @override
  String get tosSection5Body => 'يحق لنا تعليق أو إنهاء أي حساب يخالف هذه الشروط أو يُستخدم بشكل غير قانوني.';

  @override
  String get tosSection6Title => '٦. التواصل معنا';

  @override
  String get tosSection6Body => 'لأي استفسار حول شروط الاستخدام، راسلينا على: أضيفي بريدك هنا.';

  @override
  String get privacySection1Title => '١. البيانات التي نجمعها';

  @override
  String get privacySection1Body => 'نجمع بيانات مثل الاسم، البريد الإلكتروني، وأي معلومات تقومين بإدخالها داخل التطبيق (مثل نوع البشرة أو المفضلة). عدّلي هذا النص ليعكس البيانات الفعلية التي يجمعها تطبيقك.';

  @override
  String get privacySection2Title => '٢. كيف نستخدم بياناتك';

  @override
  String get privacySection2Body => 'نستخدم بياناتك لتقديم خدمات التطبيق، تحسين تجربة الاستخدام، والتواصل معك عند الحاجة. لا نبيع بياناتك لأي طرف ثالث.';

  @override
  String get privacySection3Title => '٣. مشاركة البيانات';

  @override
  String get privacySection3Body => 'قد تتم مشاركة بعض البيانات مع مزودي خدمات موثوقين (مثل Firebase من جوجل) لتشغيل التطبيق فقط، وليس لأي غرض تسويقي.';

  @override
  String get privacySection4Title => '٤. أمان البيانات';

  @override
  String get privacySection4Body => 'نتخذ إجراءات معقولة لحماية بياناتك، لكن لا يمكن ضمان الأمان الكامل لأي نظام إلكتروني بنسبة ١٠٠٪.';

  @override
  String get privacySection5Title => '٥. حقوقك';

  @override
  String get privacySection5Body => 'يمكنك طلب تعديل أو حذف بياناتك في أي وقت عن طريق التواصل معنا من داخل التطبيق أو عبر البريد الإلكتروني.';

  @override
  String get privacySection6Title => '٦. التواصل معنا';

  @override
  String get privacySection6Body => 'لأي استفسار حول سياسة الخصوصية، راسلينا على: أضيفي بريدك هنا.';

  @override
  String get search => 'بحث';

  @override
  String get searchHint => 'ابحثي عن منتج أو ماركة...';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get save => 'حفظ';

  @override
  String get apply => 'تطبيق';

  @override
  String get done => 'تم';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get aiAssistant => 'المساعد الذكي';

  @override
  String get categories => 'الفئات';

  @override
  String get helloBeautiful => 'أهلاً أيتها الجميلة';

  @override
  String get elevateYourRitual => 'ارتقِ بروتينك اليومي.';

  @override
  String get askRosivaAnything => 'اسألي ROSIVA أي شيء...';

  @override
  String get curatedEssentials => 'أساسيات مختارة';

  @override
  String get trendingNow => 'الأكثر رواجًا';

  @override
  String get skincare => 'العناية بالبشرة';

  @override
  String get makeup => 'مكياج';

  @override
  String get perfume => 'عطور';

  @override
  String get affiliateDisclosureShort => 'روزيفيا منصة تسويق بالعمولة. تتم عمليات الشراء عبر مواقع خارجية. قد نحصل على عمولة عن عمليات الشراء المؤهلة عبر روابطنا.';

  @override
  String get loadingProducts => 'جارِ تحميل المنتجات...';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get somethingWentWrongDesc => 'تعذر تحميل هذا المحتوى. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';

  @override
  String get noResultsFound => 'لا توجد نتائج';

  @override
  String get noResultsFoundDesc => 'جربي كلمة بحث مختلفة أو تصفحي الفئات بدلاً من ذلك.';

  @override
  String get noProductsYet => 'لا توجد منتجات بعد';

  @override
  String get noProductsYetDesc => 'ستظهر المنتجات هنا بمجرد إضافتها.';

  @override
  String get startSearching => 'ابدئي البحث';

  @override
  String get startSearchingDesc => 'ابحثي عن منتجات العناية بالبشرة والمكياج والعطور.';

  @override
  String get browseCategories => 'تصفح الفئات';

  @override
  String get allProducts => 'كل المنتجات';

  @override
  String get filter => 'تصفية';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get reviews => 'التقييمات';

  @override
  String get editorsChoice => 'اختيار المحررين';

  @override
  String get whyRosivaRecommends => 'لماذا توصي روزيفيا بهذا';

  @override
  String get ingredients => 'المكونات';

  @override
  String get benefits => 'الفوائد';

  @override
  String get howToUse => 'طريقة الاستخدام';

  @override
  String get openStore => 'فتح المتجر';

  @override
  String get priceAvailabilityDisclaimer => 'قد تختلف الأسعار والتوفر على المواقع الخارجية. بصفتها منصة تسويق بالعمولة، قد تحصل روزيفيا على عمولة صغيرة عن عمليات الشراء المؤهلة.';

  @override
  String get patchTestDisclaimer => 'يحتوي هذا المنتج على مكونات فعالة. نوصي بإجراء اختبار حساسية قبل الاستخدام الكامل. استشيري طبيب الجلدية إذا كانت لديكِ مشكلات جلدية محددة.';

  @override
  String get addToFavorites => 'إضافة للمفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get addedToFavorites => 'أُضيف إلى المفضلة';

  @override
  String get removedFromFavorites => 'أُزيل من المفضلة';

  @override
  String get rosivaAiTitle => 'مساعد الجمال الذكي روزيفيا';

  @override
  String get aiWelcomeMessage => 'مرحبًا! أنا مساعد الجمال الذكي من روزيفيا. كيف يمكنني مساعدتكِ لتحقيق أهداف بشرتكِ اليوم؟';

  @override
  String get aiInputHint => 'اسألي روزيفيا أي شيء...';

  @override
  String get aiNotConfigured => 'لم يتم توصيل المساعد الذكي بعد. يرجى المحاولة لاحقًا.';

  @override
  String get aiAccuracyTitle => 'دقة الذكاء الاصطناعي';

  @override
  String get aiAccuracyDesc => 'يتم إنشاء توصياتنا من خلال نمذجة بيانات معقدة استنادًا إلى التفضيلات التي تشاركينها. نسعى للدقة المطلقة في مطابقة الألوان واقتراح الروتين، لكن النتائج الفردية قد تختلف بسبب العوامل البيئية وخصوصية بشرة كل شخص.';

  @override
  String get medicalAdviceDisclaimerTitle => 'إخلاء مسؤولية طبي';

  @override
  String get medicalAdviceDisclaimerDesc => 'لا تقدم روزيفيا تشخيصًا طبيًا أو استشارة جلدية. الاقتراحات المقدمة هي لأغراض تجميلية فقط. إذا كانت لديكِ حالات جلدية نشطة أو حساسية أو تخضعين لعلاج طبي، ننصح بشدة باستشارة أخصائي رعاية صحية مؤهل قبل إدخال مكونات فعالة جديدة إلى روتينكِ.';

  @override
  String get requiredLegalDisclosure => 'إفصاح قانوني مطلوب';

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingsSubtitle => 'خصصي تجربتكِ وطريقة عملنا.';

  @override
  String get localization => 'الإعدادات المحلية';

  @override
  String get country => 'الدولة';

  @override
  String get language => 'اللغة';

  @override
  String get currency => 'العملة';

  @override
  String get autoBasedOnLocation => 'تلقائي حسب الموقع';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get aiRecommendations => 'توصيات الذكاء الاصطناعي';

  @override
  String get aiRecommendationsDesc => 'اقتراحات منتجات مخصصة';

  @override
  String get priceDrops => 'انخفاض الأسعار';

  @override
  String get priceDropsDesc => 'احصلي على إشعار بالعناصر المحفوظة';

  @override
  String get newDiscoveries => 'اكتشافات جديدة';

  @override
  String get newDiscoveriesDesc => 'علامات ومنتجات جديدة';

  @override
  String get transparencyAndLegal => 'الشفافية والقوانين';

  @override
  String get affiliateTransparency => 'شفافية العمولة';

  @override
  String get affiliateTransparencyDesc => 'روزيفيا محرك توصيات ذكي وليست بائعًا مباشرًا. عند الضغط على \"تسوقي الآن\"، يتم توجيهكِ إلى بائع خارجي. قد نحصل على عمولة عبر تلك الروابط دون أي تكلفة إضافية عليكِ. هذا يمكّننا من إبقاء مساعد الجمال الذكي المتميز مجانيًا للجميع.';

  @override
  String get medicalDisclaimer => 'إخلاء مسؤولية طبي';

  @override
  String get requiredLegalDisclosureShort => 'إفصاح قانوني مطلوب';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get security => 'الأمان';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get support => 'الدعم';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get contactUs => 'تواصلي معنا';

  @override
  String get legalAndDisclaimers => 'الجوانب القانونية وإخلاء المسؤولية';

  @override
  String get affiliateDisclosure => 'إفصاح العمولة';

  @override
  String get aiAndMedicalDisclaimer => 'إخلاء مسؤولية الذكاء الاصطناعي والطب';

  @override
  String get termsOfServiceShort => 'شروط الخدمة';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get myBeautyProfile => 'ملفي الجمالي';

  @override
  String get myBeautyProfileDesc => 'نوع البشرة، الأهداف';

  @override
  String get favoritesAndCollections => 'المفضلة والمجموعات';

  @override
  String get personalization => 'التخصيص';

  @override
  String memberSince(String year) {
    return 'عضو منذ $year';
  }

  @override
  String get confirmLogout => 'هل أنتِ متأكدة من تسجيل الخروج؟';

  @override
  String get categorySkincare => 'العناية بالبشرة';

  @override
  String get categoryMakeup => 'مكياج';

  @override
  String get categoryPerfume => 'العطور';

  @override
  String get helpCenterSubtitle => 'إجابات عن الأسئلة الشائعة حول حسابك في روزيفيا، والمنتجات، والمساعد الذكي.';

  @override
  String get helpCenterAccountQuestion => 'كيف أدير حسابي؟';

  @override
  String get helpCenterAccountAnswer => 'اذهبي إلى الملف الشخصي ← تعديل الملف الشخصي لتحديث اسمك وتفضيلاتك الجمالية، أو الملف الشخصي ← الأمان لإعادة تعيين كلمة المرور.';

  @override
  String get helpCenterProductsQuestion => 'من أين تأتي تفاصيل المنتجات؟';

  @override
  String get helpCenterProductsAnswer => 'معلومات المنتجات والأسعار والتوفر تُقدَّم من متاجرنا الشريكة وقد تتغير دون إشعار.';

  @override
  String get helpCenterOrdersQuestion => 'هل تقوم روزيفيا بمعالجة طلباتي؟';

  @override
  String get helpCenterOrdersAnswer => 'لا. روزيفيا منصة اكتشاف — الضغط على \"فتح المتجر\" ينقلك إلى موقع البائع لإتمام الشراء هناك.';

  @override
  String get helpCenterFavoritesQuestion => 'كيف تعمل المفضلة؟';

  @override
  String get helpCenterFavoritesAnswer => 'اضغطي على أيقونة القلب في أي منتج لحفظه في تبويب المفضلة. تتم مزامنة مفضلتكِ مع حسابكِ.';

  @override
  String get helpCenterAiQuestion => 'ما مدى دقة المساعد الذكي؟';

  @override
  String get helpCenterAiAnswer => 'يقدم المساعد الذكي إرشادات جمالية عامة بناءً على ما تشاركينه معه. لا يُعد بديلاً عن الاستشارة المتخصصة — راجعي دقة الذكاء الاصطناعي في الإعدادات لمزيد من التفاصيل.';

  @override
  String get helpCenterLanguageQuestion => 'هل يمكنني تغيير لغة التطبيق أو العملة؟';

  @override
  String get helpCenterLanguageAnswer => 'نعم. اذهبي إلى الملف الشخصي ← الإعدادات ← الإعدادات المحلية للتبديل بين العربية والإنجليزية، ولتحديد الدولة والعملة المفضلتين لديكِ.';

  @override
  String get helpCenterPrivacyQuestion => 'كيف تُستخدم بياناتي؟';

  @override
  String get helpCenterPrivacyAnswer => 'راجعي سياسة الخصوصية في الإعدادات للاطلاع على التفاصيل الكاملة حول ما نجمعه وكيفية استخدامه.';

  @override
  String get helpCenterContactQuestion => 'ما زلت بحاجة إلى مساعدة — كيف أتواصل معكم؟';

  @override
  String get helpCenterContactAnswer => 'زوري صفحة تواصلي معنا في الإعدادات لأحدث طرق التواصل مع فريق روزيفيا.';

  @override
  String get contactUsSubtitle => 'يسعدنا التواصل معكِ.';

  @override
  String get contactUsNotConfiguredTitle => 'بيانات التواصل قريبًا';

  @override
  String get contactUsNotConfiguredDesc => 'نعمل حاليًا على توفير قنوات تواصل مباشرة لروزيفيا. في هذه الأثناء، يمكنكِ مراجعة مركز المساعدة للإجابة على الأسئلة الشائعة.';

  @override
  String get contactUsHelpCenterCta => 'الذهاب إلى مركز المساعدة';

  @override
  String get countryEgypt => 'مصر';

  @override
  String get countrySaudiArabia => 'السعودية';

  @override
  String get countryUae => 'الإمارات العربية المتحدة';

  @override
  String get countryUsa => 'الولايات المتحدة';

  @override
  String get countryUnitedKingdom => 'المملكة المتحدة';

  @override
  String get countryQatar => 'قطر';

  @override
  String get countryKuwait => 'الكويت';

  @override
  String get countryJordan => 'الأردن';

  @override
  String get myBeautyProfileScreenSubtitle => 'أخبرينا عن بشرتكِ لتتمكن روزيفيا من اقتراح منتجات أفضل لكِ.';

  @override
  String get skinType => 'نوع البشرة';

  @override
  String get skinTypeNormal => 'عادية';

  @override
  String get skinTypeDry => 'جافة';

  @override
  String get skinTypeOily => 'دهنية';

  @override
  String get skinTypeCombination => 'مختلطة';

  @override
  String get skinTypeSensitive => 'حساسة';

  @override
  String get skinTypeNotSet => 'غير محدد';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get editProfileScreenSubtitle => 'حدّثي اسمكِ وكيفية ظهوركِ عبر روزيفيا.';

  @override
  String get securityScreenSubtitle => 'إدارة طريقة تسجيل دخولكِ إلى روزيفيا.';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordDesc => 'سنرسل لكِ رابطًا آمنًا عبر البريد الإلكتروني لإعادة تعيين كلمة المرور.';

  @override
  String sendPasswordResetConfirm(String email) {
    return 'إرسال رابط إعادة تعيين كلمة المرور إلى $email؟';
  }

  @override
  String get passwordResetLinkSent => 'تم إرسال رابط إعادة تعيين كلمة المرور. تحققي من بريدكِ.';

  @override
  String get aiNoProductsFound => 'لم أتمكن من العثور على منتج مطابق في روزيفيا الآن. جربي تعديل تفضيلاتكِ أو ميزانيتكِ.';

  @override
  String get aiRecommendationsIntro => 'إليكِ بعض المنتجات التي قد تكون مناسبة.';

  @override
  String get adminProductsTitle => 'المنتجات';

  @override
  String get adminLastSync => 'آخر مزامنة';

  @override
  String get adminSyncNever => 'لم تتم أي مزامنة بعد';

  @override
  String get adminSyncRunning => 'المزامنة جارية…';

  @override
  String get adminSyncSuccess => 'نجحت آخر مزامنة';

  @override
  String get adminSyncError => 'فشلت آخر مزامنة';

  @override
  String adminSyncSummary(int imported, int skipped, int processed) {
    return 'تم استيراد $imported، وتخطي $skipped، من أصل $processed';
  }

  @override
  String get adminFallbackName => 'المشرف';

  @override
  String get adminHelloWave => 'مرحبًا أيها المشرف 👋';

  @override
  String get adminDashboardSubtitle => 'إليك آخر مستجدات روزيفيا اليوم.';

  @override
  String get adminMobileHeaderSubtitle => 'المشرف';

  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get navUsers => 'المستخدمون';

  @override
  String get navProducts => 'المنتجات';

  @override
  String get navPlatforms => 'المنصات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get adminTotalProducts => 'إجمالي المنتجات';

  @override
  String get adminTotalProductsDesc => 'المنتجات المتوفرة حاليًا';

  @override
  String get adminCategoryProductsDesc => 'المنتجات ضمن هذه الفئة';

  @override
  String get adminTotalUsersDesc => 'الحسابات المسجَّلة';

  @override
  String get adminVerifiedUsersDesc => 'عناوين بريد إلكتروني موثّقة';

  @override
  String get adminCatalogSync => 'مزامنة الكتالوج';

  @override
  String get adminLastSuccessfulSync => 'آخر مزامنة ناجحة';

  @override
  String get adminProductsImported => 'منتجات مستوردة';

  @override
  String get adminProductsSkipped => 'منتجات متخطاة';

  @override
  String get adminProductsProcessed => 'صفوف تمت معالجتها';

  @override
  String get adminSyncDuration => 'مدة المزامنة';

  @override
  String get adminSyncCatalogButton => 'مزامنة الكتالوج';

  @override
  String get adminSyncOpensGithub => 'يفتح GitHub Actions لتشغيل مهمة المزامنة.';

  @override
  String get adminSyncLinkFailed => 'تعذر فتح صفحة المزامنة. حاولي مرة أخرى.';

  @override
  String get adminRecentActivity => 'النشاط الأخير';

  @override
  String get adminActivityStarted => 'بدأت مزامنة الكتالوج';

  @override
  String get adminActivityCompleted => 'اكتملت مزامنة الكتالوج';

  @override
  String get adminActivityFailedEvent => 'فشلت مزامنة الكتالوج';

  @override
  String get adminNoActivityTitle => 'لا يوجد نشاط حديث';

  @override
  String get adminNoActivityDesc => 'سيظهر نشاط المزامنة هنا بعد أول عملية مزامنة للكتالوج.';

  @override
  String get adminJustNow => 'الآن';

  @override
  String adminMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String adminHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String adminDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String get adminQuickActions => 'إجراءات سريعة';

  @override
  String get adminViewProducts => 'عرض المنتجات';

  @override
  String get adminViewUsers => 'عرض المستخدمين';

  @override
  String get adminNoProductsTitle => 'لا توجد منتجات بعد';

  @override
  String get adminNoProductsDesc => 'سيظهر كتالوجك هنا بعد أول مزامنة ناجحة مع Awin.';

  @override
  String get adminSyncFailedDesc => 'حدث خطأ أثناء تحديث الكتالوج. يرجى المحاولة مرة أخرى.';

  @override
  String get adminCatalogSyncedSuccess => 'تمت مزامنة الكتالوج بنجاح.';

  @override
  String adminSyncedProductsCount(int count) {
    return 'تم تحديث $count منتج.';
  }

  @override
  String get adminAffiliatePlatforms => 'منصات التسويق بالعمولة';

  @override
  String get adminPlatformsDesc => 'عمليات الربط النشطة';

  @override
  String get adminPlatformActivity => 'نشاط المنصة';

  @override
  String get adminNoHistoricalActivity => 'لا تتوفر بيانات نشاط سابقة حتى الآن.';

  @override
  String get adminRecentUsers => 'أحدث المستخدمين';

  @override
  String get adminNoUsersYet => 'لا يوجد مستخدمون بعد';

  @override
  String adminJoinedOn(String date) {
    return 'انضم في $date';
  }

  @override
  String get adminStatusVerified => 'موثّق';

  @override
  String get adminStatusUnverified => 'غير موثّق';

  @override
  String get adminUsersSubtitle => 'إدارة مستخدمي روزيفيا';

  @override
  String get adminSearchUsersHint => 'ابحثي بالاسم أو البريد الإلكتروني';

  @override
  String get adminFilterAll => 'الكل';

  @override
  String get adminActiveUsers => 'المستخدمون النشطون';

  @override
  String get adminActiveUsersDesc => 'سجّلوا الدخول خلال آخر 30 يومًا';

  @override
  String get adminUserDetails => 'عرض التفاصيل';

  @override
  String get adminDeleteUser => 'حذف';

  @override
  String get adminDeleteNotAvailable => 'حذف المستخدمين غير متاح حاليًا.';

  @override
  String get adminUserListRestricted => 'عرض قائمة المستخدمين الكاملة يتطلب صلاحية إضافية في Firestore لم يتم تفعيلها بعد.';

  @override
  String get adminNoUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get adminNoUsersFoundDesc => 'جربي كلمة بحث مختلفة.';

  @override
  String get adminProductsScreenSubtitle => 'إدارة كتالوج روزيفيا للجمال';

  @override
  String get adminSearchProductsHint => 'ابحثي عن منتج';

  @override
  String get adminInStock => 'متوفر';

  @override
  String get adminOutOfStock => 'غير متوفر';

  @override
  String get adminPlatformsScreenTitle => 'منصات التسويق بالعمولة';

  @override
  String get adminPlatformsScreenSubtitle => 'إدارة منظومة الشراكات الخاصة بكِ';

  @override
  String get adminPlatformConnected => 'متصل';

  @override
  String get adminPlatformNotConnected => 'غير متصل';

  @override
  String get adminCatalogActive => 'نشط';

  @override
  String get adminCatalogInactive => 'غير نشط';

  @override
  String get adminComingSoonPlatform => 'المزيد من المنصات قريبًا';

  @override
  String get adminSettingsScreenSubtitle => 'إدارة تفضيلات المشرف';

  @override
  String get adminSectionAccount => 'الحساب';

  @override
  String get adminSectionAppearance => 'المظهر';

  @override
  String get adminNotificationsComingSoonDesc => 'إشعارات المشرف غير متاحة حاليًا.';

  @override
  String get adminNewUsers => 'مستخدمون جدد';

  @override
  String get adminNewUsersDesc => 'انضموا خلال آخر 7 أيام';
}
