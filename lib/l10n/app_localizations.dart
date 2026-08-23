import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ROSIVA'**
  String get welcome;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Discover Beauty with AI'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDescription1.
  ///
  /// In en, this message translates to:
  /// **'Your smart beauty assistant helps you find the best skincare and makeup products for you.'**
  String get onboardingDescription1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Personalized Beauty Advice'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDescription2.
  ///
  /// In en, this message translates to:
  /// **'Chat with ROSIVA anytime to receive personalized beauty tips and routines.'**
  String get onboardingDescription2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Shop with Confidence'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDescription3.
  ///
  /// In en, this message translates to:
  /// **'Explore trusted beauty products and shop securely.'**
  String get onboardingDescription3;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your ROSIVA journey'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join ROSIVA and start your beauty ritual'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameHint;

  /// No description provided for @createStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get createStrongPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @agreeTermsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Service and Privacy Policy.'**
  String get agreeTermsMessage;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries, we\'ll send you reset instructions.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @checkYourInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get checkYourInbox;

  /// No description provided for @resetLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We sent a password reset link to {email}. Follow the instructions to create a new password.'**
  String resetLinkSentMessage(String email);

  /// No description provided for @forgotPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get forgotPasswordFailed;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @agreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToThe;

  /// No description provided for @termsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsAnd;

  /// No description provided for @signedInAndVerified.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in and verified.'**
  String get signedInAndVerified;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ROSIVA'**
  String get appName;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @verifyEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to\n{email}.\nTap the link in that email to activate your account.'**
  String verifyEmailMessage(String email);

  /// No description provided for @openMailApp.
  ///
  /// In en, this message translates to:
  /// **'Open Mail App'**
  String get openMailApp;

  /// No description provided for @iveVerified.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Verified'**
  String get iveVerified;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @resendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// No description provided for @resendEmailPrompt.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the email? Resend'**
  String get resendEmailPrompt;

  /// No description provided for @openMailManually.
  ///
  /// In en, this message translates to:
  /// **'Please open your mail app manually.'**
  String get openMailManually;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Your email is not verified yet. Please tap the link we sent you.'**
  String get emailNotVerifiedYet;

  /// No description provided for @resendEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend email.'**
  String get resendEmailFailed;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// No description provided for @yourEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get yourEmailFallback;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Add at least one uppercase letter'**
  String get passwordUppercase;

  /// No description provided for @passwordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Add at least one lowercase letter'**
  String get passwordLowercase;

  /// No description provided for @passwordNumber.
  ///
  /// In en, this message translates to:
  /// **'Add at least one number'**
  String get passwordNumber;

  /// No description provided for @passwordSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Add at least one special character'**
  String get passwordSpecialChar;

  /// No description provided for @loginPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginPasswordMinLength;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @fullNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid full name'**
  String get fullNameInvalid;

  /// No description provided for @fullNameLettersOnly.
  ///
  /// In en, this message translates to:
  /// **'Name can only contain letters'**
  String get fullNameLettersOnly;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @homeStartHere.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get homeStartHere;

  /// No description provided for @homeDiscoverMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover more'**
  String get homeDiscoverMoreTitle;

  /// No description provided for @homeDiscoverMoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore ROSIVA's features and discover everything it can offer you.'**
  String get homeDiscoverMoreDesc;

  /// No description provided for @homeFavoritesDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep the things you care about for easy access.'**
  String get homeFavoritesDesc;

  /// No description provided for @homeMyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get homeMyAccountTitle;

  /// No description provided for @homeMyAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your account details and preferences from here.'**
  String get homeMyAccountDesc;

  /// No description provided for @welcomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String welcomeGreeting(String name);

  /// No description provided for @rosivaUserFallback.
  ///
  /// In en, this message translates to:
  /// **'ROSIVA User'**
  String get rosivaUserFallback;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @profileManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and preferences.'**
  String get profileManageSubtitle;

  /// No description provided for @favoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your favorite items will appear here.'**
  String get favoritesSubtitle;

  /// No description provided for @noFavoritesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYetTitle;

  /// No description provided for @noFavoritesYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Start adding your favorite items and they will appear here.'**
  String get noFavoritesYetDesc;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover everything ROSIVA has to offer.'**
  String get exploreSubtitle;

  /// No description provided for @exploreComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore coming soon'**
  String get exploreComingSoonTitle;

  /// No description provided for @exploreComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'The explore section will be added here.'**
  String get exploreComingSoonDesc;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @verifiedEmails.
  ///
  /// In en, this message translates to:
  /// **'Verified Emails'**
  String get verifiedEmails;

  /// No description provided for @adminToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Tools'**
  String get adminToolsTitle;

  /// No description provided for @adminToolsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'User and content management tools will be added here soon.'**
  String get adminToolsPlaceholder;

  /// No description provided for @legalLastUpdatedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Last updated: add the date here'**
  String get legalLastUpdatedPlaceholder;

  /// No description provided for @tosSection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get tosSection1Title;

  /// No description provided for @tosSection1Body.
  ///
  /// In en, this message translates to:
  /// **'By using the ROSIVA app, you agree to these terms. If you do not agree with them, please do not use the app.'**
  String get tosSection1Body;

  /// No description provided for @tosSection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Using the App'**
  String get tosSection2Title;

  /// No description provided for @tosSection2Body.
  ///
  /// In en, this message translates to:
  /// **'The app must be used only for lawful personal purposes. You must not attempt to misuse it or gain unauthorized access to other accounts.'**
  String get tosSection2Body;

  /// No description provided for @tosSection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Account & Responsibility'**
  String get tosSection3Title;

  /// No description provided for @tosSection3Body.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for keeping your account credentials confidential, and for any activity carried out through your account.'**
  String get tosSection3Body;

  /// No description provided for @tosSection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Changes to the Service'**
  String get tosSection4Title;

  /// No description provided for @tosSection4Body.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify or discontinue any part of the app at any time without prior notice.'**
  String get tosSection4Body;

  /// No description provided for @tosSection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Account Termination'**
  String get tosSection5Title;

  /// No description provided for @tosSection5Body.
  ///
  /// In en, this message translates to:
  /// **'We may suspend or terminate any account that violates these terms or is used unlawfully.'**
  String get tosSection5Body;

  /// No description provided for @tosSection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Contact Us'**
  String get tosSection6Title;

  /// No description provided for @tosSection6Body.
  ///
  /// In en, this message translates to:
  /// **'For any questions about the Terms of Service, contact us at: add your email here.'**
  String get tosSection6Body;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Data We Collect'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Body.
  ///
  /// In en, this message translates to:
  /// **'We collect data such as your name, email address, and any information you enter within the app (such as skin type or favorites). Edit this text to reflect the data your app actually collects.'**
  String get privacySection1Body;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Data'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Body.
  ///
  /// In en, this message translates to:
  /// **'We use your data to provide the app's services, improve the user experience, and contact you when needed. We do not sell your data to any third party.'**
  String get privacySection2Body;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Sharing'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Body.
  ///
  /// In en, this message translates to:
  /// **'Some data may be shared with trusted service providers (such as Google Firebase) solely to operate the app, and not for any marketing purpose.'**
  String get privacySection3Body;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data Security'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Body.
  ///
  /// In en, this message translates to:
  /// **'We take reasonable measures to protect your data, but complete security cannot be guaranteed for any electronic system 100%.'**
  String get privacySection4Body;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Your Rights'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Body.
  ///
  /// In en, this message translates to:
  /// **'You may request to modify or delete your data at any time by contacting us from within the app or by email.'**
  String get privacySection5Body;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Contact Us'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Body.
  ///
  /// In en, this message translates to:
  /// **'For any questions about the Privacy Policy, contact us at: add your email here.'**
  String get privacySection6Body;

  /// No description provided for @search.
  String get search;

  /// No description provided for @searchHint.
  String get searchHint;

  /// No description provided for @seeAll.
  String get seeAll;

  /// No description provided for @cancel.
  String get cancel;

  /// No description provided for @retry.
  String get retry;

  /// No description provided for @save.
  String get save;

  /// No description provided for @apply.
  String get apply;

  /// No description provided for @done.
  String get done;

  /// No description provided for @comingSoon.
  String get comingSoon;

  /// No description provided for @aiAssistant.
  String get aiAssistant;

  /// No description provided for @categories.
  String get categories;

  /// No description provided for @helloBeautiful.
  String get helloBeautiful;

  /// No description provided for @elevateYourRitual.
  String get elevateYourRitual;

  /// No description provided for @askRosivaAnything.
  String get askRosivaAnything;

  /// No description provided for @curatedEssentials.
  String get curatedEssentials;

  /// No description provided for @trendingNow.
  String get trendingNow;

  /// No description provided for @skincare.
  String get skincare;

  /// No description provided for @makeup.
  String get makeup;

  /// No description provided for @perfume.
  String get perfume;

  /// No description provided for @affiliateDisclosureShort.
  String get affiliateDisclosureShort;

  /// No description provided for @loadingProducts.
  String get loadingProducts;

  /// No description provided for @somethingWentWrong.
  String get somethingWentWrong;

  /// No description provided for @somethingWentWrongDesc.
  String get somethingWentWrongDesc;

  /// No description provided for @noResultsFound.
  String get noResultsFound;

  /// No description provided for @noResultsFoundDesc.
  String get noResultsFoundDesc;

  /// No description provided for @noProductsYet.
  String get noProductsYet;

  /// No description provided for @noProductsYetDesc.
  String get noProductsYetDesc;

  /// No description provided for @startSearching.
  String get startSearching;

  /// No description provided for @startSearchingDesc.
  String get startSearchingDesc;

  /// No description provided for @browseCategories.
  String get browseCategories;

  /// No description provided for @allProducts.
  String get allProducts;

  /// No description provided for @filter.
  String get filter;

  /// No description provided for @sortBy.
  String get sortBy;

  /// No description provided for @productDetails.
  String get productDetails;

  /// No description provided for @reviews.
  String get reviews;

  /// No description provided for @editorsChoice.
  String get editorsChoice;

  /// No description provided for @whyRosivaRecommends.
  String get whyRosivaRecommends;

  /// No description provided for @ingredients.
  String get ingredients;

  /// No description provided for @benefits.
  String get benefits;

  /// No description provided for @howToUse.
  String get howToUse;

  /// No description provided for @openStore.
  String get openStore;

  /// No description provided for @priceAvailabilityDisclaimer.
  String get priceAvailabilityDisclaimer;

  /// No description provided for @patchTestDisclaimer.
  String get patchTestDisclaimer;

  /// No description provided for @addToFavorites.
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  String get removeFromFavorites;

  /// No description provided for @addedToFavorites.
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  String get removedFromFavorites;

  /// No description provided for @rosivaAiTitle.
  String get rosivaAiTitle;

  /// No description provided for @aiWelcomeMessage.
  String get aiWelcomeMessage;

  /// No description provided for @aiInputHint.
  String get aiInputHint;

  /// No description provided for @aiNotConfigured.
  String get aiNotConfigured;

  /// No description provided for @aiAccuracyTitle.
  String get aiAccuracyTitle;

  /// No description provided for @aiAccuracyDesc.
  String get aiAccuracyDesc;

  /// No description provided for @medicalAdviceDisclaimerTitle.
  String get medicalAdviceDisclaimerTitle;

  /// No description provided for @medicalAdviceDisclaimerDesc.
  String get medicalAdviceDisclaimerDesc;

  /// No description provided for @requiredLegalDisclosure.
  String get requiredLegalDisclosure;

  /// No description provided for @settings.
  String get settings;

  /// No description provided for @settingsSubtitle.
  String get settingsSubtitle;

  /// No description provided for @localization.
  String get localization;

  /// No description provided for @country.
  String get country;

  /// No description provided for @language.
  String get language;

  /// No description provided for @currency.
  String get currency;

  /// No description provided for @autoBasedOnLocation.
  String get autoBasedOnLocation;

  /// No description provided for @notifications.
  String get notifications;

  /// No description provided for @aiRecommendations.
  String get aiRecommendations;

  /// No description provided for @aiRecommendationsDesc.
  String get aiRecommendationsDesc;

  /// No description provided for @priceDrops.
  String get priceDrops;

  /// No description provided for @priceDropsDesc.
  String get priceDropsDesc;

  /// No description provided for @newDiscoveries.
  String get newDiscoveries;

  /// No description provided for @newDiscoveriesDesc.
  String get newDiscoveriesDesc;

  /// No description provided for @transparencyAndLegal.
  String get transparencyAndLegal;

  /// No description provided for @affiliateTransparency.
  String get affiliateTransparency;

  /// No description provided for @affiliateTransparencyDesc.
  String get affiliateTransparencyDesc;

  /// No description provided for @medicalDisclaimer.
  String get medicalDisclaimer;

  /// No description provided for @requiredLegalDisclosureShort.
  String get requiredLegalDisclosureShort;

  /// No description provided for @darkMode.
  String get darkMode;

  /// No description provided for @accountSettings.
  String get accountSettings;

  /// No description provided for @editProfile.
  String get editProfile;

  /// No description provided for @security.
  String get security;

  /// No description provided for @preferences.
  String get preferences;

  /// No description provided for @support.
  String get support;

  /// No description provided for @helpCenter.
  String get helpCenter;

  /// No description provided for @contactUs.
  String get contactUs;

  /// No description provided for @legalAndDisclaimers.
  String get legalAndDisclaimers;

  /// No description provided for @affiliateDisclosure.
  String get affiliateDisclosure;

  /// No description provided for @aiAndMedicalDisclaimer.
  String get aiAndMedicalDisclaimer;

  /// No description provided for @termsOfServiceShort.
  String get termsOfServiceShort;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @myBeautyProfile.
  String get myBeautyProfile;

  /// No description provided for @myBeautyProfileDesc.
  String get myBeautyProfileDesc;

  /// No description provided for @favoritesAndCollections.
  String get favoritesAndCollections;

  /// No description provided for @personalization.
  String get personalization;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String memberSince(String year);

  /// No description provided for @confirmLogout.
  String get confirmLogout;

  /// No description provided for @categorySkincare.
  String get categorySkincare;

  /// No description provided for @categoryMakeup.
  String get categoryMakeup;

  /// No description provided for @categoryPerfume.
  String get categoryPerfume;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
