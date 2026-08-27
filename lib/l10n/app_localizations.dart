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
  /// **'Explore ROSIVA\'s features and discover everything it can offer you.'**
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
  /// **'We use your data to provide the app\'s services, improve the user experience, and contact you when needed. We do not sell your data to any third party.'**
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
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products, brands...'**
  String get searchHint;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get seeAll;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @helloBeautiful.
  ///
  /// In en, this message translates to:
  /// **'Hello, Beautiful'**
  String get helloBeautiful;

  /// No description provided for @elevateYourRitual.
  ///
  /// In en, this message translates to:
  /// **'Elevate your ritual.'**
  String get elevateYourRitual;

  /// No description provided for @askRosivaAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask ROSIVA anything...'**
  String get askRosivaAnything;

  /// No description provided for @curatedEssentials.
  ///
  /// In en, this message translates to:
  /// **'Curated Essentials'**
  String get curatedEssentials;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @skincare.
  ///
  /// In en, this message translates to:
  /// **'Skincare'**
  String get skincare;

  /// No description provided for @makeup.
  ///
  /// In en, this message translates to:
  /// **'Makeup'**
  String get makeup;

  /// No description provided for @perfume.
  ///
  /// In en, this message translates to:
  /// **'Perfume'**
  String get perfume;

  /// No description provided for @affiliateDisclosureShort.
  ///
  /// In en, this message translates to:
  /// **'ROSIVA is an affiliate platform. Purchases occur on third-party sites. We may earn a commission on qualifying purchases made through our links.'**
  String get affiliateDisclosureShort;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @somethingWentWrongDesc.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this content. Please check your connection and try again.'**
  String get somethingWentWrongDesc;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noResultsFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or browse our categories instead.'**
  String get noResultsFoundDesc;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @noProductsYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Products will appear here once they are added.'**
  String get noProductsYetDesc;

  /// No description provided for @startSearching.
  ///
  /// In en, this message translates to:
  /// **'Start searching'**
  String get startSearching;

  /// No description provided for @startSearchingDesc.
  ///
  /// In en, this message translates to:
  /// **'Search for skincare, makeup, and perfume products.'**
  String get startSearchingDesc;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @editorsChoice.
  ///
  /// In en, this message translates to:
  /// **'Editor\'s Choice'**
  String get editorsChoice;

  /// No description provided for @whyRosivaRecommends.
  ///
  /// In en, this message translates to:
  /// **'Why ROSIVA recommends this'**
  String get whyRosivaRecommends;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get howToUse;

  /// No description provided for @openStore.
  ///
  /// In en, this message translates to:
  /// **'Open Store'**
  String get openStore;

  /// No description provided for @priceAvailabilityDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Prices and availability on third-party sites may vary. As an affiliate, ROSIVA may earn a small commission on qualifying purchases.'**
  String get priceAvailabilityDisclaimer;

  /// No description provided for @patchTestDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This product contains active ingredients. We recommend a patch test before full application. Consult a dermatologist if you have specific skin concerns.'**
  String get patchTestDisclaimer;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @rosivaAiTitle.
  ///
  /// In en, this message translates to:
  /// **'ROSIVA AI Beauty Assistant'**
  String get rosivaAiTitle;

  /// No description provided for @aiWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m your ROSIVA AI Beauty Assistant. How can I help you achieve your skin goals today?'**
  String get aiWelcomeMessage;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask ROSIVA anything...'**
  String get aiInputHint;

  /// No description provided for @aiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant isn\'t connected yet. Please check back soon.'**
  String get aiNotConfigured;

  /// No description provided for @aiAccuracyTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Accuracy'**
  String get aiAccuracyTitle;

  /// No description provided for @aiAccuracyDesc.
  ///
  /// In en, this message translates to:
  /// **'Our recommendations are generated through complex data modeling based on the preferences you share. We strive for absolute precision in color matching and routine suggestions, but individual results may vary due to environmental factors and skin\'s unique nuances.'**
  String get aiAccuracyDesc;

  /// No description provided for @medicalAdviceDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Advice Disclaimer'**
  String get medicalAdviceDisclaimerTitle;

  /// No description provided for @medicalAdviceDisclaimerDesc.
  ///
  /// In en, this message translates to:
  /// **'ROSIVA does not provide medical diagnosis or dermatological advice. The product suggestions provided are for cosmetic guidance only. If you have active skin conditions, allergies, or are undergoing medical treatment, we strongly advise consulting with a qualified healthcare professional before introducing new active ingredients into your routine.'**
  String get medicalAdviceDisclaimerDesc;

  /// No description provided for @requiredLegalDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Required Legal Disclosure'**
  String get requiredLegalDisclosure;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience and how we work.'**
  String get settingsSubtitle;

  /// No description provided for @localization.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get localization;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @autoBasedOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Auto based on location'**
  String get autoBasedOnLocation;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendations'**
  String get aiRecommendations;

  /// No description provided for @aiRecommendationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Personalized product suggestions'**
  String get aiRecommendationsDesc;

  /// No description provided for @priceDrops.
  ///
  /// In en, this message translates to:
  /// **'Price Drops'**
  String get priceDrops;

  /// No description provided for @priceDropsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about saved items'**
  String get priceDropsDesc;

  /// No description provided for @newDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'New Discoveries'**
  String get newDiscoveries;

  /// No description provided for @newDiscoveriesDesc.
  ///
  /// In en, this message translates to:
  /// **'New brands and products'**
  String get newDiscoveriesDesc;

  /// No description provided for @transparencyAndLegal.
  ///
  /// In en, this message translates to:
  /// **'Transparency & Legal'**
  String get transparencyAndLegal;

  /// No description provided for @affiliateTransparency.
  ///
  /// In en, this message translates to:
  /// **'Affiliate Transparency'**
  String get affiliateTransparency;

  /// No description provided for @affiliateTransparencyDesc.
  ///
  /// In en, this message translates to:
  /// **'ROSIVA is an intelligent recommendation engine, not a direct retailer. When you click \"Shop Now,\" you are directed to a third-party merchant. We may earn a commission through those links at no extra cost to you. This enables us to keep our premium beauty AI free for everyone.'**
  String get affiliateTransparencyDesc;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Medical Advice Disclaimer'**
  String get medicalDisclaimer;

  /// No description provided for @requiredLegalDisclosureShort.
  ///
  /// In en, this message translates to:
  /// **'Required Legal Disclosure'**
  String get requiredLegalDisclosureShort;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @legalAndDisclaimers.
  ///
  /// In en, this message translates to:
  /// **'Legal & Disclaimers'**
  String get legalAndDisclaimers;

  /// No description provided for @affiliateDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Affiliate Disclosure'**
  String get affiliateDisclosure;

  /// No description provided for @aiAndMedicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI & Medical Disclaimer'**
  String get aiAndMedicalDisclaimer;

  /// No description provided for @termsOfServiceShort.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceShort;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @myBeautyProfile.
  ///
  /// In en, this message translates to:
  /// **'My Beauty Profile'**
  String get myBeautyProfile;

  /// No description provided for @myBeautyProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Skin Type, Goals'**
  String get myBeautyProfileDesc;

  /// No description provided for @favoritesAndCollections.
  ///
  /// In en, this message translates to:
  /// **'Favorites & Collections'**
  String get favoritesAndCollections;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String memberSince(String year);

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogout;

  /// No description provided for @categorySkincare.
  ///
  /// In en, this message translates to:
  /// **'Skincare'**
  String get categorySkincare;

  /// No description provided for @categoryMakeup.
  ///
  /// In en, this message translates to:
  /// **'Makeup'**
  String get categoryMakeup;

  /// No description provided for @categoryPerfume.
  ///
  /// In en, this message translates to:
  /// **'Perfumes'**
  String get categoryPerfume;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answers to common questions about your ROSIVA account, products, and the AI assistant.'**
  String get helpCenterSubtitle;

  /// No description provided for @helpCenterAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I manage my account?'**
  String get helpCenterAccountQuestion;

  /// No description provided for @helpCenterAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Edit Profile to update your name and beauty preferences, or Profile → Security to reset your password.'**
  String get helpCenterAccountAnswer;

  /// No description provided for @helpCenterProductsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where do product details come from?'**
  String get helpCenterProductsQuestion;

  /// No description provided for @helpCenterProductsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Product information, pricing, and availability are provided by our partner stores and may change without notice.'**
  String get helpCenterProductsAnswer;

  /// No description provided for @helpCenterOrdersQuestion.
  ///
  /// In en, this message translates to:
  /// **'Does ROSIVA process my orders?'**
  String get helpCenterOrdersQuestion;

  /// No description provided for @helpCenterOrdersAnswer.
  ///
  /// In en, this message translates to:
  /// **'No. ROSIVA is a discovery platform — tapping \"Open Store\" takes you to the retailer\'s site to complete your purchase there.'**
  String get helpCenterOrdersAnswer;

  /// No description provided for @helpCenterFavoritesQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do favorites work?'**
  String get helpCenterFavoritesQuestion;

  /// No description provided for @helpCenterFavoritesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any product to save it to your Favorites tab. Your favorites are synced to your account.'**
  String get helpCenterFavoritesAnswer;

  /// No description provided for @helpCenterAiQuestion.
  ///
  /// In en, this message translates to:
  /// **'How accurate is the AI assistant?'**
  String get helpCenterAiQuestion;

  /// No description provided for @helpCenterAiAnswer.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant offers general beauty guidance based on what you share with it. It isn\'t a substitute for professional advice — see AI Accuracy in Settings for details.'**
  String get helpCenterAiAnswer;

  /// No description provided for @helpCenterLanguageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I change the app language or currency?'**
  String get helpCenterLanguageQuestion;

  /// No description provided for @helpCenterLanguageAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes. Go to Profile → Settings → Localization to switch between English and Arabic, and to set your country and currency preferences.'**
  String get helpCenterLanguageAnswer;

  /// No description provided for @helpCenterPrivacyQuestion.
  ///
  /// In en, this message translates to:
  /// **'How is my data used?'**
  String get helpCenterPrivacyQuestion;

  /// No description provided for @helpCenterPrivacyAnswer.
  ///
  /// In en, this message translates to:
  /// **'See our Privacy Policy in Settings for full details on what we collect and how it\'s used.'**
  String get helpCenterPrivacyAnswer;

  /// No description provided for @helpCenterContactQuestion.
  ///
  /// In en, this message translates to:
  /// **'I still need help — how do I reach you?'**
  String get helpCenterContactQuestion;

  /// No description provided for @helpCenterContactAnswer.
  ///
  /// In en, this message translates to:
  /// **'Visit Contact Us in Settings for the latest ways to reach the ROSIVA team.'**
  String get helpCenterContactAnswer;

  /// No description provided for @contactUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'d love to hear from you.'**
  String get contactUsSubtitle;

  /// No description provided for @contactUsNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact details coming soon'**
  String get contactUsNotConfiguredTitle;

  /// No description provided for @contactUsNotConfiguredDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'re setting up direct contact channels for ROSIVA. In the meantime, check the Help Center for answers to common questions.'**
  String get contactUsNotConfiguredDesc;

  /// No description provided for @contactUsHelpCenterCta.
  ///
  /// In en, this message translates to:
  /// **'Go to Help Center'**
  String get contactUsHelpCenterCta;

  /// No description provided for @countryEgypt.
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get countryEgypt;

  /// No description provided for @countrySaudiArabia.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get countrySaudiArabia;

  /// No description provided for @countryUae.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get countryUae;

  /// No description provided for @countryUsa.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get countryUsa;

  /// No description provided for @countryUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get countryUnitedKingdom;

  /// No description provided for @countryQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get countryQatar;

  /// No description provided for @countryKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get countryKuwait;

  /// No description provided for @countryJordan.
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get countryJordan;

  /// No description provided for @myBeautyProfileScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your skin so ROSIVA can recommend better products for you.'**
  String get myBeautyProfileScreenSubtitle;

  /// No description provided for @skinType.
  ///
  /// In en, this message translates to:
  /// **'Skin Type'**
  String get skinType;

  /// No description provided for @skinTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get skinTypeNormal;

  /// No description provided for @skinTypeDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get skinTypeDry;

  /// No description provided for @skinTypeOily.
  ///
  /// In en, this message translates to:
  /// **'Oily'**
  String get skinTypeOily;

  /// No description provided for @skinTypeCombination.
  ///
  /// In en, this message translates to:
  /// **'Combination'**
  String get skinTypeCombination;

  /// No description provided for @skinTypeSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get skinTypeSensitive;

  /// No description provided for @skinTypeNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get skinTypeNotSet;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @editProfileScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name and how you appear across ROSIVA.'**
  String get editProfileScreenSubtitle;

  /// No description provided for @securityScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage how you sign in to ROSIVA.'**
  String get securityScreenSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a secure link to reset your password.'**
  String get changePasswordDesc;

  /// No description provided for @sendPasswordResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send a password reset link to {email}?'**
  String sendPasswordResetConfirm(String email);

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent. Check your inbox.'**
  String get passwordResetLinkSent;

  /// No description provided for @aiNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t find a matching product in ROSIVA right now. Try adjusting your preferences or budget.'**
  String get aiNoProductsFound;

  /// No description provided for @aiRecommendationsIntro.
  ///
  /// In en, this message translates to:
  /// **'Here are some products that may be relevant.'**
  String get aiRecommendationsIntro;

  /// No description provided for @adminProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get adminProductsTitle;

  /// No description provided for @adminLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get adminLastSync;

  /// No description provided for @adminSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Never synced yet'**
  String get adminSyncNever;

  /// No description provided for @adminSyncRunning.
  ///
  /// In en, this message translates to:
  /// **'Sync in progress…'**
  String get adminSyncRunning;

  /// No description provided for @adminSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Last sync succeeded'**
  String get adminSyncSuccess;

  /// No description provided for @adminSyncError.
  ///
  /// In en, this message translates to:
  /// **'Last sync failed'**
  String get adminSyncError;

  /// No description provided for @adminSyncSummary.
  ///
  /// In en, this message translates to:
  /// **'{imported} imported, {skipped} skipped, {processed} processed'**
  String adminSyncSummary(int imported, int skipped, int processed);

  /// No description provided for @adminFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminFallbackName;

  /// No description provided for @adminHelloWave.
  ///
  /// In en, this message translates to:
  /// **'Hello Admin 👋'**
  String get adminHelloWave;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s happening with ROSIVA today.'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminMobileHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminMobileHeaderSubtitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get navPlatforms;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @adminTotalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get adminTotalProducts;

  /// No description provided for @adminTotalProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Products currently available'**
  String get adminTotalProductsDesc;

  /// No description provided for @adminCategoryProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Products in this category'**
  String get adminCategoryProductsDesc;

  /// No description provided for @adminTotalUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Registered accounts'**
  String get adminTotalUsersDesc;

  /// No description provided for @adminVerifiedUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Verified email addresses'**
  String get adminVerifiedUsersDesc;

  /// No description provided for @adminCatalogSync.
  ///
  /// In en, this message translates to:
  /// **'Catalog Sync'**
  String get adminCatalogSync;

  /// No description provided for @adminLastSuccessfulSync.
  ///
  /// In en, this message translates to:
  /// **'Last successful sync'**
  String get adminLastSuccessfulSync;

  /// No description provided for @adminProductsImported.
  ///
  /// In en, this message translates to:
  /// **'Products imported'**
  String get adminProductsImported;

  /// No description provided for @adminProductsSkipped.
  ///
  /// In en, this message translates to:
  /// **'Products skipped'**
  String get adminProductsSkipped;

  /// No description provided for @adminProductsProcessed.
  ///
  /// In en, this message translates to:
  /// **'Rows processed'**
  String get adminProductsProcessed;

  /// No description provided for @adminSyncDuration.
  ///
  /// In en, this message translates to:
  /// **'Sync duration'**
  String get adminSyncDuration;

  /// No description provided for @adminSyncCatalogButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Catalog'**
  String get adminSyncCatalogButton;

  /// No description provided for @adminSyncOpensGithub.
  ///
  /// In en, this message translates to:
  /// **'Opens GitHub Actions to run the sync workflow.'**
  String get adminSyncOpensGithub;

  /// No description provided for @adminSyncLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the sync page. Try again.'**
  String get adminSyncLinkFailed;

  /// No description provided for @adminRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get adminRecentActivity;

  /// No description provided for @adminActivityStarted.
  ///
  /// In en, this message translates to:
  /// **'Catalog sync started'**
  String get adminActivityStarted;

  /// No description provided for @adminActivityCompleted.
  ///
  /// In en, this message translates to:
  /// **'Catalog sync completed'**
  String get adminActivityCompleted;

  /// No description provided for @adminActivityFailedEvent.
  ///
  /// In en, this message translates to:
  /// **'Catalog sync failed'**
  String get adminActivityFailedEvent;

  /// No description provided for @adminNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get adminNoActivityTitle;

  /// No description provided for @adminNoActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync activity will appear here after your first catalog sync.'**
  String get adminNoActivityDesc;

  /// No description provided for @adminJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get adminJustNow;

  /// No description provided for @adminMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute ago} other{{count} minutes ago}}'**
  String adminMinutesAgo(int count);

  /// No description provided for @adminHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String adminHoursAgo(int count);

  /// No description provided for @adminDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String adminDaysAgo(int count);

  /// No description provided for @adminQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get adminQuickActions;

  /// No description provided for @adminViewProducts.
  ///
  /// In en, this message translates to:
  /// **'View Products'**
  String get adminViewProducts;

  /// No description provided for @adminViewUsers.
  ///
  /// In en, this message translates to:
  /// **'View Users'**
  String get adminViewUsers;

  /// No description provided for @adminNoProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get adminNoProductsTitle;

  /// No description provided for @adminNoProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Your catalog will appear here after the first successful Awin sync.'**
  String get adminNoProductsDesc;

  /// No description provided for @adminSyncFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while updating the catalog. Please try again.'**
  String get adminSyncFailedDesc;

  /// No description provided for @adminCatalogSyncedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Catalog synced successfully.'**
  String get adminCatalogSyncedSuccess;

  /// No description provided for @adminSyncedProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products updated.'**
  String adminSyncedProductsCount(int count);

  /// No description provided for @adminAffiliatePlatforms.
  ///
  /// In en, this message translates to:
  /// **'Affiliate Platforms'**
  String get adminAffiliatePlatforms;

  /// No description provided for @adminPlatformsDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected integrations'**
  String get adminPlatformsDesc;

  /// No description provided for @adminPlatformActivity.
  ///
  /// In en, this message translates to:
  /// **'Platform activity'**
  String get adminPlatformActivity;

  /// No description provided for @adminNoHistoricalActivity.
  ///
  /// In en, this message translates to:
  /// **'No historical activity data available yet.'**
  String get adminNoHistoricalActivity;

  /// No description provided for @adminRecentUsers.
  ///
  /// In en, this message translates to:
  /// **'Recent Users'**
  String get adminRecentUsers;

  /// No description provided for @adminNoUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No users yet'**
  String get adminNoUsersYet;

  /// No description provided for @adminJoinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String adminJoinedOn(String date);

  /// No description provided for @adminStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get adminStatusVerified;

  /// No description provided for @adminStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get adminStatusUnverified;

  /// No description provided for @adminUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage ROSIVA users'**
  String get adminUsersSubtitle;

  /// No description provided for @adminSearchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get adminSearchUsersHint;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get adminActiveUsers;

  /// No description provided for @adminActiveUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Signed in within the last 30 days'**
  String get adminActiveUsersDesc;

  /// No description provided for @adminUserDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get adminUserDetails;

  /// No description provided for @adminDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDeleteUser;

  /// No description provided for @adminDeleteNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Deleting users isn\'t available yet.'**
  String get adminDeleteNotAvailable;

  /// No description provided for @adminUserListRestricted.
  ///
  /// In en, this message translates to:
  /// **'Full user list requires an additional Firestore permission that hasn\'t been enabled yet.'**
  String get adminUserListRestricted;

  /// No description provided for @adminNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoUsersFound;

  /// No description provided for @adminNoUsersFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term.'**
  String get adminNoUsersFoundDesc;

  /// No description provided for @adminProductsScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage the ROSIVA beauty catalog'**
  String get adminProductsScreenSubtitle;

  /// No description provided for @adminSearchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get adminSearchProductsHint;

  /// No description provided for @adminInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get adminInStock;

  /// No description provided for @adminOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get adminOutOfStock;

  /// No description provided for @adminPlatformsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Affiliate Platforms'**
  String get adminPlatformsScreenTitle;

  /// No description provided for @adminPlatformsScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your connected affiliate ecosystem'**
  String get adminPlatformsScreenSubtitle;

  /// No description provided for @adminPlatformConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get adminPlatformConnected;

  /// No description provided for @adminPlatformNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get adminPlatformNotConnected;

  /// No description provided for @adminCatalogActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminCatalogActive;

  /// No description provided for @adminCatalogInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminCatalogInactive;

  /// No description provided for @adminComingSoonPlatform.
  ///
  /// In en, this message translates to:
  /// **'More platforms coming soon'**
  String get adminComingSoonPlatform;

  /// No description provided for @adminSettingsScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your admin preferences'**
  String get adminSettingsScreenSubtitle;

  /// No description provided for @adminSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get adminSectionAccount;

  /// No description provided for @adminSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get adminSectionAppearance;

  /// No description provided for @adminNotificationsComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Admin notifications aren\'t available yet.'**
  String get adminNotificationsComingSoonDesc;

  /// No description provided for @adminNewUsers.
  ///
  /// In en, this message translates to:
  /// **'New Users'**
  String get adminNewUsers;

  /// No description provided for @adminNewUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Joined in the last 7 days'**
  String get adminNewUsersDesc;
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
