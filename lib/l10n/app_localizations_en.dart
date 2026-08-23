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
  String get adminToolsTitle => 'Admin Tools';

  @override
  String get adminToolsPlaceholder => 'User and content management tools will be added here soon.';

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
  String get affiliateTransparencyDesc => 'ROSIVA is an intelligent recommendation engine, not a direct retailer. When you click "Shop Now," you are directed to a third-party merchant. We may earn a commission through those links at no extra cost to you. This enables us to keep our premium beauty AI free for everyone.';

  @override
  String get medicalDisclaimer => 'Medical Advice Disclaimer';

  @override
  String get requiredLegalDisclosureShort => 'Required Legal Disclosure';

  @override
  String get darkMode => 'Dark Mode';

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
}
