// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome => 'Welcome to ROSIVA';

  @override
  String get chooseLanguage => 'Choose your preferred language';

  @override
  String get continueButton => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingTitle1 => 'Discover Beauty with AI';

  @override
  String get onboardingDescription1 => 'Your smart beauty assistant helps you find the best skincare and makeup products for you.';

  @override
  String get onboardingTitle2 => 'Personalized Beauty Advice';

  @override
  String get onboardingDescription2 => 'Chat with ROSIVA anytime to receive personalized beauty tips and routines.';

  @override
  String get onboardingTitle3 => 'Shop with Confidence';

  @override
  String get onboardingDescription3 => 'Explore trusted beauty products and shop securely.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue your ROSIVA journey';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Log In';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create account';

  @override
  String get registerSubtitle => 'Join ROSIVA and start your beauty ritual';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Full Name';

  @override
  String get createStrongPassword => 'Create a strong password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get logIn => 'Log In';

  @override
  String get agreeTermsMessage => 'Please agree to the Terms of Service and Privacy Policy.';

  @override
  String get registrationFailed => 'Registration failed. Please try again.';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get forgotPasswordTitle => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle => 'No worries, we\'ll send you reset instructions.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get checkYourInbox => 'Check your inbox';

  @override
  String resetLinkSentMessage(String email) {
    return 'We sent a password reset link to $email. Follow the instructions to create a new password.';
  }

  @override
  String get forgotPasswordFailed => 'Failed to send reset email.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get agreeToThe => 'I agree to the ';

  @override
  String get termsAnd => ' and ';

  @override
  String get signedInAndVerified => 'You\'re signed in and verified.';

  @override
  String get logOut => 'Log Out';

  @override
  String get appName => 'ROSIVA';

  @override
  String get verifyYourEmail => 'Verify your email';

  @override
  String verifyEmailMessage(String email) {
    return 'We\'ve sent a verification link to\n$email.\nTap the link in that email to activate your account.';
  }

  @override
  String get openMailApp => 'Open Mail App';

  @override
  String get iveVerified => 'I\'ve Verified';

  @override
  String get sending => 'Sending...';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resendEmailPrompt => 'Didn\'t get the email? Resend';

  @override
  String get openMailManually => 'Please open your mail app manually.';

  @override
  String get emailNotVerifiedYet => 'Your email is not verified yet. Please tap the link we sent you.';

  @override
  String get resendEmailFailed => 'Failed to resend email.';

  @override
  String get verificationEmailSent => 'Verification email sent!';

  @override
  String get yourEmailFallback => 'your email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordUppercase => 'Add at least one uppercase letter';

  @override
  String get passwordLowercase => 'Add at least one lowercase letter';

  @override
  String get passwordNumber => 'Add at least one number';

  @override
  String get passwordSpecialChar => 'Add at least one special character';

  @override
  String get loginPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get fullNameInvalid => 'Enter a valid full name';

  @override
  String get fullNameLettersOnly => 'Name can only contain letters';

  @override
  String get home => 'Home';

  @override
  String get explore => 'Explore';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get homeStartHere => 'Start here';

  @override
  String get homeDiscoverMoreTitle => 'Discover more';

  @override
  String get homeDiscoverMoreDesc => 'Explore ROSIVA\'s features and discover everything it can offer you.';

  @override
  String get homeFavoritesDesc => 'Keep the things you care about for easy access.';

  @override
  String get homeMyAccountTitle => 'My Account';

  @override
  String get homeMyAccountDesc => 'Manage your account details and preferences from here.';

  @override
  String welcomeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get rosivaUserFallback => 'ROSIVA User';

  @override
  String get yourProfile => 'Your Profile';

  @override
  String get profileManageSubtitle => 'Manage your account and preferences.';

  @override
  String get favoritesSubtitle => 'Your favorite items will appear here.';

  @override
  String get noFavoritesYetTitle => 'No favorites yet';

  @override
  String get noFavoritesYetDesc => 'Start adding your favorite items and they will appear here.';

  @override
  String get exploreSubtitle => 'Discover everything ROSIVA has to offer.';

  @override
  String get exploreComingSoonTitle => 'Explore coming soon';

  @override
  String get exploreComingSoonDesc => 'The explore section will be added here.';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get verifiedEmails => 'Verified Emails';

  @override
  String get legalLastUpdatedPlaceholder => 'Last updated: add the date here';

  @override
  String get tosSection1Title => '1. Acceptance of Terms';

  @override
  String get tosSection1Body => 'By using the ROSIVA app, you agree to these terms. If you do not agree with them, please do not use the app.';

  @override
  String get tosSection2Title => '2. Using the App';

  @override
  String get tosSection2Body => 'The app must be used only for lawful personal purposes. You must not attempt to misuse it or gain unauthorized access to other accounts.';

  @override
  String get tosSection3Title => '3. Account & Responsibility';

  @override
  String get tosSection3Body => 'You are responsible for keeping your account credentials confidential, and for any activity carried out through your account.';

  @override
  String get tosSection4Title => '4. Changes to the Service';

  @override
  String get tosSection4Body => 'We reserve the right to modify or discontinue any part of the app at any time without prior notice.';

  @override
  String get tosSection5Title => '5. Account Termination';

  @override
  String get tosSection5Body => 'We may suspend or terminate any account that violates these terms or is used unlawfully.';

  @override
  String get tosSection6Title => '6. Contact Us';

  @override
  String get tosSection6Body => 'For any questions about the Terms of Service, contact us at: add your email here.';

  @override
  String get privacySection1Title => '1. Data We Collect';

  @override
  String get privacySection1Body => 'We collect data such as your name, email address, and any information you enter within the app (such as skin type or favorites). Edit this text to reflect the data your app actually collects.';

  @override
  String get privacySection2Title => '2. How We Use Your Data';

  @override
  String get privacySection2Body => 'We use your data to provide the app\'s services, improve the user experience, and contact you when needed. We do not sell your data to any third party.';

  @override
  String get privacySection3Title => '3. Data Sharing';

  @override
  String get privacySection3Body => 'Some data may be shared with trusted service providers (such as Google Firebase) solely to operate the app, and not for any marketing purpose.';

  @override
  String get privacySection4Title => '4. Data Security';

  @override
  String get privacySection4Body => 'We take reasonable measures to protect your data, but complete security cannot be guaranteed for any electronic system 100%.';

  @override
  String get privacySection5Title => '5. Your Rights';

  @override
  String get privacySection5Body => 'You may request to modify or delete your data at any time by contacting us from within the app or by email.';

  @override
  String get privacySection6Title => '6. Contact Us';

  @override
  String get privacySection6Body => 'For any questions about the Privacy Policy, contact us at: add your email here.';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search products, brands...';

  @override
  String get seeAll => 'View All';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Done';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get categories => 'Categories';

  @override
  String get helloBeautiful => 'Hello, Beautiful';

  @override
  String get elevateYourRitual => 'Elevate your ritual.';

  @override
  String get askRosivaAnything => 'Ask ROSIVA anything...';

  @override
  String get curatedEssentials => 'Curated Essentials';

  @override
  String get trendingNow => 'Trending Now';

  @override
  String get skincare => 'Skincare';

  @override
  String get makeup => 'Makeup';

  @override
  String get perfume => 'Perfume';

  @override
  String get affiliateDisclosureShort => 'ROSIVA is an affiliate platform. Purchases occur on third-party sites. We may earn a commission on qualifying purchases made through our links.';

  @override
  String get loadingProducts => 'Loading products...';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get somethingWentWrongDesc => 'We couldn\'t load this content. Please check your connection and try again.';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noResultsFoundDesc => 'Try a different search term or browse our categories instead.';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get noProductsYetDesc => 'Products will appear here once they are added.';

  @override
  String get startSearching => 'Start searching';

  @override
  String get startSearchingDesc => 'Search for skincare, makeup, and perfume products.';

  @override
  String get browseCategories => 'Browse Categories';

  @override
  String get allProducts => 'All Products';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sort By';

  @override
  String get productDetails => 'Product Details';

  @override
  String get reviews => 'Reviews';

  @override
  String get editorsChoice => 'Editor\'s Choice';

  @override
  String get whyRosivaRecommends => 'Why ROSIVA recommends this';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get benefits => 'Benefits';

  @override
  String get howToUse => 'How to Use';

  @override
  String get openStore => 'Open Store';

  @override
  String get priceAvailabilityDisclaimer => 'Prices and availability on third-party sites may vary. As an affiliate, ROSIVA may earn a small commission on qualifying purchases.';

  @override
  String get patchTestDisclaimer => 'This product contains active ingredients. We recommend a patch test before full application. Consult a dermatologist if you have specific skin concerns.';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get rosivaAiTitle => 'ROSIVA AI Beauty Assistant';

  @override
  String get aiWelcomeMessage => 'Hello! I\'m your ROSIVA AI Beauty Assistant. How can I help you achieve your skin goals today?';

  @override
  String get aiInputHint => 'Ask ROSIVA anything...';

  @override
  String get aiSuggestionMascara => '💄 I want mascara';

  @override
  String get aiSuggestionLipstick => '💋 I want lipstick';

  @override
  String get aiSuggestionHighlighter => '✨ I want highlighter';

  @override
  String get aiSuggestionSkincare => '🧴 I want skincare';

  @override
  String get aiSuggestionPerfume => '🌸 I want women\'s perfume';

  @override
  String get aiSuggestionMakeupBrushes => '🖌️ I want makeup brushes';

  @override
  String get aiNotConfigured => 'The AI assistant isn\'t connected yet. Please check back soon.';

  @override
  String get aiAccuracyTitle => 'AI Accuracy';

  @override
  String get aiAccuracyDesc => 'Our recommendations are generated through complex data modeling based on the preferences you share. We strive for absolute precision in color matching and routine suggestions, but individual results may vary due to environmental factors and skin\'s unique nuances.';

  @override
  String get medicalAdviceDisclaimerTitle => 'Medical Advice Disclaimer';

  @override
  String get medicalAdviceDisclaimerDesc => 'ROSIVA does not provide medical diagnosis or dermatological advice. The product suggestions provided are for cosmetic guidance only. If you have active skin conditions, allergies, or are undergoing medical treatment, we strongly advise consulting with a qualified healthcare professional before introducing new active ingredients into your routine.';

  @override
  String get requiredLegalDisclosure => 'Required Legal Disclosure';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Customize your experience and how we work.';

  @override
  String get localization => 'Localization';

  @override
  String get country => 'Country';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get autoBasedOnLocation => 'Auto based on location';

  @override
  String get notifications => 'Notifications';

  @override
  String get aiRecommendations => 'AI Recommendations';

  @override
  String get aiRecommendationsDesc => 'Personalized product suggestions';

  @override
  String get priceDrops => 'Price Drops';

  @override
  String get priceDropsDesc => 'Get notified about saved items';

  @override
  String get newDiscoveries => 'New Discoveries';

  @override
  String get newDiscoveriesDesc => 'New brands and products';

  @override
  String get transparencyAndLegal => 'Transparency & Legal';

  @override
  String get affiliateTransparency => 'Affiliate Transparency';

  @override
  String get affiliateTransparencyDesc => 'ROSIVA is an intelligent recommendation engine, not a direct retailer. When you click \"Shop Now,\" you are directed to a third-party merchant. We may earn a commission through those links at no extra cost to you. This enables us to keep our premium beauty AI free for everyone.';

  @override
  String get medicalDisclaimer => 'Medical Advice Disclaimer';

  @override
  String get requiredLegalDisclosureShort => 'Required Legal Disclosure';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get security => 'Security';

  @override
  String get preferences => 'Preferences';

  @override
  String get support => 'Support';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get legalAndDisclaimers => 'Legal & Disclaimers';

  @override
  String get affiliateDisclosure => 'Affiliate Disclosure';

  @override
  String get aiAndMedicalDisclaimer => 'AI & Medical Disclaimer';

  @override
  String get termsOfServiceShort => 'Terms of Service';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get myBeautyProfile => 'My Beauty Profile';

  @override
  String get myBeautyProfileDesc => 'Skin Type, Goals';

  @override
  String get favoritesAndCollections => 'Favorites & Collections';

  @override
  String get personalization => 'Personalization';

  @override
  String memberSince(String year) {
    return 'Member since $year';
  }

  @override
  String get confirmLogout => 'Are you sure you want to log out?';

  @override
  String get categorySkincare => 'Skincare';

  @override
  String get categoryMakeup => 'Makeup';

  @override
  String get categoryPerfume => 'Perfumes';

  @override
  String get helpCenterSubtitle => 'Answers to common questions about your ROSIVA account, products, and the AI assistant.';

  @override
  String get helpCenterAccountQuestion => 'How do I manage my account?';

  @override
  String get helpCenterAccountAnswer => 'Go to Profile → Edit Profile to update your name and beauty preferences, or Profile → Security to reset your password.';

  @override
  String get helpCenterProductsQuestion => 'Where do product details come from?';

  @override
  String get helpCenterProductsAnswer => 'Product information, pricing, and availability are provided by our partner stores and may change without notice.';

  @override
  String get helpCenterOrdersQuestion => 'Does ROSIVA process my orders?';

  @override
  String get helpCenterOrdersAnswer => 'No. ROSIVA is a discovery platform — tapping \"Open Store\" takes you to the retailer\'s site to complete your purchase there.';

  @override
  String get helpCenterFavoritesQuestion => 'How do favorites work?';

  @override
  String get helpCenterFavoritesAnswer => 'Tap the heart icon on any product to save it to your Favorites tab. Your favorites are synced to your account.';

  @override
  String get helpCenterAiQuestion => 'How accurate is the AI assistant?';

  @override
  String get helpCenterAiAnswer => 'The AI assistant offers general beauty guidance based on what you share with it. It isn\'t a substitute for professional advice — see AI Accuracy in Settings for details.';

  @override
  String get helpCenterLanguageQuestion => 'Can I change the app language or currency?';

  @override
  String get helpCenterLanguageAnswer => 'Yes. Go to Profile → Settings → Localization to switch between English and Arabic, and to set your country and currency preferences.';

  @override
  String get helpCenterPrivacyQuestion => 'How is my data used?';

  @override
  String get helpCenterPrivacyAnswer => 'See our Privacy Policy in Settings for full details on what we collect and how it\'s used.';

  @override
  String get helpCenterContactQuestion => 'I still need help — how do I reach you?';

  @override
  String get helpCenterContactAnswer => 'Visit Contact Us in Settings for the latest ways to reach the ROSIVA team.';

  @override
  String get contactUsSubtitle => 'We\'d love to hear from you.';

  @override
  String get contactUsNotConfiguredTitle => 'Contact details coming soon';

  @override
  String get contactUsNotConfiguredDesc => 'We\'re setting up direct contact channels for ROSIVA. In the meantime, check the Help Center for answers to common questions.';

  @override
  String get contactUsHelpCenterCta => 'Go to Help Center';

  @override
  String get countryEgypt => 'Egypt';

  @override
  String get countrySaudiArabia => 'Saudi Arabia';

  @override
  String get countryUae => 'United Arab Emirates';

  @override
  String get countryUsa => 'United States';

  @override
  String get countryUnitedKingdom => 'United Kingdom';

  @override
  String get countryQatar => 'Qatar';

  @override
  String get countryKuwait => 'Kuwait';

  @override
  String get countryJordan => 'Jordan';

  @override
  String get myBeautyProfileScreenSubtitle => 'Tell us about your skin so ROSIVA can recommend better products for you.';

  @override
  String get skinType => 'Skin Type';

  @override
  String get skinTypeNormal => 'Normal';

  @override
  String get skinTypeDry => 'Dry';

  @override
  String get skinTypeOily => 'Oily';

  @override
  String get skinTypeCombination => 'Combination';

  @override
  String get skinTypeSensitive => 'Sensitive';

  @override
  String get skinTypeNotSet => 'Not set';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get editProfileScreenSubtitle => 'Update your name and how you appear across ROSIVA.';

  @override
  String get securityScreenSubtitle => 'Manage how you sign in to ROSIVA.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordDesc => 'We\'ll email you a secure link to reset your password.';

  @override
  String sendPasswordResetConfirm(String email) {
    return 'Send a password reset link to $email?';
  }

  @override
  String get passwordResetLinkSent => 'Password reset link sent. Check your inbox.';

  @override
  String get aiNoProductsFound => 'I couldn\'t find an exact match right now, but I can help you find another skincare, makeup, or perfume product.';

  @override
  String get aiErrorGeneric => 'Something went wrong with the AI assistant. Please try again ❤️';

  @override
  String get aiQuotaExceeded => 'ROSIVA AI is getting a lot of requests right now. Please wait a moment and try again ❤️';

  @override
  String get aiRecommendationsIntro => 'Here are some products that may be relevant.';

  @override
  String get adminProductsTitle => 'Products';

  @override
  String get adminLastSync => 'Last Sync';

  @override
  String get adminSyncNever => 'Never synced yet';

  @override
  String get adminSyncRunning => 'Sync in progress…';

  @override
  String get adminSyncSuccess => 'Last sync succeeded';

  @override
  String get adminSyncError => 'Last sync failed';

  @override
  String adminSyncSummary(int imported, int skipped, int processed) {
    return '$imported imported, $skipped skipped, $processed processed';
  }

  @override
  String get adminFallbackName => 'Admin';

  @override
  String get adminHelloWave => 'Hello Admin 👋';

  @override
  String get adminDashboardSubtitle => 'Here\'s what\'s happening with ROSIVA today.';

  @override
  String get adminMobileHeaderSubtitle => 'Admin';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navUsers => 'Users';

  @override
  String get navProducts => 'Products';

  @override
  String get navPlatforms => 'Platforms';

  @override
  String get navSettings => 'Settings';

  @override
  String get adminTotalProducts => 'Total Products';

  @override
  String get adminTotalProductsDesc => 'Products currently available';

  @override
  String get adminCategoryProductsDesc => 'Products in this category';

  @override
  String get adminTotalUsersDesc => 'Registered accounts';

  @override
  String get adminVerifiedUsersDesc => 'Verified email addresses';

  @override
  String get adminCatalogSync => 'Catalog Sync';

  @override
  String get adminLastSuccessfulSync => 'Last successful sync';

  @override
  String get adminProductsImported => 'Products imported';

  @override
  String get adminProductsSkipped => 'Products skipped';

  @override
  String get adminProductsProcessed => 'Rows processed';

  @override
  String get adminSyncDuration => 'Sync duration';

  @override
  String get adminSyncCatalogButton => 'Sync Catalog';

  @override
  String get adminSyncOpensGithub => 'Opens GitHub Actions to run the sync workflow.';

  @override
  String get adminSyncLinkFailed => 'Couldn\'t open the sync page. Try again.';

  @override
  String get adminRecentActivity => 'Recent Activity';

  @override
  String get adminActivityStarted => 'Catalog sync started';

  @override
  String get adminActivityCompleted => 'Catalog sync completed';

  @override
  String get adminActivityFailedEvent => 'Catalog sync failed';

  @override
  String get adminNoActivityTitle => 'No recent activity';

  @override
  String get adminNoActivityDesc => 'Sync activity will appear here after your first catalog sync.';

  @override
  String get adminJustNow => 'Just now';

  @override
  String adminMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String adminHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String adminDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get adminQuickActions => 'Quick Actions';

  @override
  String get adminViewProducts => 'View Products';

  @override
  String get adminViewUsers => 'View Users';

  @override
  String get adminNoProductsTitle => 'No products yet';

  @override
  String get adminNoProductsDesc => 'Your catalog will appear here after the first successful Awin sync.';

  @override
  String get adminSyncFailedDesc => 'Something went wrong while updating the catalog. Please try again.';

  @override
  String get adminCatalogSyncedSuccess => 'Catalog synced successfully.';

  @override
  String adminSyncedProductsCount(int count) {
    return '$count products updated.';
  }

  @override
  String get adminAffiliatePlatforms => 'Affiliate Platforms';

  @override
  String get adminPlatformsDesc => 'Connected integrations';

  @override
  String get adminPlatformActivity => 'Platform activity';

  @override
  String get adminNoHistoricalActivity => 'No historical activity data available yet.';

  @override
  String get adminRecentUsers => 'Recent Users';

  @override
  String get adminNoUsersYet => 'No users yet';

  @override
  String adminJoinedOn(String date) {
    return 'Joined $date';
  }

  @override
  String get adminStatusVerified => 'Verified';

  @override
  String get adminStatusUnverified => 'Unverified';

  @override
  String get adminUsersSubtitle => 'Manage ROSIVA users';

  @override
  String get adminSearchUsersHint => 'Search by name or email';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminActiveUsers => 'Active Users';

  @override
  String get adminActiveUsersDesc => 'Signed in within the last 30 days';

  @override
  String get adminUserDetails => 'View Details';

  @override
  String get adminDeleteUser => 'Delete';

  @override
  String get adminDeleteNotAvailable => 'Deleting users isn\'t available yet.';

  @override
  String get adminUserListRestricted => 'Full user list requires an additional Firestore permission that hasn\'t been enabled yet.';

  @override
  String get adminNoUsersFound => 'No users found';

  @override
  String get adminNoUsersFoundDesc => 'Try a different search term.';

  @override
  String get adminProductsScreenSubtitle => 'Manage the ROSIVA beauty catalog';

  @override
  String get adminSearchProductsHint => 'Search products';

  @override
  String get adminInStock => 'In Stock';

  @override
  String get adminOutOfStock => 'Out of Stock';

  @override
  String get adminPlatformsScreenTitle => 'Affiliate Platforms';

  @override
  String get adminPlatformsScreenSubtitle => 'Manage your connected affiliate ecosystem';

  @override
  String get adminPlatformConnected => 'Connected';

  @override
  String get adminPlatformNotConnected => 'Not Connected';

  @override
  String get adminCatalogActive => 'Active';

  @override
  String get adminCatalogInactive => 'Inactive';

  @override
  String get adminComingSoonPlatform => 'More platforms coming soon';

  @override
  String get adminSettingsScreenSubtitle => 'Manage your admin preferences';

  @override
  String get adminSectionAccount => 'Account';

  @override
  String get adminSectionAppearance => 'Appearance';

  @override
  String get adminNotificationsComingSoonDesc => 'Admin notifications aren\'t available yet.';

  @override
  String get adminNewUsers => 'New Users';

  @override
  String get adminNewUsersDesc => 'Joined in the last 7 days';

  @override
  String get adminSave => 'Save';

  @override
  String get adminCancel => 'Cancel';

  @override
  String get adminSaved => 'Saved';

  @override
  String get adminSaveFailed => 'Could not save. Please try again.';

  @override
  String get adminDiscardChanges => 'Discard changes?';

  @override
  String get adminEditProduct => 'Edit Product';

  @override
  String get adminProductOverridesNote => 'Name, price, currency, image and store link are refreshed daily by the Awin sync. Your edits are saved as overrides and always take precedence.';

  @override
  String get adminFieldName => 'Name';

  @override
  String get adminFieldBrand => 'Brand';

  @override
  String get adminFieldDescription => 'Description';

  @override
  String get adminFieldImageUrl => 'Image URL';

  @override
  String get adminFieldProductType => 'Product type';

  @override
  String get adminFieldProductTypeHint => 'e.g. mascara, face serum, makeup brush';

  @override
  String get adminFieldCategory => 'Category';

  @override
  String get adminFieldGender => 'Gender';

  @override
  String get adminGenderClassifierNote => 'Set by the classifier — not editable here.';

  @override
  String get adminFieldPrice => 'Price';

  @override
  String get adminFieldCurrency => 'Currency';

  @override
  String get adminFieldStoreUrl => 'Store / affiliate URL';

  @override
  String get adminFieldFeatured => 'Featured';

  @override
  String get adminFieldFeaturedDesc => 'Highlight this product across ROSIVA';

  @override
  String get adminFieldActive => 'Active';

  @override
  String get adminFieldActiveDesc => 'Inactive products are hidden from shoppers (soft delete)';

  @override
  String get adminFieldAdminNote => 'Admin note (internal)';

  @override
  String get adminInvalidUrl => 'Enter a valid https:// URL';

  @override
  String get adminInvalidNumber => 'Enter a valid number';

  @override
  String get adminRequiredField => 'This field is required';

  @override
  String get adminConfirmSaveProductTitle => 'Save product changes?';

  @override
  String get adminConfirmSaveProductBody => 'These changes take effect immediately for all shoppers.';

  @override
  String get adminFilterFeatured => 'Featured';

  @override
  String get adminFilterInactive => 'Inactive';

  @override
  String get adminFilterIneligible => 'Ineligible';

  @override
  String get adminFilterMissingLink => 'Missing link';

  @override
  String get adminFilterMissingPrice => 'Missing price';

  @override
  String get adminBadgeInactive => 'Inactive';

  @override
  String get adminBadgeFeatured => 'Featured';

  @override
  String get adminBadgeIneligible => 'Not in catalog';

  @override
  String get adminCatalogHealth => 'Catalog health';

  @override
  String get adminMetricSkincare => 'Skincare';

  @override
  String get adminMetricMakeup => 'Makeup';

  @override
  String get adminMetricPerfume => 'Perfume';

  @override
  String get adminMetricFeatured => 'Featured';

  @override
  String get adminMetricIneligible => 'Ineligible';

  @override
  String get adminMetricMissingLink => 'Missing affiliate link';

  @override
  String get adminMetricMissingPrice => 'Missing price';

  @override
  String get adminMetricInactive => 'Inactive';

  @override
  String get adminSectionAiAssistant => 'AI Assistant';

  @override
  String get adminSectionRegions => 'Regions & Currency';

  @override
  String get adminManageCountries => 'Countries';

  @override
  String get adminManageCurrencies => 'Currencies';

  @override
  String get adminAiControls => 'AI controls';

  @override
  String get adminAiControlsSubtitle => 'Turn the assistant on/off and set maintenance mode';

  @override
  String get adminAiEnabled => 'AI assistant enabled';

  @override
  String get adminAiEnabledDesc => 'When off, the assistant is unavailable for every user';

  @override
  String get adminAiMaintenance => 'Maintenance mode';

  @override
  String get adminAiMaintenanceDesc => 'Temporarily pause the assistant and show a message';

  @override
  String get adminAiMaintenanceMsgEn => 'Maintenance message (English)';

  @override
  String get adminAiMaintenanceMsgAr => 'Maintenance message (Arabic)';

  @override
  String get adminAiBackendAuthorityNote => 'These switches are enforced by the ROSIVA AI backend, not just the app.';

  @override
  String get adminCountriesTitle => 'Countries';

  @override
  String get adminCountriesSubtitle => 'Where ROSIVA is available, and each country’s currency';

  @override
  String get adminAddCountry => 'Add country';

  @override
  String get adminCountryCode => 'Country code (ISO, e.g. EG)';

  @override
  String get adminCountryNameEn => 'Name (English)';

  @override
  String get adminCountryNameAr => 'Name (Arabic)';

  @override
  String get adminCountrySortOrder => 'Sort order';

  @override
  String get adminCountryEnabledDesc => 'Show this country in the shopper picker';

  @override
  String get adminCurrenciesTitle => 'Currencies';

  @override
  String get adminCurrenciesSubtitle => 'Symbols and USD exchange rates for price display';

  @override
  String get adminCurrencySymbol => 'Symbol';

  @override
  String get adminCurrencyRate => 'Rate to USD';

  @override
  String get adminCurrencyRateHint => 'USD per 1 unit. Empty = no approximate conversion shown.';

  @override
  String get adminCurrencyNoRate => 'No rate';

  @override
  String get adminConfigLoadError => 'Could not load configuration.';

  @override
  String get adminNothingToShow => 'Nothing to show';

  @override
  String get aiMaintenanceBanner => 'The AI assistant is under maintenance.';

  @override
  String get adminRemove => 'Remove';

  @override
  String get adminOptional => 'optional';

  @override
  String get adminCountryOffers => 'Country offers';

  @override
  String get adminCountryOffersDesc => 'Per-country price and affiliate link. Countries without an offer keep the default price and link.';

  @override
  String get adminAddOffer => 'Add offer';

  @override
  String get adminClearOffer => 'Clear offer for this country';

  @override
  String get adminOfferInStock => 'In stock';

  @override
  String get adminNoEnabledCountries => 'No enabled countries. Add one under Regions & Currency first.';

  @override
  String get adminOfferInvalidCurrency => 'Currency must be one of the configured currencies';

  @override
  String get adminOfferNegativePrice => 'Price cannot be negative';

  @override
  String get adminCreateProduct => 'Create product';

  @override
  String get adminNewProduct => 'New product';

  @override
  String get adminCreateProductDesc => 'Manually added products are tagged source = \"admin\" and are excluded from the AI catalog by default.';

  @override
  String get adminProductCreated => 'Product created';

  @override
  String get adminFieldGenderWomen => 'Women';

  @override
  String get adminFieldGenderMen => 'Men';

  @override
  String get adminFieldGenderUnisex => 'Unisex';

  @override
  String get adminDisableUser => 'Disable user';

  @override
  String get adminEnableUser => 'Enable user';

  @override
  String get adminUserDisabledBadge => 'Disabled';

  @override
  String get adminConfirmDisableUserBody => 'The account will be marked disabled. Note: this does not block sign-in by itself — a Cloud Function or the Firebase console is still required for that.';

  @override
  String get adminConfirmEnableUserBody => 'Re-enable this account?';

  @override
  String get adminActivityLog => 'Activity log';

  @override
  String get adminActivityLogDesc => 'Recent admin actions, newest first';

  @override
  String get adminActivityEmpty => 'No activity recorded yet';

  @override
  String get adminActivityBy => 'by';

  @override
  String get adminAffiliateManager => 'Affiliate management';

  @override
  String get adminAffiliateManagerDesc => 'Review and fix affiliate links per country. Tap a product to edit its country offers.';

  @override
  String get adminFilterCountry => 'Country';

  @override
  String get adminFilterCurrency => 'Currency';

  @override
  String get adminFilterHasOffer => 'Has country offer';

  @override
  String get adminFilterMissingOffer => 'No country offer';

  @override
  String get adminFilterInStock => 'In stock';

  @override
  String get adminFilterOutOfStock => 'Out of stock';

  @override
  String get adminAnyCountry => 'Any country';

  @override
  String get adminAnyCurrency => 'Any currency';

  @override
  String get adminProductsByCountry => 'Products by country';

  @override
  String get adminByCountryWithOffer => 'with offer';

  @override
  String get adminByCountryInStock => 'in stock';

  @override
  String get adminByCountryOutOfStock => 'out of stock';

  @override
  String get adminByCountryMissingUrl => 'missing link';

  @override
  String get adminByCountryNone => 'No country offers configured yet.';

  @override
  String get adminAiDailyGlobalLimit => 'Daily global request limit';

  @override
  String get adminAiDailyGlobalLimitDesc => 'All users combined, per UTC day. Empty = unlimited.';

  @override
  String get adminAiDailyUserLimit => 'Daily per-user request limit';

  @override
  String get adminAiDailyUserLimitDesc => 'Per user, per UTC day (best-effort). Empty = unlimited.';

  @override
  String get adminAiLimitsBackendNote => 'Limits are enforced by the backend, not the app.';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsDesc => 'Alerts about new arrivals, price drops and beauty tips on this device.';

  @override
  String get pushStatusEnabled => 'Enabled on this device';

  @override
  String get pushStatusOff => 'Off';

  @override
  String get pushBlockedTitle => 'Notifications are blocked';

  @override
  String get pushBlockedBody => 'You\'ve blocked notifications for ROSIVA. Turn them back on in your browser or device settings, then try again.';

  @override
  String get pushEnableFailed => 'Couldn\'t enable notifications right now. Please try again.';

  @override
  String get pushEnabledToast => 'Notifications enabled';

  @override
  String get pushDisabledToast => 'Notifications turned off';

  @override
  String get pushNotConfigured => 'Push notifications aren\'t available in this build.';
}
