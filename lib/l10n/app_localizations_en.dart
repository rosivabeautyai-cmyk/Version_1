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
}
