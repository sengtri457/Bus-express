import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Bus Express'**
  String get appTitle;

  /// Splash screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Premium Travel Made Simple'**
  String get appSplashSubtitle;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue booking'**
  String get signInSubtitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account has been {status}. Please contact support.'**
  String accountSuspended(String status);

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not launch Google sign-in. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @googleSignInError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleSignInError;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordMinLength8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength8;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us and book your rides easily'**
  String get signupSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name too short'**
  String get nameTooShort;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+855 12 345 678'**
  String get phoneNumberHint;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhone;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailAddressHint;

  /// No description provided for @atLeast8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Chars;

  /// No description provided for @includeUppercase.
  ///
  /// In en, this message translates to:
  /// **'Include at least one uppercase letter'**
  String get includeUppercase;

  /// No description provided for @includeNumber.
  ///
  /// In en, this message translates to:
  /// **'Include at least one number'**
  String get includeNumber;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get confirmPasswordHint;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @iAgreeTo.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeTo;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @andConjunction.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andConjunction;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLink;

  /// No description provided for @stepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get stepPersonal;

  /// No description provided for @stepAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get stepAccount;

  /// No description provided for @passwordStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrengthLabel;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @passwordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordFair;

  /// No description provided for @passwordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordGood;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// No description provided for @passwordStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Use 8+ characters, uppercase, numbers & symbols for strong password'**
  String get passwordStrengthHint;

  /// No description provided for @agreeTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms & Conditions'**
  String get agreeTermsError;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreatedTitle;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to\n{email}\n\nPlease verify your email before signing in.'**
  String verificationSent(String email);

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email and we\'ll send you a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLoginLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a password reset link to\n{email}'**
  String resetLinkSent(String email);

  /// No description provided for @infoStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the email we sent you'**
  String get infoStep1;

  /// No description provided for @infoStep2.
  ///
  /// In en, this message translates to:
  /// **'Click the \"Reset Password\" link'**
  String get infoStep2;

  /// No description provided for @infoStep3.
  ///
  /// In en, this message translates to:
  /// **'Create a new strong password'**
  String get infoStep3;

  /// No description provided for @didNotReceiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email?'**
  String get didNotReceiveEmail;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @resendInCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInCountdown(int seconds);

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from your previous password.'**
  String get setNewPasswordSubtitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get confirmNewPasswordHint;

  /// No description provided for @passwordsDoNotMatchValidator.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchValidator;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @enterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmailAddress;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset!'**
  String get passwordResetTitle;

  /// No description provided for @passwordResetBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated successfully. Please sign in with your new password.'**
  String get passwordResetBody;

  /// No description provided for @navBookBus.
  ///
  /// In en, this message translates to:
  /// **'Book Bus'**
  String get navBookBus;

  /// No description provided for @navMyTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get navMyTickets;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get navRoutes;

  /// No description provided for @navBuses.
  ///
  /// In en, this message translates to:
  /// **'Buses'**
  String get navBuses;

  /// No description provided for @navSchedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get navSchedules;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// No description provided for @navOperators.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get navOperators;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @homeHelloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeHelloName(String name);

  /// No description provided for @homeWhereGoing.
  ///
  /// In en, this message translates to:
  /// **'Where are you going today?'**
  String get homeWhereGoing;

  /// No description provided for @homeOurPartners.
  ///
  /// In en, this message translates to:
  /// **'Our Partners'**
  String get homeOurPartners;

  /// No description provided for @homePopularRoutes.
  ///
  /// In en, this message translates to:
  /// **'Popular Routes'**
  String get homePopularRoutes;

  /// No description provided for @homeOriginLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get homeOriginLabel;

  /// No description provided for @homeOriginHint.
  ///
  /// In en, this message translates to:
  /// **'From where?'**
  String get homeOriginHint;

  /// No description provided for @homeDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get homeDestinationLabel;

  /// No description provided for @homeDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get homeDestinationHint;

  /// No description provided for @homeTravelDate.
  ///
  /// In en, this message translates to:
  /// **'Travel Date'**
  String get homeTravelDate;

  /// No description provided for @homeSearchBuses.
  ///
  /// In en, this message translates to:
  /// **'Search Buses'**
  String get homeSearchBuses;

  /// No description provided for @homeErrorOriginDestination.
  ///
  /// In en, this message translates to:
  /// **'Please enter origin and destination'**
  String get homeErrorOriginDestination;

  /// No description provided for @homeNoOperators.
  ///
  /// In en, this message translates to:
  /// **'No operators available at the moment'**
  String get homeNoOperators;

  /// No description provided for @profileMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileMyProfile;

  /// No description provided for @profileErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String profileErrorLoading(String error);

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String profileFailedUpdate(String error);

  /// No description provided for @profilePasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get profilePasswordUpdated;

  /// No description provided for @profileFailedPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password: {error}'**
  String profileFailedPassword(String error);

  /// No description provided for @profileErrorSignOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String profileErrorSignOut(String error);

  /// No description provided for @profilePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get profilePersonalDetails;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullNameLabel;

  /// No description provided for @profileFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profileFullNameHint;

  /// No description provided for @profileSaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get profileSaveDetails;

  /// No description provided for @profileSecurityPassword.
  ///
  /// In en, this message translates to:
  /// **'Security & Password'**
  String get profileSecurityPassword;

  /// No description provided for @profileUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get profileUpdatePassword;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @scheduleSelectSeat.
  ///
  /// In en, this message translates to:
  /// **'Select Seat'**
  String get scheduleSelectSeat;

  /// No description provided for @schedulePleaseSelectSeat.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one seat'**
  String get schedulePleaseSelectSeat;

  /// No description provided for @scheduleAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get scheduleAvailable;

  /// No description provided for @scheduleSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get scheduleSelected;

  /// No description provided for @scheduleBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get scheduleBooked;

  /// No description provided for @scheduleTripEnded.
  ///
  /// In en, this message translates to:
  /// **'This trip has ended / is completed.'**
  String get scheduleTripEnded;

  /// No description provided for @scheduleTripCancelled.
  ///
  /// In en, this message translates to:
  /// **'This trip has been cancelled.'**
  String get scheduleTripCancelled;

  /// No description provided for @scheduleTripOver.
  ///
  /// In en, this message translates to:
  /// **'This trip is over / has departed (Time over).'**
  String get scheduleTripOver;

  /// No description provided for @scheduleNoSeatSelected.
  ///
  /// In en, this message translates to:
  /// **'No seat selected'**
  String get scheduleNoSeatSelected;

  /// No description provided for @scheduleSeatCount.
  ///
  /// In en, this message translates to:
  /// **'{count} seat(s): {seats}'**
  String scheduleSeatCount(int count, String seats);

  /// No description provided for @scheduleContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get scheduleContinue;

  /// No description provided for @scheduleFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'FRONT'**
  String get scheduleFrontLabel;

  /// No description provided for @scheduleDoorLabel.
  ///
  /// In en, this message translates to:
  /// **'DOOR'**
  String get scheduleDoorLabel;

  /// No description provided for @scheduleSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} seats left'**
  String scheduleSeatsLeft(int count);

  /// No description provided for @scheduleBackLabel.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get scheduleBackLabel;

  /// No description provided for @bookingConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get bookingConfirmTitle;

  /// No description provided for @bookingTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get bookingTripDetails;

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bookingDate;

  /// No description provided for @bookingSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get bookingSeats;

  /// No description provided for @bookingBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bookingBus;

  /// No description provided for @bookingPassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get bookingPassenger;

  /// No description provided for @bookingUseSavedInfo.
  ///
  /// In en, this message translates to:
  /// **'Use saved info'**
  String get bookingUseSavedInfo;

  /// No description provided for @bookingEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get bookingEnterFullName;

  /// No description provided for @bookingAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get bookingAgeLabel;

  /// No description provided for @bookingEnterAge.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get bookingEnterAge;

  /// No description provided for @bookingEnterValidAge.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age'**
  String get bookingEnterValidAge;

  /// No description provided for @bookingPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get bookingPhoneLabel;

  /// No description provided for @bookingPhoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Include country code (e.g. +1XXXXXXXXX) for OTP'**
  String get bookingPhoneHelper;

  /// No description provided for @bookingEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get bookingEnterPhone;

  /// No description provided for @bookingIncludeCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Include country code (e.g. +1XXXXXXXXX)'**
  String get bookingIncludeCountryCode;

  /// No description provided for @bookingEnterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number (8–15 digits)'**
  String get bookingEnterValidPhone;

  /// No description provided for @bookingNationalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get bookingNationalityLabel;

  /// No description provided for @bookingEnterNationality.
  ///
  /// In en, this message translates to:
  /// **'Enter your nationality'**
  String get bookingEnterNationality;

  /// No description provided for @bookingEmailHolder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get bookingEmailHolder;

  /// No description provided for @bookingEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Receipt will be sent here'**
  String get bookingEmailHelper;

  /// No description provided for @bookingEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get bookingEnterValidEmail;

  /// No description provided for @bookingDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Your details are saved for future bookings'**
  String get bookingDetailsSaved;

  /// No description provided for @bookingPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get bookingPayment;

  /// No description provided for @bookingPromoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get bookingPromoCodeHint;

  /// No description provided for @bookingPromoCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a promo code'**
  String get bookingPromoCodeRequired;

  /// No description provided for @bookingPromoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code'**
  String get bookingPromoInvalid;

  /// No description provided for @bookingPromoInactive.
  ///
  /// In en, this message translates to:
  /// **'This promo code is no longer active'**
  String get bookingPromoInactive;

  /// No description provided for @bookingPromoExpired.
  ///
  /// In en, this message translates to:
  /// **'This promo code has expired'**
  String get bookingPromoExpired;

  /// No description provided for @bookingMinPurchase.
  ///
  /// In en, this message translates to:
  /// **'Minimum purchase of {amount} required'**
  String bookingMinPurchase(String amount);

  /// No description provided for @bookingPromoMaxUsage.
  ///
  /// In en, this message translates to:
  /// **'This promo code has reached its usage limit'**
  String get bookingPromoMaxUsage;

  /// No description provided for @bookingPromoPerUser.
  ///
  /// In en, this message translates to:
  /// **'You have used this promo code {used} out of {max} times'**
  String bookingPromoPerUser(int used, int max);

  /// No description provided for @bookingPromoPercentage.
  ///
  /// In en, this message translates to:
  /// **'{value}% OFF'**
  String bookingPromoPercentage(String value);

  /// No description provided for @bookingPromoFixed.
  ///
  /// In en, this message translates to:
  /// **'\${value} OFF'**
  String bookingPromoFixed(String value);

  /// No description provided for @bookingPromoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to validate promo code'**
  String get bookingPromoFailed;

  /// No description provided for @bookingPromoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get bookingPromoRemove;

  /// No description provided for @bookingPromoApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get bookingPromoApply;

  /// No description provided for @bookingPricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'Price per seat'**
  String get bookingPricePerSeat;

  /// No description provided for @bookingNumberOfSeats.
  ///
  /// In en, this message translates to:
  /// **'Number of seats'**
  String get bookingNumberOfSeats;

  /// No description provided for @bookingDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get bookingDiscount;

  /// No description provided for @bookingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// No description provided for @bookingNotice.
  ///
  /// In en, this message translates to:
  /// **'Arrive 15 minutes before departure. Show your QR ticket to the conductor when boarding.'**
  String get bookingNotice;

  /// No description provided for @bookingInvalidPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format.'**
  String get bookingInvalidPhoneFormat;

  /// No description provided for @bookingInvalidPhoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number. Enter a real number with correct country code (e.g. +1234567890).'**
  String get bookingInvalidPhoneMessage;

  /// No description provided for @bookingInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get bookingInvalidEmail;

  /// No description provided for @bookingTripDeparted.
  ///
  /// In en, this message translates to:
  /// **'already departed'**
  String get bookingTripDeparted;

  /// No description provided for @bookingTripEnded.
  ///
  /// In en, this message translates to:
  /// **'already ended'**
  String get bookingTripEnded;

  /// No description provided for @bookingTripCancelled.
  ///
  /// In en, this message translates to:
  /// **'been cancelled'**
  String get bookingTripCancelled;

  /// No description provided for @bookingTripNotBookable.
  ///
  /// In en, this message translates to:
  /// **'This trip has {reason} and cannot be booked.'**
  String bookingTripNotBookable(String reason);

  /// No description provided for @bookingFailedCreateTrip.
  ///
  /// In en, this message translates to:
  /// **'Failed to create trip. Check RLS policies on trips table.'**
  String get bookingFailedCreateTrip;

  /// No description provided for @bookingFailedCreateBooking.
  ///
  /// In en, this message translates to:
  /// **'Failed to create booking for seat {seat}. Check RLS policies on bookings table.'**
  String bookingFailedCreateBooking(String seat);

  /// No description provided for @bookingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingNotificationTitle;

  /// No description provided for @bookingNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{count} seat(s) on {origin} → {destination} ({time})'**
  String bookingNotificationBody(
    int count,
    String origin,
    String destination,
    String time,
  );

  /// No description provided for @bookingFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Booking failed: {message}'**
  String bookingFailedGeneric(String message);

  /// No description provided for @bookingReceiptSent.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to your email'**
  String get bookingReceiptSent;

  /// No description provided for @bookingConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get bookingConfirmButton;

  /// No description provided for @bookingConfirmCountSeats.
  ///
  /// In en, this message translates to:
  /// **'Confirm {count} Seats'**
  String bookingConfirmCountSeats(int count);

  /// No description provided for @liveTrackingAppBar.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTrackingAppBar;

  /// No description provided for @liveTripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found. It may have been cancelled.'**
  String get liveTripNotFound;

  /// No description provided for @liveCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load tracking data. Check your connection.'**
  String get liveCouldNotLoad;

  /// No description provided for @liveSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get liveSomethingWrong;

  /// No description provided for @liveRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get liveRetry;

  /// No description provided for @liveTooltipFollowBus.
  ///
  /// In en, this message translates to:
  /// **'Follow bus'**
  String get liveTooltipFollowBus;

  /// No description provided for @liveTooltipFollowingBus.
  ///
  /// In en, this message translates to:
  /// **'Following bus'**
  String get liveTooltipFollowingBus;

  /// No description provided for @liveTripNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip Not Started Yet'**
  String get liveTripNotStarted;

  /// No description provided for @liveTripNotStartedDesc.
  ///
  /// In en, this message translates to:
  /// **'The bus will appear on the map once the driver starts the trip.'**
  String get liveTripNotStartedDesc;

  /// No description provided for @liveStatusOnWay.
  ///
  /// In en, this message translates to:
  /// **'Bus is on the way'**
  String get liveStatusOnWay;

  /// No description provided for @liveStatusLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating bus...'**
  String get liveStatusLocating;

  /// No description provided for @liveStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get liveStatusCompleted;

  /// No description provided for @liveStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get liveStatusCancelled;

  /// No description provided for @liveStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for departure'**
  String get liveStatusWaiting;

  /// No description provided for @liveDepartedAt.
  ///
  /// In en, this message translates to:
  /// **'Departed at {time}'**
  String liveDepartedAt(String time);

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveBadge;

  /// No description provided for @liveBusLocation.
  ///
  /// In en, this message translates to:
  /// **'Bus Location'**
  String get liveBusLocation;

  /// No description provided for @liveScheduledSchedule.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Schedule'**
  String get liveScheduledSchedule;

  /// No description provided for @liveEstimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get liveEstimatedArrival;

  /// No description provided for @liveDelayMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{delay} min'**
  String liveDelayMinutes(int delay);

  /// No description provided for @liveUpdatesEvery5.
  ///
  /// In en, this message translates to:
  /// **'Location updates every 5 seconds'**
  String get liveUpdatesEvery5;

  /// No description provided for @liveTrackingStarts.
  ///
  /// In en, this message translates to:
  /// **'Tracking starts when driver departs'**
  String get liveTrackingStarts;

  /// No description provided for @liveIncidentReported.
  ///
  /// In en, this message translates to:
  /// **'{Type} Reported'**
  String liveIncidentReported(String Type);

  /// No description provided for @myTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTicketsTitle;

  /// No description provided for @myTicketsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({count})'**
  String myTicketsUpcoming(int count);

  /// No description provided for @myTicketsPast.
  ///
  /// In en, this message translates to:
  /// **'Past ({count})'**
  String myTicketsPast(int count);

  /// No description provided for @myTicketsNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips'**
  String get myTicketsNoUpcoming;

  /// No description provided for @myTicketsNoUpcomingSub.
  ///
  /// In en, this message translates to:
  /// **'Book a bus ticket to see it here'**
  String get myTicketsNoUpcomingSub;

  /// No description provided for @myTicketsNoPast.
  ///
  /// In en, this message translates to:
  /// **'No past trips'**
  String get myTicketsNoPast;

  /// No description provided for @myTicketsNoPastSub.
  ///
  /// In en, this message translates to:
  /// **'Your completed trips will appear here'**
  String get myTicketsNoPastSub;

  /// No description provided for @myTicketsSuccessSingular.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed!'**
  String get myTicketsSuccessSingular;

  /// No description provided for @myTicketsSuccessPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} Seats Confirmed!'**
  String myTicketsSuccessPlural(int count);

  /// No description provided for @myTicketsSuccessDescSingular.
  ///
  /// In en, this message translates to:
  /// **'Your ticket is ready. Show the QR code to the conductor when boarding.'**
  String get myTicketsSuccessDescSingular;

  /// No description provided for @myTicketsSuccessDescPlural.
  ///
  /// In en, this message translates to:
  /// **'Your {count} tickets are ready. Each seat has its own QR code.'**
  String myTicketsSuccessDescPlural(int count);

  /// No description provided for @myTicketsViewSingular.
  ///
  /// In en, this message translates to:
  /// **'View My Ticket'**
  String get myTicketsViewSingular;

  /// No description provided for @myTicketsViewPlural.
  ///
  /// In en, this message translates to:
  /// **'View My Tickets'**
  String get myTicketsViewPlural;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptBusExpress.
  ///
  /// In en, this message translates to:
  /// **'BUS EXPRESS'**
  String get receiptBusExpress;

  /// No description provided for @receiptOfficial.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL RECEIPT'**
  String get receiptOfficial;

  /// No description provided for @receiptReceiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt #'**
  String get receiptReceiptNo;

  /// No description provided for @receiptIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get receiptIssued;

  /// No description provided for @receiptRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get receiptRoute;

  /// No description provided for @receiptDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get receiptDeparture;

  /// No description provided for @receiptBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get receiptBookingDetails;

  /// No description provided for @receiptTableSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get receiptTableSeat;

  /// No description provided for @receiptTableStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get receiptTableStatus;

  /// No description provided for @receiptTablePrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get receiptTablePrice;

  /// No description provided for @receiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: '**
  String get receiptTotal;

  /// No description provided for @receiptThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for traveling with Bus Express!'**
  String get receiptThankYou;

  /// No description provided for @receiptKeepRecord.
  ///
  /// In en, this message translates to:
  /// **'This is your official receipt. Please keep it for your records.'**
  String get receiptKeepRecord;

  /// No description provided for @receiptShare.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt (PDF)'**
  String get receiptShare;

  /// No description provided for @receiptGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get receiptGenerating;

  /// No description provided for @promotionsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Promotions'**
  String get promotionsTitle;

  /// No description provided for @promotionsCopied.
  ///
  /// In en, this message translates to:
  /// **'Promo code \"{code}\" copied!'**
  String promotionsCopied(String code);

  /// No description provided for @promotionsNoPromotions.
  ///
  /// In en, this message translates to:
  /// **'No promotions available right now'**
  String get promotionsNoPromotions;

  /// No description provided for @promotionsNoPromotionsSub.
  ///
  /// In en, this message translates to:
  /// **'Check back later for exciting offers!'**
  String get promotionsNoPromotionsSub;

  /// No description provided for @promotionsMinPurchase.
  ///
  /// In en, this message translates to:
  /// **'Min. purchase: {amount}'**
  String promotionsMinPurchase(String amount);

  /// No description provided for @cancelSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking?'**
  String get cancelSheetTitle;

  /// No description provided for @cancelSheetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your trip?'**
  String get cancelSheetConfirm;

  /// No description provided for @cancelSheetRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get cancelSheetRoute;

  /// No description provided for @cancelSheetSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get cancelSheetSeat;

  /// No description provided for @cancelSheetAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get cancelSheetAmount;

  /// No description provided for @cancelSheetPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellations must be made at least 2 hours before departure. Trips already in progress cannot be cancelled.'**
  String get cancelSheetPolicy;

  /// No description provided for @cancelSheetKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep Booking'**
  String get cancelSheetKeep;

  /// No description provided for @cancelSheetYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get cancelSheetYesCancel;

  /// No description provided for @cancelSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get cancelSuccessTitle;

  /// No description provided for @cancelSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your booking for {origin} → {destination} (Seat {seat}) has been cancelled.'**
  String cancelSuccessDesc(String origin, String destination, String seat);

  /// No description provided for @cancelSuccessNote.
  ///
  /// In en, this message translates to:
  /// **'Your booking has been cancelled. If payment was made, the refund will be credited to your wallet.'**
  String get cancelSuccessNote;

  /// No description provided for @cancelSheetDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cancelSheetDone;

  /// No description provided for @offersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers for you'**
  String get offersSectionTitle;

  /// No description provided for @offersViewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get offersViewMore;

  /// No description provided for @offersCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get offersCategoryAll;

  /// No description provided for @offersCategoryBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get offersCategoryBus;

  /// No description provided for @offersCategoryTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get offersCategoryTrain;

  /// No description provided for @offersNoOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers available for this category'**
  String get offersNoOffers;

  /// No description provided for @popularRoutesNoRoutes.
  ///
  /// In en, this message translates to:
  /// **'No routes available yet'**
  String get popularRoutesNoRoutes;

  /// No description provided for @routeSelectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Route'**
  String get routeSelectorTitle;

  /// No description provided for @routeSelectorSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations...'**
  String get routeSelectorSearchHint;

  /// No description provided for @routeSelectorNoRoutes.
  ///
  /// In en, this message translates to:
  /// **'No routes available'**
  String get routeSelectorNoRoutes;

  /// No description provided for @routeSelectorNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No routes match \"{query}\"'**
  String routeSelectorNoMatch(String query);

  /// No description provided for @ticketCardNewBooking.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get ticketCardNewBooking;

  /// No description provided for @ticketCardSeats.
  ///
  /// In en, this message translates to:
  /// **'{count} seats'**
  String ticketCardSeats(int count);

  /// No description provided for @ticketCardTrackLive.
  ///
  /// In en, this message translates to:
  /// **'Track Live'**
  String get ticketCardTrackLive;

  /// No description provided for @ticketCardTrackBus.
  ///
  /// In en, this message translates to:
  /// **'Track Bus'**
  String get ticketCardTrackBus;

  /// No description provided for @ticketCardViewQrSingular.
  ///
  /// In en, this message translates to:
  /// **'Tap to view QR code'**
  String get ticketCardViewQrSingular;

  /// No description provided for @ticketCardViewQrPlural.
  ///
  /// In en, this message translates to:
  /// **'Tap to view {count} QR codes'**
  String ticketCardViewQrPlural(int count);

  /// No description provided for @ticketCardViewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get ticketCardViewReceipt;

  /// No description provided for @ticketDetailTrackLive.
  ///
  /// In en, this message translates to:
  /// **'Track Live'**
  String get ticketDetailTrackLive;

  /// No description provided for @ticketDetailTrackBus.
  ///
  /// In en, this message translates to:
  /// **'Track Bus'**
  String get ticketDetailTrackBus;

  /// No description provided for @ticketDetailCancelTooLate.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel — departure is less than 2 hours away.'**
  String get ticketDetailCancelTooLate;

  /// No description provided for @ticketDetailCancelledSingular.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get ticketDetailCancelledSingular;

  /// No description provided for @ticketDetailCancelledPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} bookings cancelled'**
  String ticketDetailCancelledPlural(int count);

  /// No description provided for @ticketDetailErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String ticketDetailErrorPrefix(String error);

  /// No description provided for @ticketDetailConfirmCancelTitleSingular.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking?'**
  String get ticketDetailConfirmCancelTitleSingular;

  /// No description provided for @ticketDetailConfirmCancelTitlePlural.
  ///
  /// In en, this message translates to:
  /// **'Cancel {count} Seats?'**
  String ticketDetailConfirmCancelTitlePlural(int count);

  /// No description provided for @ticketDetailConfirmPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellations must be made at least 2 hours before departure.'**
  String get ticketDetailConfirmPolicy;

  /// No description provided for @ticketDetailKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep It'**
  String get ticketDetailKeepIt;

  /// No description provided for @ticketDetailYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get ticketDetailYesCancel;

  /// No description provided for @ticketDetailSeatCount.
  ///
  /// In en, this message translates to:
  /// **'{count} seat(s)'**
  String ticketDetailSeatCount(int count);

  /// No description provided for @ticketDetailTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String ticketDetailTotal(String amount);

  /// No description provided for @ticketDetailCancelAll.
  ///
  /// In en, this message translates to:
  /// **'Cancel All {count} Seats'**
  String ticketDetailCancelAll(int count);

  /// No description provided for @ticketDetailCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get ticketDetailCancelBooking;

  /// No description provided for @ticketDetailSeatTab.
  ///
  /// In en, this message translates to:
  /// **'Seat {seat}'**
  String ticketDetailSeatTab(String seat);

  /// No description provided for @ticketDetailDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get ticketDetailDeparture;

  /// No description provided for @ticketDetailArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get ticketDetailArrival;

  /// No description provided for @ticketDetailTicketPrice.
  ///
  /// In en, this message translates to:
  /// **'Ticket price'**
  String get ticketDetailTicketPrice;

  /// No description provided for @ticketDetailPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get ticketDetailPayment;

  /// No description provided for @ticketDetailQrError.
  ///
  /// In en, this message translates to:
  /// **'QR Error'**
  String get ticketDetailQrError;

  /// No description provided for @ticketDetailStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Ticket already used'**
  String get ticketDetailStatusUsed;

  /// No description provided for @ticketDetailStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ticket cancelled'**
  String get ticketDetailStatusCancelled;

  /// No description provided for @ticketDetailStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Ticket expired'**
  String get ticketDetailStatusExpired;

  /// No description provided for @ticketDetailStatusNoData.
  ///
  /// In en, this message translates to:
  /// **'No ticket data'**
  String get ticketDetailStatusNoData;

  /// No description provided for @ticketDetailInfoValid.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to the conductor when boarding.'**
  String get ticketDetailInfoValid;

  /// No description provided for @ticketDetailInfoUsed.
  ///
  /// In en, this message translates to:
  /// **'This ticket has already been used for boarding.'**
  String get ticketDetailInfoUsed;

  /// No description provided for @ticketDetailInfoCancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking has been cancelled.'**
  String get ticketDetailInfoCancelled;

  /// No description provided for @ticketDetailInfoExpired.
  ///
  /// In en, this message translates to:
  /// **'This ticket has expired.'**
  String get ticketDetailInfoExpired;

  /// No description provided for @ticketDetailInfoUnknown.
  ///
  /// In en, this message translates to:
  /// **'Ticket status is unknown.'**
  String get ticketDetailInfoUnknown;

  /// No description provided for @cancelServiceSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled successfully.'**
  String get cancelServiceSuccess;

  /// No description provided for @cancelServiceTooLate.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel — departure is less than 2 hours away.'**
  String get cancelServiceTooLate;

  /// No description provided for @cancelServiceAlreadyBoarded.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel — you have already boarded this bus.'**
  String get cancelServiceAlreadyBoarded;

  /// No description provided for @cancelServiceAlreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking is already cancelled.'**
  String get cancelServiceAlreadyCancelled;

  /// No description provided for @cancelServiceTripStarted.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel — the trip has already started or completed.'**
  String get cancelServiceTripStarted;

  /// No description provided for @cancelServiceError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get cancelServiceError;

  /// No description provided for @driverHomeHello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String driverHomeHello(String name);

  /// No description provided for @driverHomeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Driver Dashboard'**
  String get driverHomeDashboard;

  /// No description provided for @driverHomeTodaysTrip.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Trip'**
  String get driverHomeTodaysTrip;

  /// No description provided for @driverHomeNoTripToday.
  ///
  /// In en, this message translates to:
  /// **'No trip today'**
  String get driverHomeNoTripToday;

  /// No description provided for @driverHomeNoTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have no scheduled trips for today'**
  String get driverHomeNoTripSubtitle;

  /// No description provided for @driverHomeUpcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trips'**
  String get driverHomeUpcomingTrips;

  /// No description provided for @driverHomeQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get driverHomeQuickStats;

  /// No description provided for @driverHomeStatTotalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get driverHomeStatTotalTrips;

  /// No description provided for @driverHomeStatCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get driverHomeStatCompleted;

  /// No description provided for @driverHomeStatPassengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get driverHomeStatPassengers;

  /// No description provided for @driverHomeFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get driverHomeFailedLoad;

  /// No description provided for @driverHomeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get driverHomeRetry;

  /// No description provided for @driverTripAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Management'**
  String get driverTripAppBarTitle;

  /// No description provided for @driverTripReportIncident.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get driverTripReportIncident;

  /// No description provided for @driverTripRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get driverTripRouteLabel;

  /// No description provided for @driverTripBusLabel.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get driverTripBusLabel;

  /// No description provided for @driverTripDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get driverTripDateLabel;

  /// No description provided for @driverTripStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to Depart'**
  String get driverTripStatusReady;

  /// No description provided for @driverTripStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip In Progress'**
  String get driverTripStatusInProgress;

  /// No description provided for @driverTripStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get driverTripStatusCompleted;

  /// No description provided for @driverTripStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip Cancelled'**
  String get driverTripStatusCancelled;

  /// No description provided for @driverTripStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get driverTripStatusUnknown;

  /// No description provided for @driverTripDepartedAt.
  ///
  /// In en, this message translates to:
  /// **'Departed at {time}'**
  String driverTripDepartedAt(String time);

  /// No description provided for @driverTripArrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String driverTripArrivedAt(String time);

  /// No description provided for @driverTripTapStart.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Start Trip\" when ready'**
  String get driverTripTapStart;

  /// No description provided for @driverTripGpsActive.
  ///
  /// In en, this message translates to:
  /// **'GPS Tracking Active'**
  String get driverTripGpsActive;

  /// No description provided for @driverTripPassengersTitle.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get driverTripPassengersTitle;

  /// No description provided for @driverTripPassengerCount.
  ///
  /// In en, this message translates to:
  /// **'{boarded}/{total} boarded'**
  String driverTripPassengerCount(int boarded, int total);

  /// No description provided for @driverTripNoPassengers.
  ///
  /// In en, this message translates to:
  /// **'No passengers booked yet'**
  String get driverTripNoPassengers;

  /// No description provided for @driverTripSeatInfo.
  ///
  /// In en, this message translates to:
  /// **'Seat {number} • {phone}'**
  String driverTripSeatInfo(String number, String phone);

  /// No description provided for @driverTripUnknownPassenger.
  ///
  /// In en, this message translates to:
  /// **'Unknown Passenger'**
  String get driverTripUnknownPassenger;

  /// No description provided for @driverTripStartTripBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get driverTripStartTripBtn;

  /// No description provided for @driverTripEndTripArrivedBtn.
  ///
  /// In en, this message translates to:
  /// **'End Trip (Arrived)'**
  String get driverTripEndTripArrivedBtn;

  /// No description provided for @driverTripEndTripCountdown.
  ///
  /// In en, this message translates to:
  /// **'End Trip (ready in {countdown})'**
  String driverTripEndTripCountdown(String countdown);

  /// No description provided for @driverTripStartDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get driverTripStartDialogTitle;

  /// No description provided for @driverTripStartDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you ready to depart? This will notify all passengers.'**
  String get driverTripStartDialogMessage;

  /// No description provided for @driverTripStartNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get driverTripStartNowLabel;

  /// No description provided for @driverTripEndDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'End Trip'**
  String get driverTripEndDialogTitle;

  /// No description provided for @driverTripEndDialogMessageDelay.
  ///
  /// In en, this message translates to:
  /// **'Trip was delayed by {delay} min due to incidents. Confirm arrival?'**
  String driverTripEndDialogMessageDelay(int delay);

  /// No description provided for @driverTripEndDialogMessageNormal.
  ///
  /// In en, this message translates to:
  /// **'Confirm you have arrived at the destination?'**
  String get driverTripEndDialogMessageNormal;

  /// No description provided for @driverTripEndTripLabel.
  ///
  /// In en, this message translates to:
  /// **'End Trip'**
  String get driverTripEndTripLabel;

  /// No description provided for @driverTripCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get driverTripCancel;

  /// No description provided for @driverTripBusNotFull.
  ///
  /// In en, this message translates to:
  /// **'Bus is not full ({boarded}/{capacity}). Waiting for Conductor permission.'**
  String driverTripBusNotFull(int boarded, int capacity);

  /// No description provided for @driverTripStartedSnack.
  ///
  /// In en, this message translates to:
  /// **'Trip started! GPS tracking active.'**
  String get driverTripStartedSnack;

  /// No description provided for @driverTripFailedStart.
  ///
  /// In en, this message translates to:
  /// **'Failed to start trip: {error}'**
  String driverTripFailedStart(String error);

  /// No description provided for @driverTripWaitCountdown.
  ///
  /// In en, this message translates to:
  /// **'Arrival at {time}. Please wait {countdown} to end the trip.'**
  String driverTripWaitCountdown(String time, String countdown);

  /// No description provided for @driverTripCompletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Trip completed successfully!'**
  String get driverTripCompletedSnack;

  /// No description provided for @driverTripFailedEnd.
  ///
  /// In en, this message translates to:
  /// **'Failed to end trip: {error}'**
  String driverTripFailedEnd(String error);

  /// No description provided for @driverTripNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Started'**
  String get driverTripNotificationTitle;

  /// No description provided for @driverTripNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your bus from {origin} → {destination} has departed! Track it live.'**
  String driverTripNotificationBody(String origin, String destination);

  /// No description provided for @driverTripNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get driverTripNA;

  /// No description provided for @driverTripDelayInfo.
  ///
  /// In en, this message translates to:
  /// **'{delay} min delay ({count} incident(s))'**
  String driverTripDelayInfo(int delay, int count);

  /// No description provided for @driverTripAdjustedEta.
  ///
  /// In en, this message translates to:
  /// **'Adjusted ETA: {time}'**
  String driverTripAdjustedEta(String time);

  /// No description provided for @driverTripOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get driverTripOverdue;

  /// No description provided for @driverTripTimeFallback.
  ///
  /// In en, this message translates to:
  /// **'--:--'**
  String get driverTripTimeFallback;

  /// No description provided for @driverIncidentAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get driverIncidentAppBarTitle;

  /// No description provided for @driverIncidentHeaderWarning.
  ///
  /// In en, this message translates to:
  /// **'Report any incidents that affect this trip immediately. Your report will be sent to the operator.'**
  String get driverIncidentHeaderWarning;

  /// No description provided for @driverIncidentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Incident Type'**
  String get driverIncidentTypeLabel;

  /// No description provided for @driverIncidentTypeDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get driverIncidentTypeDelay;

  /// No description provided for @driverIncidentTypeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get driverIncidentTypeBreakdown;

  /// No description provided for @driverIncidentTypeAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get driverIncidentTypeAccident;

  /// No description provided for @driverIncidentTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get driverIncidentTypeOther;

  /// No description provided for @driverIncidentLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Incident Location'**
  String get driverIncidentLocationLabel;

  /// No description provided for @driverIncidentDetectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting location...'**
  String get driverIncidentDetectingLocation;

  /// No description provided for @driverIncidentAccessingGps.
  ///
  /// In en, this message translates to:
  /// **'Accessing GPS...'**
  String get driverIncidentAccessingGps;

  /// No description provided for @driverIncidentGpsDenied.
  ///
  /// In en, this message translates to:
  /// **'GPS Permission Denied'**
  String get driverIncidentGpsDenied;

  /// No description provided for @driverIncidentResolvingAddress.
  ///
  /// In en, this message translates to:
  /// **'Resolving address...'**
  String get driverIncidentResolvingAddress;

  /// No description provided for @driverIncidentUnknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get driverIncidentUnknownLocation;

  /// No description provided for @driverIncidentFailedDetect.
  ///
  /// In en, this message translates to:
  /// **'Failed to detect location'**
  String get driverIncidentFailedDetect;

  /// No description provided for @driverIncidentAutoDetecting.
  ///
  /// In en, this message translates to:
  /// **'Auto-detecting Location...'**
  String get driverIncidentAutoDetecting;

  /// No description provided for @driverIncidentAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected Location'**
  String get driverIncidentAutoDetected;

  /// No description provided for @driverIncidentLocationService.
  ///
  /// In en, this message translates to:
  /// **'Location Service'**
  String get driverIncidentLocationService;

  /// No description provided for @driverIncidentRefreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh Location'**
  String get driverIncidentRefreshLocation;

  /// No description provided for @driverIncidentDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get driverIncidentDescriptionLabel;

  /// No description provided for @driverIncidentHintText.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened in detail...\n\ne.g. \"Bus broke down near Kampong Thom, waiting for repair. Estimated delay: 30 minutes.\"'**
  String get driverIncidentHintText;

  /// No description provided for @driverIncidentSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get driverIncidentSubmitReport;

  /// No description provided for @driverIncidentPleaseDescribe.
  ///
  /// In en, this message translates to:
  /// **'Please describe the incident'**
  String get driverIncidentPleaseDescribe;

  /// No description provided for @driverIncidentNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get driverIncidentNotLoggedIn;

  /// No description provided for @driverIncidentReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Reported'**
  String get driverIncidentReportedTitle;

  /// No description provided for @driverIncidentReportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your incident report has been submitted successfully.'**
  String get driverIncidentReportedMessage;

  /// No description provided for @driverIncidentOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get driverIncidentOK;

  /// No description provided for @driverIncidentFailedError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {message}'**
  String driverIncidentFailedError(String message);

  /// No description provided for @driverIncidentIssueFallback.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get driverIncidentIssueFallback;

  /// No description provided for @driverIncidentPreviousReports.
  ///
  /// In en, this message translates to:
  /// **'Previous Reports This Trip'**
  String get driverIncidentPreviousReports;

  /// No description provided for @driverIncidentNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Alert: {type}'**
  String driverIncidentNotificationTitle(String type);

  /// No description provided for @driverIncidentNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your bus reported a {type}. Estimated delay: {delay} min. We apologize for the inconvenience.'**
  String driverIncidentNotificationBody(String type, int delay);

  /// No description provided for @activeTripAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Trip'**
  String get activeTripAppBarTitle;

  /// No description provided for @activeTripGpsNotStarted.
  ///
  /// In en, this message translates to:
  /// **'GPS not started'**
  String get activeTripGpsNotStarted;

  /// No description provided for @activeTripRequestingPermission.
  ///
  /// In en, this message translates to:
  /// **'Requesting location permission…'**
  String get activeTripRequestingPermission;

  /// No description provided for @activeTripGpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled. Enable it in Settings.'**
  String get activeTripGpsDisabled;

  /// No description provided for @activeTripPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Enable it in Settings.'**
  String get activeTripPermissionDenied;

  /// No description provided for @activeTripPermissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Permission check failed: {error}'**
  String activeTripPermissionFailed(String error);

  /// No description provided for @activeTripGpsActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'GPS active – tracking location'**
  String get activeTripGpsActiveMessage;

  /// No description provided for @activeTripGpsPositionError.
  ///
  /// In en, this message translates to:
  /// **'Could not get GPS position: {error}'**
  String activeTripGpsPositionError(String error);

  /// No description provided for @activeTripGpsSignalLost.
  ///
  /// In en, this message translates to:
  /// **'GPS signal lost. Retrying…'**
  String get activeTripGpsSignalLost;

  /// No description provided for @activeTripGpsStopped.
  ///
  /// In en, this message translates to:
  /// **'GPS stopped'**
  String get activeTripGpsStopped;

  /// No description provided for @activeTripCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start trip. Try again.'**
  String get activeTripCouldNotStart;

  /// No description provided for @activeTripCouldNotEnd.
  ///
  /// In en, this message translates to:
  /// **'Could not end trip. Try again.'**
  String get activeTripCouldNotEnd;

  /// No description provided for @activeTripEndDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'End this trip?'**
  String get activeTripEndDialogTitle;

  /// No description provided for @activeTripEndDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Make sure all passengers have boarded. This cannot be undone.'**
  String get activeTripEndDialogMessage;

  /// No description provided for @activeTripEndTripLabel.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get activeTripEndTripLabel;

  /// No description provided for @activeTripCompletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Trip completed. Great job!'**
  String get activeTripCompletedSnack;

  /// No description provided for @activeTripTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Trip Status'**
  String get activeTripTripStatus;

  /// No description provided for @activeTripDepartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get activeTripDepartedLabel;

  /// No description provided for @activeTripArrivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get activeTripArrivedLabel;

  /// No description provided for @activeTripGpsTracking.
  ///
  /// In en, this message translates to:
  /// **'GPS Tracking'**
  String get activeTripGpsTracking;

  /// No description provided for @activeTripCoordLat.
  ///
  /// In en, this message translates to:
  /// **'LAT'**
  String get activeTripCoordLat;

  /// No description provided for @activeTripCoordLng.
  ///
  /// In en, this message translates to:
  /// **'LNG'**
  String get activeTripCoordLng;

  /// No description provided for @activeTripCoordAcc.
  ///
  /// In en, this message translates to:
  /// **'ACC'**
  String get activeTripCoordAcc;

  /// No description provided for @activeTripStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get activeTripStartTrip;

  /// No description provided for @activeTripPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get activeTripPleaseWait;

  /// No description provided for @activeTripCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get activeTripCompletedBadge;

  /// No description provided for @activeTripArrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String activeTripArrivedAt(String time);

  /// No description provided for @activeTripTimeFormatHm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String activeTripTimeFormatHm(int h, int m);

  /// No description provided for @activeTripTimeFormatM.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String activeTripTimeFormatM(int m);

  /// No description provided for @tripPunctScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tripPunctScheduled;

  /// No description provided for @tripPunctDelayedDeparture.
  ///
  /// In en, this message translates to:
  /// **'Delayed Departure'**
  String get tripPunctDelayedDeparture;

  /// No description provided for @tripPunctOverdueMins.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {minutes} mins'**
  String tripPunctOverdueMins(int minutes);

  /// No description provided for @tripPunctOnTime.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get tripPunctOnTime;

  /// No description provided for @tripPunctReadyDepart.
  ///
  /// In en, this message translates to:
  /// **'Ready to depart on time'**
  String get tripPunctReadyDepart;

  /// No description provided for @tripPunctOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get tripPunctOnTrack;

  /// No description provided for @tripPunctInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get tripPunctInProgress;

  /// No description provided for @tripPunctDepartedLate.
  ///
  /// In en, this message translates to:
  /// **'Departed {minutes} mins late'**
  String tripPunctDepartedLate(int minutes);

  /// No description provided for @tripPunctDepartedEarly.
  ///
  /// In en, this message translates to:
  /// **'Departed {minutes} mins early'**
  String tripPunctDepartedEarly(int minutes);

  /// No description provided for @tripPunctDepartedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Departed on time'**
  String get tripPunctDepartedOnTime;

  /// No description provided for @tripPunctRunningLate.
  ///
  /// In en, this message translates to:
  /// **'Running Late'**
  String get tripPunctRunningLate;

  /// No description provided for @tripPunctDelayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get tripPunctDelayed;

  /// No description provided for @tripPunctCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripPunctCompleted;

  /// No description provided for @tripPunctTripFinished.
  ///
  /// In en, this message translates to:
  /// **'Trip finished'**
  String get tripPunctTripFinished;

  /// No description provided for @tripPunctArrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String tripPunctArrivedAt(String time);

  /// No description provided for @tripPunctArrivedLate.
  ///
  /// In en, this message translates to:
  /// **'Arrived {minutes} mins late'**
  String tripPunctArrivedLate(int minutes);

  /// No description provided for @tripPunctArrivedEarly.
  ///
  /// In en, this message translates to:
  /// **'Arrived {minutes} mins early'**
  String tripPunctArrivedEarly(int minutes);

  /// No description provided for @tripPunctArrivedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Arrived on time'**
  String get tripPunctArrivedOnTime;

  /// No description provided for @tripPunctDelayedArrival.
  ///
  /// In en, this message translates to:
  /// **'Delayed Arrival'**
  String get tripPunctDelayedArrival;

  /// No description provided for @tripPunctOnTimeArrival.
  ///
  /// In en, this message translates to:
  /// **'On Time Arrival'**
  String get tripPunctOnTimeArrival;

  /// No description provided for @tripPunctCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripPunctCancelled;

  /// No description provided for @tripPunctMessageCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip was cancelled'**
  String get tripPunctMessageCancelled;

  /// No description provided for @tripPunctTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Trip status: {status}'**
  String tripPunctTripStatus(String status);

  /// No description provided for @tripPunctErrorComputing.
  ///
  /// In en, this message translates to:
  /// **'Error computing status'**
  String get tripPunctErrorComputing;

  /// No description provided for @todayTripCardTapToManage.
  ///
  /// In en, this message translates to:
  /// **'Tap to manage'**
  String get todayTripCardTapToManage;

  /// No description provided for @todayTripCardDurationMin.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String todayTripCardDurationMin(int minutes);

  /// No description provided for @todayTripCardDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String todayTripCardDistanceKm(int distance);

  /// No description provided for @todayTripCardBusInfo.
  ///
  /// In en, this message translates to:
  /// **'{model} • {plate}'**
  String todayTripCardBusInfo(String model, String plate);

  /// No description provided for @todayTripCardCapacity.
  ///
  /// In en, this message translates to:
  /// **'{capacity} seats'**
  String todayTripCardCapacity(int capacity);

  /// No description provided for @todayTripCardNoSchedule.
  ///
  /// In en, this message translates to:
  /// **'No schedule assigned'**
  String get todayTripCardNoSchedule;

  /// No description provided for @todayTripCardNoScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'This trip has no schedule linked.\nContact your operator to fix it.'**
  String get todayTripCardNoScheduleDesc;

  /// No description provided for @upcomingTripCardRoute.
  ///
  /// In en, this message translates to:
  /// **'{origin} → {destination}'**
  String upcomingTripCardRoute(String origin, String destination);

  /// No description provided for @upcomingTripCardDateTime.
  ///
  /// In en, this message translates to:
  /// **'{date} • {time}'**
  String upcomingTripCardDateTime(String date, String time);

  /// No description provided for @conductorHomeHello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String conductorHomeHello(String name);

  /// No description provided for @conductorHomeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Conductor Dashboard'**
  String get conductorHomeDashboard;

  /// No description provided for @conductorHomeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get conductorHomeQuickActions;

  /// No description provided for @conductorHomeScanTicket.
  ///
  /// In en, this message translates to:
  /// **'Scan Ticket'**
  String get conductorHomeScanTicket;

  /// No description provided for @conductorHomePassengerList.
  ///
  /// In en, this message translates to:
  /// **'Passenger List'**
  String get conductorHomePassengerList;

  /// No description provided for @conductorHomeStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get conductorHomeStatTotal;

  /// No description provided for @conductorHomeStatBoarded.
  ///
  /// In en, this message translates to:
  /// **'Boarded'**
  String get conductorHomeStatBoarded;

  /// No description provided for @conductorHomeStatWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get conductorHomeStatWaiting;

  /// No description provided for @conductorHomeTodaysTrip.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Trip'**
  String get conductorHomeTodaysTrip;

  /// No description provided for @conductorHomeNoTripToday.
  ///
  /// In en, this message translates to:
  /// **'No trip today'**
  String get conductorHomeNoTripToday;

  /// No description provided for @conductorHomeNoTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have no assigned trips for today'**
  String get conductorHomeNoTripSubtitle;

  /// No description provided for @conductorPassAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Passenger List'**
  String get conductorPassAppBarTitle;

  /// No description provided for @conductorPassRoute.
  ///
  /// In en, this message translates to:
  /// **'{origin} → {destination}'**
  String conductorPassRoute(String origin, String destination);

  /// No description provided for @conductorPassBoardedProgress.
  ///
  /// In en, this message translates to:
  /// **'{boarded} / {total} boarded'**
  String conductorPassBoardedProgress(int boarded, int total);

  /// No description provided for @conductorPassFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String conductorPassFilterAll(int count);

  /// No description provided for @conductorPassFilterWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting ({count})'**
  String conductorPassFilterWaiting(int count);

  /// No description provided for @conductorPassFilterBoarded.
  ///
  /// In en, this message translates to:
  /// **'Boarded ({count})'**
  String conductorPassFilterBoarded(int count);

  /// No description provided for @conductorPassNoPassengers.
  ///
  /// In en, this message translates to:
  /// **'No passengers booked'**
  String get conductorPassNoPassengers;

  /// No description provided for @conductorPassNoFilterPassengers.
  ///
  /// In en, this message translates to:
  /// **'No {status} passengers'**
  String conductorPassNoFilterPassengers(String status);

  /// No description provided for @conductorPassMarkedBoarded.
  ///
  /// In en, this message translates to:
  /// **'Passenger marked as boarded ✅'**
  String get conductorPassMarkedBoarded;

  /// No description provided for @conductorPassError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String conductorPassError(String error);

  /// No description provided for @conductorPassTripStartAllowed.
  ///
  /// In en, this message translates to:
  /// **'Trip start allowed by conductor ✅'**
  String get conductorPassTripStartAllowed;

  /// No description provided for @conductorPassAllowStart.
  ///
  /// In en, this message translates to:
  /// **'Allow Trip Start'**
  String get conductorPassAllowStart;

  /// No description provided for @conductorPassUnknownPassenger.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get conductorPassUnknownPassenger;

  /// No description provided for @conductorPassSeatInfo.
  ///
  /// In en, this message translates to:
  /// **'Seat {number} • {phone}'**
  String conductorPassSeatInfo(String number, String phone);

  /// No description provided for @conductorPassWalkin.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get conductorPassWalkin;

  /// No description provided for @conductorPassStatusBoarded.
  ///
  /// In en, this message translates to:
  /// **'Boarded'**
  String get conductorPassStatusBoarded;

  /// No description provided for @conductorPassBoardBtn.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get conductorPassBoardBtn;

  /// No description provided for @conductorPassRLSError.
  ///
  /// In en, this message translates to:
  /// **'Update blocked by Supabase RLS policy. Conductor role cannot update trips.'**
  String get conductorPassRLSError;

  /// No description provided for @conductorScanAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Ticket'**
  String get conductorScanAppBarTitle;

  /// No description provided for @conductorScanInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code'**
  String get conductorScanInvalidQr;

  /// No description provided for @conductorScanTicketNotFound.
  ///
  /// In en, this message translates to:
  /// **'This ticket was not found in the system.'**
  String get conductorScanTicketNotFound;

  /// No description provided for @conductorScanNoBooking.
  ///
  /// In en, this message translates to:
  /// **'No Booking Found'**
  String get conductorScanNoBooking;

  /// No description provided for @conductorScanNoBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'This ticket is not associated with a booking.'**
  String get conductorScanNoBookingDesc;

  /// No description provided for @conductorScanWrongTrip.
  ///
  /// In en, this message translates to:
  /// **'Wrong Trip'**
  String get conductorScanWrongTrip;

  /// No description provided for @conductorScanWrongTripDesc.
  ///
  /// In en, this message translates to:
  /// **'This ticket is not for this trip. Please check the bus.'**
  String get conductorScanWrongTripDesc;

  /// No description provided for @conductorScanAlreadyScanned.
  ///
  /// In en, this message translates to:
  /// **'Already Scanned'**
  String get conductorScanAlreadyScanned;

  /// No description provided for @conductorScanScannedAt.
  ///
  /// In en, this message translates to:
  /// **'Scanned at {time}'**
  String conductorScanScannedAt(String time);

  /// No description provided for @conductorScanAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This ticket has already been used.'**
  String get conductorScanAlreadyUsed;

  /// No description provided for @conductorScanInvalidTicket.
  ///
  /// In en, this message translates to:
  /// **'Invalid Ticket'**
  String get conductorScanInvalidTicket;

  /// No description provided for @conductorScanTicketStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'This ticket is {status} and cannot be used.'**
  String conductorScanTicketStatusInvalid(String status);

  /// No description provided for @conductorScanBoardedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Boarded! ✅'**
  String get conductorScanBoardedSuccess;

  /// No description provided for @conductorScanPassengerSeat.
  ///
  /// In en, this message translates to:
  /// **'{name} • Seat {number}'**
  String conductorScanPassengerSeat(String name, String number);

  /// No description provided for @conductorScanScanError.
  ///
  /// In en, this message translates to:
  /// **'Scan Error'**
  String get conductorScanScanError;

  /// No description provided for @conductorScanProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get conductorScanProcessing;

  /// No description provided for @conductorScanHintText.
  ///
  /// In en, this message translates to:
  /// **'Point camera at passenger QR code'**
  String get conductorScanHintText;

  /// No description provided for @conductorScanNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket Validated'**
  String get conductorScanNotifTitle;

  /// No description provided for @conductorScanNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Your ticket for seat {seat} has been scanned. Enjoy your trip!'**
  String conductorScanNotifBody(String seat);

  /// No description provided for @operatorPanel.
  ///
  /// In en, this message translates to:
  /// **'Operator Panel'**
  String get operatorPanel;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @todaysSummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Summary'**
  String get todaysSummary;

  /// No description provided for @statActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statActive;

  /// No description provided for @statInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statInactive;

  /// No description provided for @statBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get statBookings;

  /// No description provided for @statUpcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trips'**
  String get statUpcomingTrips;

  /// No description provided for @fleetOverview.
  ///
  /// In en, this message translates to:
  /// **'Fleet Overview'**
  String get fleetOverview;

  /// No description provided for @statActiveBuses.
  ///
  /// In en, this message translates to:
  /// **'Active Buses'**
  String get statActiveBuses;

  /// No description provided for @statActiveRoutes.
  ///
  /// In en, this message translates to:
  /// **'Active Routes'**
  String get statActiveRoutes;

  /// No description provided for @statSchedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get statSchedules;

  /// No description provided for @statStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get statStaff;

  /// No description provided for @fleetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Fleet Alerts'**
  String get fleetAlerts;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addNewRoute.
  ///
  /// In en, this message translates to:
  /// **'Add New Route'**
  String get addNewRoute;

  /// No description provided for @addNewRouteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new bus route'**
  String get addNewRouteSubtitle;

  /// No description provided for @addNewBus.
  ///
  /// In en, this message translates to:
  /// **'Add New Bus'**
  String get addNewBus;

  /// No description provided for @addNewBusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register a bus to your fleet'**
  String get addNewBusSubtitle;

  /// No description provided for @addStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Add Staff Member'**
  String get addStaffMember;

  /// No description provided for @addStaffMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hire a driver or conductor'**
  String get addStaffMemberSubtitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @operatorErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String operatorErrorWithMessage(String error);

  /// No description provided for @noBusesYet.
  ///
  /// In en, this message translates to:
  /// **'No buses yet'**
  String get noBusesYet;

  /// No description provided for @addYourFirstBus.
  ///
  /// In en, this message translates to:
  /// **'Add your first bus to get started'**
  String get addYourFirstBus;

  /// No description provided for @addBus.
  ///
  /// In en, this message translates to:
  /// **'Add Bus'**
  String get addBus;

  /// No description provided for @busCapacity.
  ///
  /// In en, this message translates to:
  /// **'{capacity} seats'**
  String busCapacity(int capacity);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @setActive.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get setActive;

  /// No description provided for @underMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Under Maintenance'**
  String get underMaintenance;

  /// No description provided for @retireBus.
  ///
  /// In en, this message translates to:
  /// **'Retire Bus'**
  String get retireBus;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @busUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bus updated ✅'**
  String get busUpdated;

  /// No description provided for @busAdded.
  ///
  /// In en, this message translates to:
  /// **'Bus added ✅'**
  String get busAdded;

  /// No description provided for @editBus.
  ///
  /// In en, this message translates to:
  /// **'Edit Bus'**
  String get editBus;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumber;

  /// No description provided for @plateNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. PP-1234-AA'**
  String get plateNumberHint;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @busModel.
  ///
  /// In en, this message translates to:
  /// **'Bus Model'**
  String get busModel;

  /// No description provided for @busModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hyundai Universe'**
  String get busModelHint;

  /// No description provided for @seatCapacity.
  ///
  /// In en, this message translates to:
  /// **'Seat Capacity'**
  String get seatCapacity;

  /// No description provided for @seatCapacityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 40'**
  String get seatCapacityHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String failedToUpdate(String error);

  /// No description provided for @deleteRoute.
  ///
  /// In en, this message translates to:
  /// **'Delete Route'**
  String get deleteRoute;

  /// No description provided for @deleteRouteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will also remove associated schedules.'**
  String get deleteRouteConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noRoutesYet.
  ///
  /// In en, this message translates to:
  /// **'No routes yet'**
  String get noRoutesYet;

  /// No description provided for @addYourFirstRoute.
  ///
  /// In en, this message translates to:
  /// **'Add your first route to get started'**
  String get addYourFirstRoute;

  /// No description provided for @addRoute.
  ///
  /// In en, this message translates to:
  /// **'Add Route'**
  String get addRoute;

  /// No description provided for @distanceKmLabel.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKmLabel(int distance);

  /// No description provided for @durationMinLabel.
  ///
  /// In en, this message translates to:
  /// **'{duration} min'**
  String durationMinLabel(int duration);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @routeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Route updated ✅'**
  String get routeUpdated;

  /// No description provided for @routeCreated.
  ///
  /// In en, this message translates to:
  /// **'Route created ✅'**
  String get routeCreated;

  /// No description provided for @editRoute.
  ///
  /// In en, this message translates to:
  /// **'Edit Route'**
  String get editRoute;

  /// No description provided for @originCity.
  ///
  /// In en, this message translates to:
  /// **'Origin City'**
  String get originCity;

  /// No description provided for @originCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Phnom Penh'**
  String get originCityHint;

  /// No description provided for @destinationCity.
  ///
  /// In en, this message translates to:
  /// **'Destination City'**
  String get destinationCity;

  /// No description provided for @destinationCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Siem Reap'**
  String get destinationCityHint;

  /// No description provided for @distanceKmHint.
  ///
  /// In en, this message translates to:
  /// **'314'**
  String get distanceKmHint;

  /// No description provided for @durationMinHint.
  ///
  /// In en, this message translates to:
  /// **'360'**
  String get durationMinHint;

  /// No description provided for @createRoute.
  ///
  /// In en, this message translates to:
  /// **'Create Route'**
  String get createRoute;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete Schedule'**
  String get deleteSchedule;

  /// No description provided for @deleteScheduleConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove the schedule permanently.'**
  String get deleteScheduleConfirm;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noSchedulesYet.
  ///
  /// In en, this message translates to:
  /// **'No schedules yet'**
  String get noSchedulesYet;

  /// No description provided for @createScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a schedule to start taking bookings'**
  String get createScheduleSubtitle;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @scheduleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get scheduleActive;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @departureLabel.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departureLabel;

  /// No description provided for @arrivalLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrivalLabel;

  /// No description provided for @perSeat.
  ///
  /// In en, this message translates to:
  /// **'per seat'**
  String get perSeat;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add Schedule'**
  String get addSchedule;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editSchedule;

  /// No description provided for @newSchedule.
  ///
  /// In en, this message translates to:
  /// **'New Schedule'**
  String get newSchedule;

  /// No description provided for @routeDropdown.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeDropdown;

  /// No description provided for @busDropdown.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get busDropdown;

  /// No description provided for @driverDropdown.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverDropdown;

  /// No description provided for @conductorOptional.
  ///
  /// In en, this message translates to:
  /// **'Conductor (optional)'**
  String get conductorOptional;

  /// No description provided for @noConductor.
  ///
  /// In en, this message translates to:
  /// **'No conductor'**
  String get noConductor;

  /// No description provided for @pricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'Price per seat (\$)'**
  String get pricePerSeat;

  /// No description provided for @priceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12.00'**
  String get priceHint;

  /// No description provided for @operatingDays.
  ///
  /// In en, this message translates to:
  /// **'Operating Days'**
  String get operatingDays;

  /// No description provided for @pleaseSelectRoute.
  ///
  /// In en, this message translates to:
  /// **'Please select a route'**
  String get pleaseSelectRoute;

  /// No description provided for @pleaseSelectBus.
  ///
  /// In en, this message translates to:
  /// **'Please select a bus'**
  String get pleaseSelectBus;

  /// No description provided for @pleaseSelectDriver.
  ///
  /// In en, this message translates to:
  /// **'Please select a driver'**
  String get pleaseSelectDriver;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a price'**
  String get pleaseEnterPrice;

  /// No description provided for @pleaseSelectAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one day'**
  String get pleaseSelectAtLeastOneDay;

  /// No description provided for @scheduleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated ✅'**
  String get scheduleUpdated;

  /// No description provided for @scheduleCreated.
  ///
  /// In en, this message translates to:
  /// **'Schedule created ✅'**
  String get scheduleCreated;

  /// No description provided for @createSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create Schedule'**
  String get createSchedule;

  /// No description provided for @staffActivated.
  ///
  /// In en, this message translates to:
  /// **'Staff activated ✅'**
  String get staffActivated;

  /// No description provided for @staffSuspended.
  ///
  /// In en, this message translates to:
  /// **'Staff suspended ⛔'**
  String get staffSuspended;

  /// No description provided for @driversTab.
  ///
  /// In en, this message translates to:
  /// **'Drivers ({count})'**
  String driversTab(int count);

  /// No description provided for @conductorsTab.
  ///
  /// In en, this message translates to:
  /// **'Conductors ({count})'**
  String conductorsTab(int count);

  /// No description provided for @noDriversYet.
  ///
  /// In en, this message translates to:
  /// **'No drivers yet'**
  String get noDriversYet;

  /// No description provided for @addDriverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a driver to assign to trips'**
  String get addDriverSubtitle;

  /// No description provided for @noConductorsYet.
  ///
  /// In en, this message translates to:
  /// **'No conductors yet'**
  String get noConductorsYet;

  /// No description provided for @addConductorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a conductor to manage boarding'**
  String get addConductorSubtitle;

  /// No description provided for @addDriver.
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get addDriver;

  /// No description provided for @addConductor.
  ///
  /// In en, this message translates to:
  /// **'Add Conductor'**
  String get addConductor;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @suspendedStatus.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspendedStatus;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @staffFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get staffFullName;

  /// No description provided for @staffFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sok Dara'**
  String get staffFullNameHint;

  /// No description provided for @staffEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get staffEmail;

  /// No description provided for @staffEmailHint.
  ///
  /// In en, this message translates to:
  /// **'driver@example.com'**
  String get staffEmailHint;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @staffPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get staffPhone;

  /// No description provided for @staffPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'012 345 678'**
  String get staffPhoneHint;

  /// No description provided for @temporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary Password'**
  String get temporaryPassword;

  /// No description provided for @min8Chars.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get min8Chars;

  /// No description provided for @staffInfoNote.
  ///
  /// In en, this message translates to:
  /// **'Share the email and password with the staff member. They can change their password after logging in.'**
  String get staffInfoNote;

  /// No description provided for @allSystemsNormal.
  ///
  /// In en, this message translates to:
  /// **'All Systems Normal'**
  String get allSystemsNormal;

  /// No description provided for @allSystemsNormalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All fleet vehicles operating normally.'**
  String get allSystemsNormalSubtitle;

  /// No description provided for @myCompany.
  ///
  /// In en, this message translates to:
  /// **'My Company'**
  String get myCompany;

  /// No description provided for @activeOperator.
  ///
  /// In en, this message translates to:
  /// **'Active Operator'**
  String get activeOperator;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @systemControlPanel.
  ///
  /// In en, this message translates to:
  /// **'System Control Panel'**
  String get systemControlPanel;

  /// No description provided for @systemOverview.
  ///
  /// In en, this message translates to:
  /// **'System Overview'**
  String get systemOverview;

  /// No description provided for @allOperatorsAndUsers.
  ///
  /// In en, this message translates to:
  /// **'All operators & users'**
  String get allOperatorsAndUsers;

  /// No description provided for @liveTrips.
  ///
  /// In en, this message translates to:
  /// **'Live Trips'**
  String get liveTrips;

  /// No description provided for @todaysTrips.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Trips'**
  String get todaysTrips;

  /// No description provided for @operatorsSection.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get operatorsSection;

  /// No description provided for @usersSection.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersSection;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// No description provided for @suspendOperatorConfirm.
  ///
  /// In en, this message translates to:
  /// **'Suspending this operator will prevent their buses from appearing in searches. Continue?'**
  String get suspendOperatorConfirm;

  /// No description provided for @reactivateOperatorConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will reactivate the operator and their services. Continue?'**
  String get reactivateOperatorConfirm;

  /// No description provided for @operatorActivated.
  ///
  /// In en, this message translates to:
  /// **'Operator activated ✅'**
  String get operatorActivated;

  /// No description provided for @operatorSuspended.
  ///
  /// In en, this message translates to:
  /// **'Operator suspended ⛔'**
  String get operatorSuspended;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @activeFilter.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeFilter;

  /// No description provided for @inactiveFilter.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveFilter;

  /// No description provided for @noOperatorsFound.
  ///
  /// In en, this message translates to:
  /// **'No operators found'**
  String get noOperatorsFound;

  /// No description provided for @addOperator.
  ///
  /// In en, this message translates to:
  /// **'Add Operator'**
  String get addOperator;

  /// No description provided for @busesLabel.
  ///
  /// In en, this message translates to:
  /// **'Buses'**
  String get busesLabel;

  /// No description provided for @routesLabel.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routesLabel;

  /// No description provided for @staffLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffLabel;

  /// No description provided for @addNewOperator.
  ///
  /// In en, this message translates to:
  /// **'Add New Operator'**
  String get addNewOperator;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Capitol Express'**
  String get companyNameHint;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// No description provided for @contactNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+855 23 123 456'**
  String get contactNumberHint;

  /// No description provided for @createOperator.
  ///
  /// In en, this message translates to:
  /// **'Create Operator'**
  String get createOperator;

  /// No description provided for @operatorCreated.
  ///
  /// In en, this message translates to:
  /// **'Operator created ✅'**
  String get operatorCreated;

  /// No description provided for @userActivated.
  ///
  /// In en, this message translates to:
  /// **'User activated ✅'**
  String get userActivated;

  /// No description provided for @userSuspended.
  ///
  /// In en, this message translates to:
  /// **'User suspended ⛔'**
  String get userSuspended;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated to {role} ✅'**
  String roleUpdated(String role);

  /// No description provided for @searchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByNameOrEmail;

  /// No description provided for @allRole.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allRole;

  /// No description provided for @activeUsersTab.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String activeUsersTab(int count);

  /// No description provided for @suspendedUsersTab.
  ///
  /// In en, this message translates to:
  /// **'Suspended ({count})'**
  String suspendedUsersTab(int count);

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortBy;

  /// No description provided for @sortDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get sortDeparture;

  /// No description provided for @sortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sortPrice;

  /// No description provided for @sortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortDuration;

  /// No description provided for @standardBus.
  ///
  /// In en, this message translates to:
  /// **'Standard Bus'**
  String get standardBus;

  /// No description provided for @bookButton.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookButton;

  /// No description provided for @noBusesFound.
  ///
  /// In en, this message translates to:
  /// **'No buses found'**
  String get noBusesFound;

  /// No description provided for @noSchedulesMessage.
  ///
  /// In en, this message translates to:
  /// **'No schedules from {origin} to {destination} on this date.'**
  String noSchedulesMessage(String origin, String destination);

  /// No description provided for @tryDifferentDate.
  ///
  /// In en, this message translates to:
  /// **'Try Different Date'**
  String get tryDifferentDate;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Booking updates and trip alerts will appear here.'**
  String get noNotificationsSubtitle;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @khmer.
  ///
  /// In en, this message translates to:
  /// **'ភាសាខ្មែរ'**
  String get khmer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
