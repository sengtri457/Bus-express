// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'Bus Express';

  @override
  String get appSplashSubtitle => 'Premium Travel Made Simple';

  @override
  String get signInButton => 'ចូល';

  @override
  String get signInSubtitle => 'ចូលគណនីរបស់អ្នកដើម្បីបន្តការកក់';

  @override
  String get welcomeBack => 'សូមស្វាគមន៍';

  @override
  String get dontHaveAccount => 'មិនទាន់មានគណនី? ';

  @override
  String get signUpLink => 'ចុះឈ្មោះ';

  @override
  String get forgotPasswordLink => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get orDivider => 'ឬ';

  @override
  String get continueWithGoogle => 'បន្តជាមួយ Google';

  @override
  String accountSuspended(String status) {
    return 'គណនីរបស់អ្នកត្រូវបានផ្អាក $status។ សូមទាក់ទងផ្នែកជំនួយ។';
  }

  @override
  String get googleSignInFailed =>
      'មិនអាចបើក Google sign-in បានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get googleSignInError => 'Google sign-in បរាជ័យ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get emailLabel => 'អ៊ីមែល';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'សូមបញ្ចូលអ៊ីមែល';

  @override
  String get enterValidEmail => 'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ';

  @override
  String get passwordLabel => 'ពាក្យសម្ងាត់';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'សូមបញ្ចូលពាក្យសម្ងាត់';

  @override
  String get passwordMinLength => 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ 6 តួ';

  @override
  String get passwordMinLength8 => 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ 8 តួ';

  @override
  String get createAccountTitle => 'បង្កើតគណនី';

  @override
  String get signupSubtitle =>
      'ចូលរួមជាមួយយើង និងកក់ការធ្វើដំណើររបស់អ្នកយ៉ាងងាយស្រួល';

  @override
  String get fullNameLabel => 'ឈ្មោះពេញ';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get fullNameRequired => 'សូមបញ្ចូលឈ្មោះពេញ';

  @override
  String get nameTooShort => 'ឈ្មោះខ្លីពេក';

  @override
  String get phoneNumberLabel => 'លេខទូរស័ព្ទ';

  @override
  String get phoneNumberHint => '+855 12 345 678';

  @override
  String get phoneRequired => 'សូមបញ្ចូលលេខទូរស័ព្ទ';

  @override
  String get enterValidPhone => 'សូមបញ្ចូលលេខទូរស័ព្ទត្រឹមត្រូវ';

  @override
  String get continueButton => 'បន្ត';

  @override
  String get emailAddressLabel => 'អាសយដ្ឋានអ៊ីមែល';

  @override
  String get emailAddressHint => 'you@example.com';

  @override
  String get atLeast8Chars => 'យ៉ាងហោចណាស់ 8 តួ';

  @override
  String get includeUppercase => 'ត្រូវមានអក្សរធំយ៉ាងហោចណាស់មួយ';

  @override
  String get includeNumber => 'ត្រូវមានលេខយ៉ាងហោចណាស់មួយ';

  @override
  String get confirmPasswordLabel => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get confirmPasswordHint => '••••••••';

  @override
  String get pleaseConfirmPassword => 'សូមបញ្ជាក់ពាក្យសម្ងាត់របស់អ្នក';

  @override
  String get passwordsDoNotMatch => 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ';

  @override
  String get iAgreeTo => 'ខ្ញុំយល់ព្រមនឹង ';

  @override
  String get termsAndConditions => 'លក្ខខណ្ឌនិងលក្ខខណ្ឌ';

  @override
  String get andConjunction => ' និង ';

  @override
  String get privacyPolicy => 'គោលការណ៍ឯកជនភាព';

  @override
  String get createAccountButton => 'បង្កើតគណនី';

  @override
  String get alreadyHaveAccount => 'មានគណនីរួចហើយ? ';

  @override
  String get signInLink => 'ចូល';

  @override
  String get stepPersonal => 'ផ្ទាល់ខ្លួន';

  @override
  String get stepAccount => 'គណនី';

  @override
  String get passwordStrengthLabel => 'កម្រិតសុវត្ថិភាពពាក្យសម្ងាត់';

  @override
  String get passwordWeak => 'ខ្សោយ';

  @override
  String get passwordFair => 'មធ្យម';

  @override
  String get passwordGood => 'ល្អ';

  @override
  String get passwordStrong => 'ខ្លាំង';

  @override
  String get passwordStrengthHint =>
      'ប្រើ 8+ តួ, អក្សរធំ, លេខ & និមិត្តសញ្ញាសម្រាប់ពាក្យសម្ងាត់ខ្លាំង';

  @override
  String get agreeTermsError => 'សូមយល់ព្រមនឹងលក្ខខណ្ឌនិងលក្ខខណ្ឌ';

  @override
  String get registrationFailed => 'ការចុះឈ្មោះបរាជ័យ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get accountCreatedTitle => 'បង្កើតគណនីដោយជោគជ័យ!';

  @override
  String verificationSent(String email) {
    return 'យើងបានផ្ញើតំណភ្ជាប់ផ្ទៀងផ្ទាត់ទៅ\n$email\n\nសូមផ្ទៀងផ្ទាត់អ៊ីមែលរបស់អ្នកមុនពេលចូល។';
  }

  @override
  String get goToLogin => 'ទៅកាន់ទំព័រចូល';

  @override
  String get forgotPasswordTitle => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get forgotPasswordSubtitle =>
      'កុំបារម្ភ! បញ្ចូលអ៊ីមែលរបស់អ្នក យើងនឹងផ្ញើតំណកំណត់ពាក្យសម្ងាត់ឡើងវិញ។';

  @override
  String get sendResetLink => 'ផ្ញើតំណកំណត់ឡើងវិញ';

  @override
  String get backToLoginLink => 'ត្រឡប់ទៅការចូល';

  @override
  String get backToLogin => 'ត្រឡប់ទៅការចូល';

  @override
  String get checkYourEmail => 'ពិនិត្យអ៊ីមែលរបស់អ្នក';

  @override
  String resetLinkSent(String email) {
    return 'យើងបានផ្ញើតំណកំណត់ពាក្យសម្ងាត់ឡើងវិញទៅ\n$email';
  }

  @override
  String get infoStep1 => 'បើកអ៊ីមែលដែលយើងផ្ញើទៅអ្នក';

  @override
  String get infoStep2 => 'ចុចតំណ \"កំណត់ពាក្យសម្ងាត់ឡើងវិញ\"';

  @override
  String get infoStep3 => 'បង្កើតពាក្យសម្ងាត់ថ្មីដែលរឹងមាំ';

  @override
  String get didNotReceiveEmail => 'មិនទាន់ទទួលបានអ៊ីមែលទេ?';

  @override
  String get resendEmail => 'ផ្ញើអ៊ីមែលម្តងទៀត';

  @override
  String resendInCountdown(int seconds) {
    return 'ផ្ញើវិញក្នុង $secondsវិនាទី';
  }

  @override
  String get setNewPassword => 'កំណត់ពាក្យសម្ងាត់ថ្មី';

  @override
  String get setNewPasswordSubtitle =>
      'ពាក្យសម្ងាត់ថ្មីរបស់អ្នកត្រូវតែខុសពីពាក្យសម្ងាត់មុន។';

  @override
  String get newPasswordLabel => 'ពាក្យសម្ងាត់ថ្មី';

  @override
  String get newPasswordHint => '••••••••';

  @override
  String get confirmNewPasswordLabel => 'បញ្ជាក់ពាក្យសម្ងាត់ថ្មី';

  @override
  String get confirmNewPasswordHint => '••••••••';

  @override
  String get passwordsDoNotMatchValidator => 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ';

  @override
  String get resetPasswordButton => 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ';

  @override
  String get enterValidEmailAddress => 'សូមបញ្ចូលអាសយដ្ឋានអ៊ីមែលត្រឹមត្រូវ';

  @override
  String get somethingWentWrong => 'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get passwordResetTitle => 'កំណត់ពាក្យសម្ងាត់ឡើងវិញដោយជោគជ័យ!';

  @override
  String get passwordResetBody =>
      'ពាក្យសម្ងាត់របស់អ្នកត្រូវបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ។ សូមចូលដោយប្រើពាក្យសម្ងាត់ថ្មីរបស់អ្នក។';

  @override
  String get navBookBus => 'កក់ឡានក្រុង';

  @override
  String get navMyTickets => 'សំបុត្ររបស់ខ្ញុំ';

  @override
  String get navProfile => 'ប្រវត្តិរូប';

  @override
  String get navDashboard => 'ផ្ទាំងគ្រប់គ្រង';

  @override
  String get navRoutes => 'ផ្លូវ';

  @override
  String get navBuses => 'ឡានក្រុង';

  @override
  String get navSchedules => 'កាលវិភាគ';

  @override
  String get navStaff => 'បុគ្គលិក';

  @override
  String get navOperators => 'ប្រតិបត្តិករ';

  @override
  String get navUsers => 'អ្នកប្រើប្រាស់';

  @override
  String homeHelloName(String name) {
    return 'សួស្តី $name';
  }

  @override
  String get homeWhereGoing => 'តើអ្នកចង់ទៅណាថ្ងៃនេះ?';

  @override
  String get homeOurPartners => 'ដៃគូរបស់យើង';

  @override
  String get homePopularRoutes => 'ផ្លូវពេញនិយម';

  @override
  String get homeOriginLabel => 'ចំណុចចេញដំណើរ';

  @override
  String get homeOriginHint => 'ពីណា?';

  @override
  String get homeDestinationLabel => 'គោលដៅ';

  @override
  String get homeDestinationHint => 'ទៅណា?';

  @override
  String get homeTravelDate => 'ថ្ងៃធ្វើដំណើរ';

  @override
  String get homeSwapLocations => 'ដូរចំណុចចេញដំណើរ និងគោលដៅ';

  @override
  String get homeSearchBuses => 'ស្វែងរកឡានក្រុង';

  @override
  String get homeErrorOriginDestination => 'សូមបញ្ចូលចំណុចចេញដំណើរ និងគោលដៅ';

  @override
  String get homeNoOperators => 'មិនមានប្រតិបត្តិករនៅពេលនេះទេ';

  @override
  String get profileMyProfile => 'ប្រវត្តិរូបរបស់ខ្ញុំ';

  @override
  String profileErrorLoading(String error) {
    return 'កំហុសក្នុងការផ្ទុកប្រវត្តិរូប: $error';
  }

  @override
  String get profileUpdatedSuccess =>
      'ប្រវត្តិរូបត្រូវបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ!';

  @override
  String profileFailedUpdate(String error) {
    return 'បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាពប្រវត្តិរូប: $error';
  }

  @override
  String get profilePasswordUpdated =>
      'ពាក្យសម្ងាត់ត្រូវបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ!';

  @override
  String profileFailedPassword(String error) {
    return 'បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាពពាក្យសម្ងាត់: $error';
  }

  @override
  String profileErrorSignOut(String error) {
    return 'កំហុសក្នុងការចាកចេញ: $error';
  }

  @override
  String get profilePersonalDetails => 'ព័ត៌មានផ្ទាល់ខ្លួន';

  @override
  String get profileFullNameLabel => 'ឈ្មោះពេញ';

  @override
  String get profileFullNameHint => 'បញ្ចូលឈ្មោះរបស់អ្នក';

  @override
  String get profileSaveDetails => 'រក្សាទុកព័ត៌មាន';

  @override
  String get profileSecurityPassword => 'សុវត្ថិភាព និងពាក្យសម្ងាត់';

  @override
  String get profileUpdatePassword => 'ធ្វើបច្ចុប្បន្នភាពពាក្យសម្ងាត់';

  @override
  String get profileSignOut => 'ចាកចេញ';

  @override
  String get scheduleSelectSeat => 'ជ្រើសរើសកៅអី';

  @override
  String get schedulePleaseSelectSeat => 'សូមជ្រើសរើសកៅអីយ៉ាងហោចណាស់មួយ';

  @override
  String get scheduleAvailable => 'ទំនេរ';

  @override
  String get scheduleSelected => 'បានជ្រើសរើស';

  @override
  String get scheduleBooked => 'បានកក់';

  @override
  String get scheduleTripEnded => 'ដំណើរនេះបានបញ្ចប់ / បានបញ្ចប់ហើយ។';

  @override
  String get scheduleTripCancelled => 'ដំណើរនេះត្រូវបានលុបចោល។';

  @override
  String get scheduleTripOver => 'ដំណើរនេះបានបញ្ចប់ / បានចេញដំណើរហើយ (ហួសពេល)។';

  @override
  String get scheduleNoSeatSelected => 'មិនទាន់បានជ្រើសរើសកៅអី';

  @override
  String scheduleSeatCount(int count, String seats) {
    return '$count កៅអី: $seats';
  }

  @override
  String get scheduleContinue => 'បន្ត';

  @override
  String get scheduleFrontLabel => 'មុខ';

  @override
  String get scheduleDoorLabel => 'ទ្វារ';

  @override
  String scheduleSeatsLeft(int count) {
    return '$count កៅអីទៀត';
  }

  @override
  String get scheduleBackLabel => 'ក្រោយ';

  @override
  String get bookingConfirmTitle => 'បញ្ជាក់ការកក់';

  @override
  String get bookingTripDetails => 'ព័ត៌មានលម្អិតអំពីដំណើរ';

  @override
  String get bookingDate => 'កាលបរិច្ឆេទ';

  @override
  String get bookingSeats => 'កៅអី';

  @override
  String get bookingBus => 'ឡានក្រុង';

  @override
  String get bookingPassenger => 'អ្នកដំណើរ';

  @override
  String get bookingUseSavedInfo => 'ប្រើព័ត៌មានដែលបានរក្សាទុក';

  @override
  String get bookingEnterFullName => 'បញ្ចូលឈ្មោះពេញ';

  @override
  String get bookingAgeLabel => 'អាយុ';

  @override
  String get bookingEnterAge => 'បញ្ចូលអាយុ';

  @override
  String get bookingEnterValidAge => 'បញ្ចូលអាយុត្រឹមត្រូវ';

  @override
  String get bookingPhoneLabel => 'លេខទូរស័ព្ទ';

  @override
  String get bookingPhoneHelper =>
      'បញ្ចូលលេខកូដប្រទេស (ឧ. +1XXXXXXXXX) សម្រាប់ OTP';

  @override
  String get bookingEnterPhone => 'បញ្ចូលលេខទូរស័ព្ទ';

  @override
  String get bookingIncludeCountryCode => 'បញ្ចូលលេខកូដប្រទេស (ឧ. +1XXXXXXXXX)';

  @override
  String get bookingEnterValidPhone =>
      'បញ្ចូលលេខទូរស័ព្ទត្រឹមត្រូវ (8–15 ខ្ទង់)';

  @override
  String get bookingNationalityLabel => 'សញ្ជាតិ';

  @override
  String get bookingEnterNationality => 'បញ្ចូលសញ្ជាតិ';

  @override
  String get bookingEmailHolder => 'អ៊ីមែល';

  @override
  String get bookingEmailHelper => 'បង្កាន់ដៃនឹងត្រូវបានផ្ញើមកទីនេះ';

  @override
  String get bookingEnterValidEmail => 'បញ្ចូលអាសយដ្ឋានអ៊ីមែលត្រឹមត្រូវ';

  @override
  String get bookingDetailsSaved =>
      'ព័ត៌មានរបស់អ្នកត្រូវបានរក្សាទុកសម្រាប់ការកក់នាពេលអនាគត';

  @override
  String get bookingPayment => 'ការទូទាត់';

  @override
  String get bookingPromoCodeHint => 'លេខកូដផ្សព្វផ្សាយ';

  @override
  String get bookingPromoCodeRequired => 'សូមបញ្ចូលលេខកូដផ្សព្វផ្សាយ';

  @override
  String get bookingPromoInvalid => 'លេខកូដផ្សព្វផ្សាយមិនត្រឹមត្រូវ';

  @override
  String get bookingPromoInactive => 'លេខកូដផ្សព្វផ្សាយនេះមិនដំណើរការទៀតទេ';

  @override
  String get bookingPromoExpired => 'លេខកូដផ្សព្វផ្សាយនេះផុតសុពលភាពហើយ';

  @override
  String bookingMinPurchase(String amount) {
    return 'តម្រូវឱ្យទិញយ៉ាងហោចណាស់ $amount';
  }

  @override
  String get bookingPromoMaxUsage =>
      'លេខកូដផ្សព្វផ្សាយនេះបានឈានដល់ដែនកំណត់ការប្រើប្រាស់';

  @override
  String bookingPromoPerUser(int used, int max) {
    return 'អ្នកបានប្រើលេខកូដនេះ $used ដងក្នុងចំណោម $max ដង';
  }

  @override
  String bookingPromoPercentage(String value) {
    return 'បញ្ចុះ $value%';
  }

  @override
  String bookingPromoFixed(String value) {
    return 'បញ្ចុះ \$$value';
  }

  @override
  String get bookingPromoFailed =>
      'បរាជ័យក្នុងការត្រួតពិនិត្យលេខកូដផ្សព្វផ្សាយ';

  @override
  String get bookingPromoRemove => 'លុប';

  @override
  String get bookingPromoApply => 'អនុវត្ត';

  @override
  String get bookingPricePerSeat => 'តម្លៃក្នុងមួយកៅអី';

  @override
  String get bookingNumberOfSeats => 'ចំនួនកៅអី';

  @override
  String get bookingDiscount => 'បញ្ចុះតម្លៃ';

  @override
  String get bookingTotal => 'សរុប';

  @override
  String get bookingNotice =>
      'មកដល់ 15 នាទីមុនពេលចេញដំណើរ។ បង្ហាញ QR សំបុត្ររបស់អ្នកទៅអ្នកដឹកអ្នកដំណើរពេលឡើងឡាន។';

  @override
  String get bookingInvalidPhoneFormat => 'ទម្រង់លេខទូរស័ព្ទមិនត្រឹមត្រូវ។';

  @override
  String get bookingInvalidPhoneMessage =>
      'លេខទូរស័ព្ទមិនត្រឹមត្រូវ។ បញ្ចូលលេខពិតប្រាកដដែលមានលេខកូដប្រទេសត្រឹមត្រូវ (ឧ. +1234567890)។';

  @override
  String get bookingInvalidEmail => 'បញ្ចូលអាសយដ្ឋានអ៊ីមែលត្រឹមត្រូវ។';

  @override
  String get bookingTripDeparted => 'បានចេញដំណើររួច';

  @override
  String get bookingTripEnded => 'បានបញ្ចប់រួច';

  @override
  String get bookingTripCancelled => 'ត្រូវបានលុបចោល';

  @override
  String bookingTripNotBookable(String reason) {
    return 'ដំណើរនេះ$reason ហើយមិនអាចកក់បានទេ។';
  }

  @override
  String get bookingFailedCreateTrip =>
      'បរាជ័យក្នុងការបង្កើតដំណើរ។ សូមពិនិត្យ RLS policies នៅលើតារាង trips ។';

  @override
  String bookingFailedCreateBooking(String seat) {
    return 'បរាជ័យក្នុងការបង្កើតការកក់សម្រាប់កៅអី $seat។ សូមពិនិត្យ RLS policies នៅលើតារាង bookings ។';
  }

  @override
  String get bookingNotificationTitle => 'ការកក់បានបញ្ជាក់';

  @override
  String bookingNotificationBody(
    int count,
    String origin,
    String destination,
    String time,
  ) {
    return '$count កៅអីនៅលើ $origin → $destination ($time)';
  }

  @override
  String bookingFailedGeneric(String message) {
    return 'ការកក់បរាជ័យ: $message';
  }

  @override
  String get bookingSeatTakenError =>
      'សូមអភ័យទោស កៅអីមួយរបស់អ្នកទើបត្រូវបានកក់ដោយអ្នកដទៃ។ សូមជ្រើសរើសកៅអីផ្សេង។';

  @override
  String get bookingHoldFailedError =>
      'មិនអាចកក់កៅអីទាំងនោះបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get bookingSeatCooldownError =>
      'កៅអីនេះទើបត្រូវបានដោះលែង ហើយមិនអាចកក់បានបណ្តោះអាសន្ន។ សូមព្យាយាមម្តងទៀតក្នុងពេលបន្តិចទៀត។';

  @override
  String get bookingHoldExpiredError =>
      'ការកក់កៅអីរបស់អ្នកបានផុតកំណត់។ សូមជ្រើសរើសកៅអីម្តងទៀត។';

  @override
  String bookingHoldRemaining(String time) {
    return 'កៅអីត្រូវបានកក់រយៈពេល $time';
  }

  @override
  String bookingHoldExpiringSoon(String time) {
    return 'ការកក់នឹងផុតកំណត់ឆាប់ៗ — នៅសល់ $time';
  }

  @override
  String get paymentLeaveTitle => 'បោះបង់ការទូទាត់នេះ?';

  @override
  String get paymentLeaveMessage =>
      'ការកក់របស់អ្នកនឹងត្រូវបានបោះបង់ ហើយកៅអីនឹងត្រូវបានដោះលែង។ អ្នកនឹងត្រូវចាប់ផ្តើមឡើងវិញ។';

  @override
  String get paymentLeaveStay => 'បន្តការទូទាត់';

  @override
  String get paymentLeaveCancel => 'បោះបង់ការកក់';

  @override
  String get bookingLeaveTitle => 'ដោះលែងកៅអីរបស់អ្នក?';

  @override
  String get bookingLeaveMessage =>
      'កៅអីដែលអ្នកបានកក់នឹងត្រូវបានដោះលែង ហើយអ្នកដទៃអាចកក់វាបាន។';

  @override
  String get bookingLeaveStay => 'រក្សាកៅអីរបស់ខ្ញុំ';

  @override
  String get bookingLeaveRelease => 'ដោះលែង ហើយត្រឡប់ក្រោយ';

  @override
  String get bookingReceiptSent => 'បង្កាន់ដៃត្រូវបានផ្ញើទៅអ៊ីមែលរបស់អ្នក';

  @override
  String get bookingConfirmButton => 'បញ្ជាក់ការកក់';

  @override
  String bookingConfirmCountSeats(int count) {
    return 'បញ្ជាក់ $count កៅអី';
  }

  @override
  String get liveTrackingAppBar => 'តាមដានផ្ទាល់';

  @override
  String get liveTripNotFound => 'រកមិនឃើញដំណើរទេ។ ប្រហែលជាត្រូវបានលុបចោល។';

  @override
  String get liveCouldNotLoad =>
      'មិនអាចផ្ទុកទិន្នន័យតាមដានបានទេ។ សូមពិនិត្យការតភ្ជាប់របស់អ្នក។';

  @override
  String get liveSomethingWrong => 'មានបញ្ហាកើតឡើង។';

  @override
  String get liveRetry => 'ព្យាយាមម្តងទៀត';

  @override
  String get liveTooltipFollowBus => 'តាមដានឡានក្រុង';

  @override
  String get liveTooltipFollowingBus => 'កំពុងតាមដានឡានក្រុង';

  @override
  String get liveTripNotStarted => 'ដំណើរមិនទាន់ចាប់ផ្តើមទេ';

  @override
  String get liveTripNotStartedDesc =>
      'ឡានក្រុងនឹងបង្ហាញនៅលើផែនទីនៅពេលអ្នកបើកបរចាប់ផ្តើមដំណើរ។';

  @override
  String get liveStatusOnWay => 'ឡានក្រុងកំពុងធ្វើដំណើរ';

  @override
  String get liveStatusLocating => 'កំពុងស្វែងរកទីតាំងឡានក្រុង...';

  @override
  String get liveStatusCompleted => 'ដំណើរបានបញ្ចប់';

  @override
  String get liveStatusCancelled => 'ដំណើរត្រូវបានលុបចោល';

  @override
  String get liveStatusWaiting => 'រង់ចាំការចេញដំណើរ';

  @override
  String liveDepartedAt(String time) {
    return 'បានចេញដំណើរនៅ $time';
  }

  @override
  String get liveBadge => 'ផ្ទាល់';

  @override
  String get liveBusLocation => 'ទីតាំងឡានក្រុង';

  @override
  String get liveScheduledSchedule => 'កាលវិភាគដែលបានកំណត់';

  @override
  String get liveEstimatedArrival => 'ការមកដល់ប៉ាន់ស្មាន';

  @override
  String liveDelayMinutes(int delay) {
    return '+$delay នាទី';
  }

  @override
  String get liveUpdatesEvery5 => 'ការធ្វើបច្ចុប្បន្នភាពទីតាំងរៀងរាល់ 5 វិនាទី';

  @override
  String get liveTrackingStarts => 'ការតាមដានចាប់ផ្តើមនៅពេលអ្នកបើកបរចេញដំណើរ';

  @override
  String liveIncidentReported(String Type) {
    return '$Type ត្រូវបានរាយការណ៍';
  }

  @override
  String get myTicketsTitle => 'សំបុត្ររបស់ខ្ញុំ';

  @override
  String myTicketsUpcoming(int count) {
    return 'នាពេលខាងមុខ ($count)';
  }

  @override
  String myTicketsPast(int count) {
    return 'កន្លងមក ($count)';
  }

  @override
  String get myTicketsNoUpcoming => 'គ្មានដំណើរនាពេលខាងមុខទេ';

  @override
  String get myTicketsNoUpcomingSub => 'កក់សំបុត្រឡានក្រុងដើម្បីមើលវានៅទីនេះ';

  @override
  String get myTicketsNoPast => 'គ្មានដំណើរកន្លងមកទេ';

  @override
  String get myTicketsNoPastSub => 'ដំណើរដែលអ្នកបានបញ្ចប់នឹងបង្ហាញនៅទីនេះ';

  @override
  String get myTicketsSuccessSingular => 'ការកក់បានបញ្ជាក់!';

  @override
  String myTicketsSuccessPlural(int count) {
    return '$count កៅអីត្រូវបានបញ្ជាក់!';
  }

  @override
  String get myTicketsSuccessDescSingular =>
      'សំបុត្ររបស់អ្នករួចរាល់។ បង្ហាញ QR កូដទៅអ្នកដឹកអ្នកដំណើរពេលឡើងឡាន។';

  @override
  String myTicketsSuccessDescPlural(int count) {
    return 'សំបុត្រ $count របស់អ្នករួចរាល់។ កៅអីនីមួយៗមាន QR កូដផ្ទាល់ខ្លួន។';
  }

  @override
  String get myTicketsViewSingular => 'មើលសំបុត្ររបស់ខ្ញុំ';

  @override
  String get myTicketsViewPlural => 'មើលសំបុត្រទាំងអស់';

  @override
  String get receiptTitle => 'បង្កាន់ដៃ';

  @override
  String get receiptBusExpress => 'BUS EXPRESS';

  @override
  String get receiptOfficial => 'បង្កាន់ដៃផ្លូវការ';

  @override
  String get receiptReceiptNo => 'លេខបង្កាន់ដៃ #';

  @override
  String get receiptIssued => 'ចេញឱ្យ';

  @override
  String get receiptRoute => 'ផ្លូវ';

  @override
  String get receiptDeparture => 'ការចេញដំណើរ';

  @override
  String get receiptBookingDetails => 'ព័ត៌មានលម្អិតអំពីការកក់';

  @override
  String get receiptTableSeat => 'កៅអី';

  @override
  String get receiptTableStatus => 'ស្ថានភាព';

  @override
  String get receiptTablePrice => 'តម្លៃ';

  @override
  String get receiptTotal => 'សរុប៖ ';

  @override
  String get receiptThankYou => 'សូមអរគុណសម្រាប់ការធ្វើដំណើរជាមួយ Bus Express!';

  @override
  String get receiptKeepRecord =>
      'នេះជាបង្កាន់ដៃផ្លូវការរបស់អ្នក។ សូមរក្សាទុកសម្រាប់កំណត់ត្រារបស់អ្នក។';

  @override
  String get receiptShare => 'ចែករំលែកបង្កាន់ដៃ (PDF)';

  @override
  String get receiptGenerating => 'កំពុងបង្កើត...';

  @override
  String get promotionsTitle => 'ការផ្សព្វផ្សាយទាំងអស់';

  @override
  String promotionsCopied(String code) {
    return 'លេខកូដផ្សព្វផ្សាយ \"$code\" ត្រូវបានចម្លង!';
  }

  @override
  String get promotionsNoPromotions => 'មិនមានការផ្សព្វផ្សាយនៅពេលនេះទេ';

  @override
  String get promotionsNoPromotionsSub =>
      'សូមត្រឡប់មកក្រោយសម្រាប់ការផ្តល់ជូនពិសេស!';

  @override
  String promotionsMinPurchase(String amount) {
    return 'ការទិញអប្បបរមា: $amount';
  }

  @override
  String get cancelSheetTitle => 'លុបការកក់?';

  @override
  String get cancelSheetConfirm =>
      'តើអ្នកប្រាកដថាចង់លុបការធ្វើដំណើររបស់អ្នកទេ?';

  @override
  String get cancelSheetRoute => 'ផ្លូវ';

  @override
  String get cancelSheetSeat => 'កៅអី';

  @override
  String get cancelSheetAmount => 'ចំនួនទឹកប្រាក់';

  @override
  String get cancelSheetPolicy =>
      'ការលុបចោលត្រូវតែធ្វើឡើងយ៉ាងហោចណាស់ 2 ម៉ោងមុនពេលចេញដំណើរ។ ដំណើរដែលកំពុងដំណើរការមិនអាចលុបចោលបានទេ។';

  @override
  String get cancelSheetKeep => 'រក្សាការកក់';

  @override
  String get cancelSheetYesCancel => 'បាទ/ចាស, លុបចោល';

  @override
  String get cancelSuccessTitle => 'ការកក់ត្រូវបានលុបចោល';

  @override
  String cancelSuccessDesc(String origin, String destination, String seat) {
    return 'ការកក់របស់អ្នកសម្រាប់ $origin → $destination (កៅអី $seat) ត្រូវបានលុបចោល។';
  }

  @override
  String get cancelSuccessNote =>
      'ការកក់របស់អ្នកត្រូវបានលុបចោល។ ប្រសិនបើមានការទូទាត់រួចហើយ ប្រាក់នឹងត្រូវបានបង្វិលសងទៅកាន់កាបូបរបស់អ្នក។';

  @override
  String get cancelSheetDone => 'រួចរាល់';

  @override
  String get offersSectionTitle => 'ការផ្តល់ជូនសម្រាប់អ្នក';

  @override
  String get offersViewMore => 'មើលបន្ថែម';

  @override
  String get offersCategoryAll => 'ទាំងអស់';

  @override
  String get offersCategoryBus => 'ឡានក្រុង';

  @override
  String get offersCategoryTrain => 'រថភ្លើង';

  @override
  String get offersNoOffers => 'មិនមានការផ្តល់ជូនសម្រាប់ប្រភេទនេះទេ';

  @override
  String get popularRoutesNoRoutes => 'មិនទាន់មានផ្លូវនៅឡើយទេ';

  @override
  String get routeSelectorTitle => 'ជ្រើសរើសផ្លូវ';

  @override
  String get routeSelectorSearchHint => 'ស្វែងរកគោលដៅ...';

  @override
  String get routeSelectorNoRoutes => 'មិនមានផ្លូវទេ';

  @override
  String routeSelectorNoMatch(String query) {
    return 'រកមិនឃើញផ្លូវដែលត្រូវនឹង \"$query\"';
  }

  @override
  String get ticketCardNewBooking => 'ការកក់ថ្មី';

  @override
  String ticketCardSeats(int count) {
    return '$count កៅអី';
  }

  @override
  String get ticketCardTrackLive => 'តាមដានផ្ទាល់';

  @override
  String get ticketCardTrackBus => 'តាមដានឡានក្រុង';

  @override
  String get ticketCardViewQrSingular => 'ចុចដើម្បីមើល QR កូដ';

  @override
  String ticketCardViewQrPlural(int count) {
    return 'ចុចដើម្បីមើល $count QR កូដ';
  }

  @override
  String get ticketCardViewReceipt => 'មើលបង្កាន់ដៃ';

  @override
  String get ticketDetailTrackLive => 'តាមដានផ្ទាល់';

  @override
  String get ticketDetailTrackBus => 'តាមដានឡានក្រុង';

  @override
  String get ticketDetailCancelTooLate =>
      'មិនអាចលុបចោលបានទេ — ការចេញដំណើរតិចជាង 2 ម៉ោង។';

  @override
  String get ticketDetailCancelledSingular => 'ការកក់ត្រូវបានលុបចោល';

  @override
  String ticketDetailCancelledPlural(int count) {
    return '$count ការកក់ត្រូវបានលុបចោល';
  }

  @override
  String ticketDetailErrorPrefix(String error) {
    return 'កំហុស: $error';
  }

  @override
  String get ticketDetailConfirmCancelTitleSingular => 'លុបការកក់?';

  @override
  String ticketDetailConfirmCancelTitlePlural(int count) {
    return 'លុប $count កៅអី?';
  }

  @override
  String get ticketDetailConfirmPolicy =>
      'ការលុបចោលត្រូវតែធ្វើឡើងយ៉ាងហោចណាស់ 2 ម៉ោងមុនពេលចេញដំណើរ។';

  @override
  String get ticketDetailKeepIt => 'រក្សាទុក';

  @override
  String get ticketDetailYesCancel => 'បាទ/ចាស, លុបចោល';

  @override
  String ticketDetailSeatCount(int count) {
    return '$count កៅអី';
  }

  @override
  String ticketDetailTotal(String amount) {
    return 'សរុប $amount';
  }

  @override
  String ticketDetailCancelAll(int count) {
    return 'លុបចោល $count កៅអីទាំងអស់';
  }

  @override
  String get ticketDetailCancelBooking => 'លុបចោលការកក់';

  @override
  String ticketDetailSeatTab(String seat) {
    return 'កៅអី $seat';
  }

  @override
  String get ticketDetailDeparture => 'ការចេញដំណើរ';

  @override
  String get ticketDetailArrival => 'ការមកដល់';

  @override
  String get ticketDetailTicketPrice => 'តម្លៃសំបុត្រ';

  @override
  String get ticketDetailPayment => 'ការទូទាត់';

  @override
  String get ticketDetailQrError => 'កំហុស QR';

  @override
  String get ticketDetailStatusUsed => 'សំបុត្រត្រូវបានប្រើរួច';

  @override
  String get ticketDetailStatusCancelled => 'សំបុត្រត្រូវបានលុបចោល';

  @override
  String get ticketDetailStatusExpired => 'សំបុត្រផុតសុពលភាព';

  @override
  String get ticketDetailStatusNoData => 'គ្មានទិន្នន័យសំបុត្រ';

  @override
  String get ticketDetailInfoValid =>
      'បង្ហាញ QR កូដនេះទៅអ្នកដឹកអ្នកដំណើរពេលឡើងឡាន។';

  @override
  String get ticketDetailInfoUsed =>
      'សំបុត្រនេះត្រូវបានប្រើសម្រាប់ការឡើងឡានរួចហើយ។';

  @override
  String get ticketDetailInfoCancelled => 'ការកក់នេះត្រូវបានលុបចោល។';

  @override
  String get ticketDetailInfoExpired => 'សំបុត្រនេះផុតសុពលភាពហើយ។';

  @override
  String get ticketDetailInfoUnknown => 'ស្ថានភាពសំបុត្រមិនច្បាស់លាស់។';

  @override
  String get cancelServiceSuccess => 'ការកក់ត្រូវបានលុបចោលដោយជោគជ័យ។';

  @override
  String get cancelServiceTooLate =>
      'មិនអាចលុបចោលបានទេ — ការចេញដំណើរតិចជាង 2 ម៉ោង។';

  @override
  String get cancelServiceAlreadyBoarded =>
      'មិនអាចលុបចោលបានទេ — អ្នកបានឡើងឡានរួចហើយ។';

  @override
  String get cancelServiceAlreadyCancelled => 'ការកក់នេះត្រូវបានលុបចោលរួចហើយ។';

  @override
  String get cancelServiceTripStarted =>
      'មិនអាចលុបចោលបានទេ — ដំណើរបានចាប់ផ្តើម ឬបញ្ចប់រួចហើយ។';

  @override
  String get cancelServiceError => 'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្តងទៀត។';

  @override
  String driverHomeHello(String name) {
    return 'សួស្តី $name';
  }

  @override
  String get driverHomeDashboard => 'ផ្ទាំងគ្រប់គ្រងអ្នកបើកបរ';

  @override
  String get driverHomeTodaysTrip => 'ដំណើរថ្ងៃនេះ';

  @override
  String get driverHomeNoTripToday => 'គ្មានដំណើរថ្ងៃនេះទេ';

  @override
  String get driverHomeNoTripSubtitle =>
      'អ្នកមិនមានដំណើរដែលបានកំណត់ពេលសម្រាប់ថ្ងៃនេះទេ';

  @override
  String get driverHomeUpcomingTrips => 'ដំណើរនាពេលខាងមុខ';

  @override
  String get driverHomeQuickStats => 'ស្ថិតិរហ័ស';

  @override
  String get driverHomeStatTotalTrips => 'ដំណើរសរុប';

  @override
  String get driverHomeStatCompleted => 'បានបញ្ចប់';

  @override
  String get driverHomeStatPassengers => 'អ្នកដំណើរ';

  @override
  String get driverHomeFailedLoad => 'បរាជ័យក្នុងការផ្ទុកទិន្នន័យ';

  @override
  String get driverHomeRetry => 'ព្យាយាមម្តងទៀត';

  @override
  String get driverTripAppBarTitle => 'ការគ្រប់គ្រងដំណើរ';

  @override
  String get driverTripReportIncident => 'រាយការណ៍ហេតុការណ៍';

  @override
  String get driverTripRouteLabel => 'ផ្លូវ';

  @override
  String get driverTripBusLabel => 'ឡានក្រុង';

  @override
  String get driverTripDateLabel => 'កាលបរិច្ឆេទ';

  @override
  String get driverTripStatusReady => 'ត្រៀមចេញដំណើរ';

  @override
  String get driverTripStatusInProgress => 'ដំណើរកំពុងដំណើរការ';

  @override
  String get driverTripStatusCompleted => 'ដំណើរបានបញ្ចប់';

  @override
  String get driverTripStatusCancelled => 'ដំណើរត្រូវបានលុបចោល';

  @override
  String get driverTripStatusUnknown => 'មិនស្គាល់';

  @override
  String driverTripDepartedAt(String time) {
    return 'បានចេញដំណើរនៅ $time';
  }

  @override
  String driverTripArrivedAt(String time) {
    return 'បានមកដល់នៅ $time';
  }

  @override
  String get driverTripTapStart => 'ចុច \"ចាប់ផ្តើមដំណើរ\" នៅពេលត្រៀម';

  @override
  String get driverTripGpsActive => 'GPS កំពុងដំណើរការ';

  @override
  String get driverTripPassengersTitle => 'អ្នកដំណើរ';

  @override
  String driverTripPassengerCount(int boarded, int total) {
    return '$boarded/$total បានឡើងឡាន';
  }

  @override
  String get driverTripNoPassengers => 'មិនទាន់មានអ្នកដំណើរកក់ទេ';

  @override
  String driverTripSeatInfo(String number, String phone) {
    return 'កៅអី $number • $phone';
  }

  @override
  String get driverTripUnknownPassenger => 'អ្នកដំណើរមិនស្គាល់';

  @override
  String get driverTripStartTripBtn => 'ចាប់ផ្តើមដំណើរ';

  @override
  String get driverTripEndTripArrivedBtn => 'បញ្ចប់ដំណើរ (មកដល់)';

  @override
  String driverTripEndTripCountdown(String countdown) {
    return 'បញ្ចប់ដំណើរ (ត្រៀមក្នុង $countdown)';
  }

  @override
  String get driverTripStartDialogTitle => 'ចាប់ផ្តើមដំណើរ';

  @override
  String get driverTripStartDialogMessage =>
      'តើអ្នកត្រៀមចេញដំណើរហើយឬនៅ? នេះនឹងជូនដំណឹងដល់អ្នកដំណើរទាំងអស់។';

  @override
  String get driverTripStartNowLabel => 'ចាប់ផ្តើមឥឡូវនេះ';

  @override
  String get driverTripEndDialogTitle => 'បញ្ចប់ដំណើរ';

  @override
  String driverTripEndDialogMessageDelay(int delay) {
    return 'ដំណើរត្រូវបានពន្យារពេល $delay នាទីដោយសារហេតុការណ៍។ បញ្ជាក់ការមកដល់?';
  }

  @override
  String get driverTripEndDialogMessageNormal =>
      'បញ្ជាក់ថាអ្នកបានមកដល់គោលដៅហើយ?';

  @override
  String get driverTripEndTripLabel => 'បញ្ចប់ដំណើរ';

  @override
  String get driverTripCancel => 'បោះបង់';

  @override
  String driverTripBusNotFull(int boarded, int capacity) {
    return 'ឡានមិនទាន់ពេញ ($boarded/$capacity)។ កំពុងរង់ចាំការអនុញ្ញាតពីអ្នកដឹកអ្នកដំណើរ។';
  }

  @override
  String get driverTripStartedSnack => 'ដំណើរបានចាប់ផ្តើម! GPS កំពុងដំណើរការ។';

  @override
  String driverTripFailedStart(String error) {
    return 'បរាជ័យក្នុងការចាប់ផ្តើមដំណើរ: $error';
  }

  @override
  String driverTripWaitCountdown(String time, String countdown) {
    return 'ការមកដល់នៅ $time។ សូមរង់ចាំ $countdown ដើម្បីបញ្ចប់ដំណើរ។';
  }

  @override
  String get driverTripCompletedSnack => 'ដំណើរបានបញ្ចប់ដោយជោគជ័យ!';

  @override
  String driverTripFailedEnd(String error) {
    return 'បរាជ័យក្នុងការបញ្ចប់ដំណើរ: $error';
  }

  @override
  String get driverTripNotificationTitle => 'ដំណើរបានចាប់ផ្តើម';

  @override
  String driverTripNotificationBody(String origin, String destination) {
    return 'ឡានក្រុងរបស់អ្នកពី $origin → $destination បានចេញដំណើរហើយ! តាមដានផ្ទាល់។';
  }

  @override
  String get driverTripNA => 'N/A';

  @override
  String driverTripDelayInfo(int delay, int count) {
    return '$delay នាទីយឺត ($count ហេតុការណ៍)';
  }

  @override
  String driverTripAdjustedEta(String time) {
    return 'ETA ដែលបានកែតម្រូវ: $time';
  }

  @override
  String get driverTripOverdue => 'ហួសពេល';

  @override
  String get driverTripTimeFallback => '--:--';

  @override
  String get driverIncidentAppBarTitle => 'រាយការណ៍ហេតុការណ៍';

  @override
  String get driverIncidentHeaderWarning =>
      'រាយការណ៍ហេតុការណ៍ណាមួយដែលប៉ះពាល់ដល់ដំណើរនេះភ្លាមៗ។ របាយការណ៍របស់អ្នកនឹងត្រូវបានផ្ញើទៅប្រតិបត្តិករ។';

  @override
  String get driverIncidentTypeLabel => 'ប្រភេទហេតុការណ៍';

  @override
  String get driverIncidentTypeDelay => 'ពន្យារពេល';

  @override
  String get driverIncidentTypeBreakdown => 'ខូច';

  @override
  String get driverIncidentTypeAccident => 'គ្រោះថ្នាក់';

  @override
  String get driverIncidentTypeOther => 'ផ្សេងៗ';

  @override
  String get driverIncidentLocationLabel => 'ទីតាំងហេតុការណ៍';

  @override
  String get driverIncidentDetectingLocation => 'កំពុងរកទីតាំង...';

  @override
  String get driverIncidentAccessingGps => 'កំពុងចូលប្រើ GPS...';

  @override
  String get driverIncidentGpsDenied => 'ការអនុញ្ញាត GPS ត្រូវបានបដិសេធ';

  @override
  String get driverIncidentResolvingAddress => 'កំពុងដោះស្រាយអាសយដ្ឋាន...';

  @override
  String get driverIncidentUnknownLocation => 'ទីតាំងមិនស្គាល់';

  @override
  String get driverIncidentFailedDetect => 'បរាជ័យក្នុងការរកទីតាំង';

  @override
  String get driverIncidentAutoDetecting => 'កំពុងរកទីតាំងដោយស្វ័យប្រវត្តិ...';

  @override
  String get driverIncidentAutoDetected => 'ទីតាំងដែលបានរកឃើញដោយស្វ័យប្រវត្តិ';

  @override
  String get driverIncidentLocationService => 'សេវាទីតាំង';

  @override
  String get driverIncidentRefreshLocation => 'ធ្វើឱ្យទីតាំងស្រស់';

  @override
  String get driverIncidentDescriptionLabel => 'ការពិពណ៌នា';

  @override
  String get driverIncidentHintText =>
      'រៀបរាប់លម្អិតអំពីអ្វីដែលបានកើតឡើង...\n\nឧ. \"ឡានក្រុងខូចក្បែរកំពង់ធំ កំពុងរង់ចាំជួសជុល។ ការពន្យារពេលប៉ាន់ស្មាន: 30 នាទី។\"';

  @override
  String get driverIncidentSubmitReport => 'ដាក់ស្នើរបាយការណ៍';

  @override
  String get driverIncidentPleaseDescribe => 'សូមពិពណ៌នាអំពីហេតុការណ៍';

  @override
  String get driverIncidentNotLoggedIn => 'មិនទាន់ចូលប្រព័ន្ធ';

  @override
  String get driverIncidentReportedTitle => 'ហេតុការណ៍ត្រូវបានរាយការណ៍';

  @override
  String get driverIncidentReportedMessage =>
      'របាយការណ៍ហេតុការណ៍របស់អ្នកត្រូវបានដាក់ស្នើដោយជោគជ័យ។';

  @override
  String get driverIncidentOK => 'យល់ព្រម';

  @override
  String driverIncidentFailedError(String message) {
    return 'បរាជ័យ: $message';
  }

  @override
  String get driverIncidentIssueFallback => 'បញ្ហា';

  @override
  String get driverIncidentPreviousReports => 'របាយការណ៍មុនៗនៃដំណើរនេះ';

  @override
  String driverIncidentNotificationTitle(String type) {
    return 'ការជូនដំណឹងដំណើរ: $type';
  }

  @override
  String driverIncidentNotificationBody(String type, int delay) {
    return 'ឡានក្រុងរបស់អ្នកបានរាយការណ៍ $type។ ការពន្យារពេលប៉ាន់ស្មាន: $delay នាទី។ យើងសុំទោសចំពោះការរំខាន។';
  }

  @override
  String get activeTripAppBarTitle => 'ដំណើរសកម្ម';

  @override
  String get activeTripGpsNotStarted => 'GPS មិនទាន់ចាប់ផ្តើម';

  @override
  String get activeTripRequestingPermission => 'កំពុងស្នើសុំការអនុញ្ញាតទីតាំង…';

  @override
  String get activeTripGpsDisabled =>
      'សេវាទីតាំងត្រូវបានបិទ។ សូមបើកវានៅក្នុងការកំណត់។';

  @override
  String get activeTripPermissionDenied =>
      'ការអនុញ្ញាតទីតាំងត្រូវបានបដិសេធ។ សូមបើកវានៅក្នុងការកំណត់។';

  @override
  String activeTripPermissionFailed(String error) {
    return 'ការត្រួតពិនិត្យការអនុញ្ញាតបរាជ័យ: $error';
  }

  @override
  String get activeTripGpsActiveMessage => 'GPS សកម្ម – កំពុងតាមដានទីតាំង';

  @override
  String activeTripGpsPositionError(String error) {
    return 'មិនអាចទទួលបានទីតាំង GPS: $error';
  }

  @override
  String get activeTripGpsSignalLost => 'សញ្ញា GPS បាត់។ កំពុងព្យាយាមម្តងទៀត…';

  @override
  String get activeTripGpsStopped => 'GPS បានឈប់';

  @override
  String get activeTripCouldNotStart =>
      'មិនអាចចាប់ផ្តើមដំណើរបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get activeTripCouldNotEnd =>
      'មិនអាចបញ្ចប់ដំណើរបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get activeTripEndDialogTitle => 'បញ្ចប់ដំណើរនេះ?';

  @override
  String get activeTripEndDialogMessage =>
      'សូមប្រាកដថាអ្នកដំណើរទាំងអស់បានឡើងឡានហើយ។ នេះមិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get activeTripEndTripLabel => 'បញ្ចប់ដំណើរ';

  @override
  String get activeTripCompletedSnack => 'ដំណើរបានបញ្ចប់។ ល្អណាស់!';

  @override
  String get activeTripTripStatus => 'ស្ថានភាពដំណើរ';

  @override
  String get activeTripDepartedLabel => 'បានចេញដំណើរ';

  @override
  String get activeTripArrivedLabel => 'បានមកដល់';

  @override
  String get activeTripGpsTracking => 'GPS តាមដាន';

  @override
  String get activeTripCoordLat => 'រយៈទទឹង';

  @override
  String get activeTripCoordLng => 'រយៈបណ្តោយ';

  @override
  String get activeTripCoordAcc => 'ភាពត្រឹមត្រូវ';

  @override
  String get activeTripStartTrip => 'ចាប់ផ្តើមដំណើរ';

  @override
  String get activeTripPleaseWait => 'សូមរង់ចាំ…';

  @override
  String get activeTripCompletedBadge => 'ដំណើរបានបញ្ចប់';

  @override
  String activeTripArrivedAt(String time) {
    return 'បានមកដល់នៅ $time';
  }

  @override
  String activeTripTimeFormatHm(int h, int m) {
    return '$hម៉ $mន';
  }

  @override
  String activeTripTimeFormatM(int m) {
    return '$mន';
  }

  @override
  String get tripPunctScheduled => 'បានកំណត់ពេល';

  @override
  String get tripPunctDelayedDeparture => 'ការចេញដំណើរយឺត';

  @override
  String tripPunctOverdueMins(int minutes) {
    return 'ហួសពេល $minutes នាទី';
  }

  @override
  String get tripPunctOnTime => 'ទាន់ពេល';

  @override
  String get tripPunctReadyDepart => 'ត្រៀមចេញដំណើរទាន់ពេល';

  @override
  String get tripPunctOnTrack => 'តាមផែនការ';

  @override
  String get tripPunctInProgress => 'ដំណើរកំពុងដំណើរការ';

  @override
  String tripPunctDepartedLate(int minutes) {
    return 'បានចេញដំណើរយឺត $minutes នាទី';
  }

  @override
  String tripPunctDepartedEarly(int minutes) {
    return 'បានចេញដំណើរមុន $minutes នាទី';
  }

  @override
  String get tripPunctDepartedOnTime => 'បានចេញដំណើរទាន់ពេល';

  @override
  String get tripPunctRunningLate => 'កំពុងយឺត';

  @override
  String get tripPunctDelayed => 'ពន្យារពេល';

  @override
  String get tripPunctCompleted => 'បានបញ្ចប់';

  @override
  String get tripPunctTripFinished => 'ដំណើរបានបញ្ចប់';

  @override
  String tripPunctArrivedAt(String time) {
    return 'បានមកដល់នៅ $time';
  }

  @override
  String tripPunctArrivedLate(int minutes) {
    return 'បានមកដល់យឺត $minutes នាទី';
  }

  @override
  String tripPunctArrivedEarly(int minutes) {
    return 'បានមកដល់មុន $minutes នាទី';
  }

  @override
  String get tripPunctArrivedOnTime => 'បានមកដល់ទាន់ពេល';

  @override
  String get tripPunctDelayedArrival => 'ការមកដល់យឺត';

  @override
  String get tripPunctOnTimeArrival => 'ការមកដល់ទាន់ពេល';

  @override
  String get tripPunctCancelled => 'បានលុបចោល';

  @override
  String get tripPunctMessageCancelled => 'ដំណើរត្រូវបានលុបចោល';

  @override
  String tripPunctTripStatus(String status) {
    return 'ស្ថានភាពដំណើរ: $status';
  }

  @override
  String get tripPunctErrorComputing => 'កំហុសក្នុងការគណនាស្ថានភាព';

  @override
  String get todayTripCardTapToManage => 'ចុចដើម្បីគ្រប់គ្រង';

  @override
  String todayTripCardDurationMin(int minutes) {
    return '$minutes នាទី';
  }

  @override
  String todayTripCardDistanceKm(int distance) {
    return '$distance គ.ម';
  }

  @override
  String todayTripCardBusInfo(String model, String plate) {
    return '$model • $plate';
  }

  @override
  String todayTripCardCapacity(int capacity) {
    return '$capacity កៅអី';
  }

  @override
  String get todayTripCardNoSchedule => 'មិនមានកាលវិភាគ';

  @override
  String get todayTripCardNoScheduleDesc =>
      'ដំណើរនេះគ្មានកាលវិភាគភ្ជាប់ទេ។\nសូមទាក់ទងប្រតិបត្តិកររបស់អ្នកដើម្បីដោះស្រាយ។';

  @override
  String upcomingTripCardRoute(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String upcomingTripCardDateTime(String date, String time) {
    return '$date • $time';
  }

  @override
  String conductorHomeHello(String name) {
    return 'សួស្តី $name';
  }

  @override
  String get conductorHomeDashboard => 'ផ្ទាំងគ្រប់គ្រងអ្នកដឹកអ្នកដំណើរ';

  @override
  String get conductorHomeQuickActions => 'សកម្មភាពរហ័ស';

  @override
  String get conductorHomeScanTicket => 'ស្កេនសំបុត្រ';

  @override
  String get conductorHomePassengerList => 'បញ្ជីអ្នកដំណើរ';

  @override
  String get conductorHomeStatTotal => 'សរុប';

  @override
  String get conductorHomeStatBoarded => 'បានឡើងឡាន';

  @override
  String get conductorHomeStatWaiting => 'កំពុងរង់ចាំ';

  @override
  String get conductorHomeTodaysTrip => 'ដំណើរថ្ងៃនេះ';

  @override
  String get conductorHomeNoTripToday => 'គ្មានដំណើរថ្ងៃនេះទេ';

  @override
  String get conductorHomeNoTripSubtitle =>
      'អ្នកមិនមានដំណើរដែលបានចាត់តាំងសម្រាប់ថ្ងៃនេះទេ';

  @override
  String get conductorPassAppBarTitle => 'បញ្ជីអ្នកដំណើរ';

  @override
  String conductorPassRoute(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String conductorPassBoardedProgress(int boarded, int total) {
    return '$boarded / $total បានឡើងឡាន';
  }

  @override
  String conductorPassFilterAll(int count) {
    return 'ទាំងអស់ ($count)';
  }

  @override
  String conductorPassFilterWaiting(int count) {
    return 'កំពុងរង់ចាំ ($count)';
  }

  @override
  String conductorPassFilterBoarded(int count) {
    return 'បានឡើងឡាន ($count)';
  }

  @override
  String get conductorPassNoPassengers => 'គ្មានអ្នកដំណើរកក់';

  @override
  String conductorPassNoFilterPassengers(String status) {
    return 'គ្មានអ្នកដំណើរ $status';
  }

  @override
  String get conductorPassMarkedBoarded =>
      'អ្នកដំណើរត្រូវបានសម្គាល់ថាបានឡើងឡាន ✅';

  @override
  String conductorPassError(String error) {
    return 'កំហុស: $error';
  }

  @override
  String get conductorPassTripStartAllowed =>
      'ការចាប់ផ្តើមដំណើរត្រូវបានអនុញ្ញាតដោយអ្នកដឹកអ្នកដំណើរ ✅';

  @override
  String get conductorPassAllowStart => 'អនុញ្ញាតឱ្យចាប់ផ្តើមដំណើរ';

  @override
  String get conductorPassUnknownPassenger => 'មិនស្គាល់';

  @override
  String conductorPassSeatInfo(String number, String phone) {
    return 'កៅអី $number • $phone';
  }

  @override
  String get conductorPassWalkin => 'ដើរចូល';

  @override
  String get conductorPassStatusBoarded => 'បានឡើងឡាន';

  @override
  String get conductorPassBoardBtn => 'ឡើងឡាន';

  @override
  String get conductorPassRLSError =>
      'ការធ្វើបច្ចុប្បន្នភាពត្រូវបានរារាំងដោយគោលការណ៍ RLS របស់ Supabase។ តួនាទីអ្នកដឹកអ្នកដំណើរមិនអាចធ្វើបច្ចុប្បន្នភាពដំណើរបានទេ។';

  @override
  String get conductorScanAppBarTitle => 'ស្កេនសំបុត្រ';

  @override
  String get conductorScanInvalidQr => 'QR កូដមិនត្រឹមត្រូវ';

  @override
  String get conductorScanTicketNotFound =>
      'រកមិនឃើញសំបុត្រនេះនៅក្នុងប្រព័ន្ធទេ។';

  @override
  String get conductorScanNoBooking => 'រកមិនឃើញការកក់';

  @override
  String get conductorScanNoBookingDesc => 'សំបុត្រនេះមិនភ្ជាប់ជាមួយការកក់ទេ។';

  @override
  String get conductorScanWrongTrip => 'ដំណើរខុស';

  @override
  String get conductorScanWrongTripDesc =>
      'សំបុត្រនេះមិនមែនសម្រាប់ដំណើរនេះទេ។ សូមពិនិត្យឡានក្រុង។';

  @override
  String get conductorScanAlreadyScanned => 'បានស្កេនរួច';

  @override
  String conductorScanScannedAt(String time) {
    return 'បានស្កេននៅ $time';
  }

  @override
  String get conductorScanAlreadyUsed => 'សំបុត្រនេះត្រូវបានប្រើរួចហើយ។';

  @override
  String get conductorScanInvalidTicket => 'សំបុត្រមិនត្រឹមត្រូវ';

  @override
  String conductorScanTicketStatusInvalid(String status) {
    return 'សំបុត្រនេះ $status ហើយមិនអាចប្រើបានទេ។';
  }

  @override
  String get conductorScanBoardedSuccess => 'ឡើងឡានដោយជោគជ័យ! ✅';

  @override
  String conductorScanPassengerSeat(String name, String number) {
    return '$name • កៅអី $number';
  }

  @override
  String get conductorScanScanError => 'កំហុសក្នុងការស្កេន';

  @override
  String get conductorScanProcessing => 'កំពុងដំណើរការ...';

  @override
  String get conductorScanHintText => 'ចង្អុលកាមេរ៉ាទៅ QR កូដអ្នកដំណើរ';

  @override
  String get conductorScanNotifTitle => 'សំបុត្រត្រូវបានដំណើរការ';

  @override
  String conductorScanNotifBody(String seat) {
    return 'សំបុត្ររបស់អ្នកសម្រាប់កៅអី $seat ត្រូវបានស្កេន។ សូមរីករាយជាមួយការធ្វើដំណើរ!';
  }

  @override
  String get operatorPanel => 'ផ្ទាំងគ្រប់គ្រងប្រតិបត្តិករ';

  @override
  String get adminDashboard => 'ផ្ទាំងគ្រប់គ្រងអ្នកគ្រប់គ្រង';

  @override
  String get todaysSummary => 'សេចក្តីសង្ខេបថ្ងៃនេះ';

  @override
  String get statActive => 'សកម្ម';

  @override
  String get statInactive => 'អសកម្ម';

  @override
  String get statBookings => 'ការកក់';

  @override
  String get statUpcomingTrips => 'ដំណើរនាពេលខាងមុខ';

  @override
  String get fleetOverview => 'ទិដ្ឋភាពទូទៅនៃកងនាវា';

  @override
  String get statActiveBuses => 'ឡានក្រុងសកម្ម';

  @override
  String get statActiveRoutes => 'ផ្លូវសកម្ម';

  @override
  String get statSchedules => 'កាលវិភាគ';

  @override
  String get statStaff => 'បុគ្គលិក';

  @override
  String get fleetAlerts => 'ការជូនដំណឹងកងនាវា';

  @override
  String get quickActions => 'សកម្មភាពរហ័ស';

  @override
  String get addNewRoute => 'បន្ថែមផ្លូវថ្មី';

  @override
  String get addNewRouteSubtitle => 'បង្កើតផ្លូវឡានក្រុងថ្មី';

  @override
  String get addNewBus => 'បន្ថែមឡានក្រុងថ្មី';

  @override
  String get addNewBusSubtitle => 'ចុះឈ្មោះឡានក្រុងទៅក្នុងកងនាវារបស់អ្នក';

  @override
  String get addStaffMember => 'បន្ថែមបុគ្គលិក';

  @override
  String get addStaffMemberSubtitle => 'ជួលអ្នកបើកបរ ឬអ្នកដឹកអ្នកដំណើរ';

  @override
  String get refresh => 'ធ្វើឱ្យស្រស់';

  @override
  String get signOut => 'ចាកចេញ';

  @override
  String operatorErrorWithMessage(String error) {
    return 'កំហុស: $error';
  }

  @override
  String get noBusesYet => 'មិនទាន់មានឡានក្រុងទេ';

  @override
  String get addYourFirstBus => 'បន្ថែមឡានក្រុងដំបូងរបស់អ្នកដើម្បីចាប់ផ្តើម';

  @override
  String get addBus => 'បន្ថែមឡានក្រុង';

  @override
  String busCapacity(int capacity) {
    return '$capacity កៅអី';
  }

  @override
  String get edit => 'កែសម្រួល';

  @override
  String get setActive => 'កំណត់ជាសកម្ម';

  @override
  String get underMaintenance => 'កំពុងថែទាំ';

  @override
  String get retireBus => 'ដកឡានក្រុងចេញ';

  @override
  String get status => 'ស្ថានភាព';

  @override
  String get busUpdated => 'ឡានក្រុងត្រូវបានធ្វើបច្ចុប្បន្នភាព ✅';

  @override
  String get busAdded => 'ឡានក្រុងត្រូវបានបន្ថែម ✅';

  @override
  String get editBus => 'កែសម្រួលឡានក្រុង';

  @override
  String get plateNumber => 'ស្លាកលេខ';

  @override
  String get plateNumberHint => 'ឧ. PP-1234-AA';

  @override
  String get required => 'តម្រូវ';

  @override
  String get busModel => 'ម៉ូដែលឡានក្រុង';

  @override
  String get busModelHint => 'ឧ. Hyundai Universe';

  @override
  String get seatCapacity => 'សមត្ថភាពកៅអី';

  @override
  String get seatCapacityHint => 'ឧ. 40';

  @override
  String get saveChanges => 'រក្សាទុកការផ្លាស់ប្តូរ';

  @override
  String failedToUpdate(String error) {
    return 'បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាព: $error';
  }

  @override
  String get deleteRoute => 'លុបផ្លូវ';

  @override
  String get deleteRouteConfirm =>
      'តើអ្នកប្រាកដទេ? នេះនឹងលុបកាលវិភាគដែលភ្ជាប់ផងដែរ។';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get delete => 'លុប';

  @override
  String get noRoutesYet => 'មិនទាន់មានផ្លូវទេ';

  @override
  String get addYourFirstRoute => 'បន្ថែមផ្លូវដំបូងរបស់អ្នកដើម្បីចាប់ផ្តើម';

  @override
  String get addRoute => 'បន្ថែមផ្លូវ';

  @override
  String distanceKmLabel(int distance) {
    return '$distance គ.ម';
  }

  @override
  String durationMinLabel(int duration) {
    return '$duration នាទី';
  }

  @override
  String get active => 'សកម្ម';

  @override
  String get inactive => 'អសកម្ម';

  @override
  String get deactivate => 'បិទ';

  @override
  String get activate => 'បើក';

  @override
  String get routeUpdated => 'ផ្លូវត្រូវបានធ្វើបច្ចុប្បន្នភាព ✅';

  @override
  String get routeCreated => 'ផ្លូវត្រូវបានបង្កើត ✅';

  @override
  String get editRoute => 'កែសម្រួលផ្លូវ';

  @override
  String get originCity => 'ទីក្រុងចេញដំណើរ';

  @override
  String get originCityHint => 'ឧ. ភ្នំពេញ';

  @override
  String get destinationCity => 'ទីក្រុងគោលដៅ';

  @override
  String get destinationCityHint => 'ឧ. សៀមរាប';

  @override
  String get distanceKmHint => '314';

  @override
  String get durationMinHint => '360';

  @override
  String get createRoute => 'បង្កើតផ្លូវ';

  @override
  String get deleteSchedule => 'លុបកាលវិភាគ';

  @override
  String get deleteScheduleConfirm => 'នេះនឹងលុបកាលវិភាគជាអចិន្ត្រៃយ៍។';

  @override
  String get confirm => 'បញ្ជាក់';

  @override
  String get noSchedulesYet => 'មិនទាន់មានកាលវិភាគទេ';

  @override
  String get createScheduleSubtitle =>
      'បង្កើតកាលវិភាគដើម្បីចាប់ផ្តើមទទួលការកក់';

  @override
  String get everyDay => 'រៀងរាល់ថ្ងៃ';

  @override
  String get weekdays => 'ថ្ងៃធ្វើការ';

  @override
  String get am => 'ព្រឹក';

  @override
  String get pm => 'ល្ងាច';

  @override
  String get scheduleActive => 'សកម្ម';

  @override
  String get cancelled => 'បានលុបចោល';

  @override
  String get departureLabel => 'ការចេញដំណើរ';

  @override
  String get arrivalLabel => 'ការមកដល់';

  @override
  String get perSeat => 'ក្នុងមួយកៅអី';

  @override
  String get addSchedule => 'បន្ថែមកាលវិភាគ';

  @override
  String get editSchedule => 'កែសម្រួលកាលវិភាគ';

  @override
  String get newSchedule => 'កាលវិភាគថ្មី';

  @override
  String get routeDropdown => 'ផ្លូវ';

  @override
  String get busDropdown => 'ឡានក្រុង';

  @override
  String get driverDropdown => 'អ្នកបើកបរ';

  @override
  String get conductorOptional => 'អ្នកដឹកអ្នកដំណើរ (ស្រេចចិត្ត)';

  @override
  String get noConductor => 'គ្មានអ្នកដឹកអ្នកដំណើរ';

  @override
  String get pricePerSeat => 'តម្លៃក្នុងមួយកៅអី (\$)';

  @override
  String get priceHint => 'ឧ. 12.00';

  @override
  String get operatingDays => 'ថ្ងៃប្រតិបត្តិការ';

  @override
  String get pleaseSelectRoute => 'សូមជ្រើសរើសផ្លូវ';

  @override
  String get pleaseSelectBus => 'សូមជ្រើសរើសឡានក្រុង';

  @override
  String get pleaseSelectDriver => 'សូមជ្រើសរើសអ្នកបើកបរ';

  @override
  String get pleaseEnterPrice => 'សូមបញ្ចូលតម្លៃ';

  @override
  String get pleaseSelectAtLeastOneDay => 'សូមជ្រើសរើសយ៉ាងហោចណាស់មួយថ្ងៃ';

  @override
  String get scheduleUpdated => 'កាលវិភាគត្រូវបានធ្វើបច្ចុប្បន្នភាព ✅';

  @override
  String get scheduleCreated => 'កាលវិភាគត្រូវបានបង្កើត ✅';

  @override
  String get createSchedule => 'បង្កើតកាលវិភាគ';

  @override
  String get staffActivated => 'បុគ្គលិកត្រូវបានបើដំណើរការ ✅';

  @override
  String get staffSuspended => 'បុគ្គលិកត្រូវបានផ្អាក ⛔';

  @override
  String driversTab(int count) {
    return 'អ្នកបើកបរ ($count)';
  }

  @override
  String conductorsTab(int count) {
    return 'អ្នកដឹកអ្នកដំណើរ ($count)';
  }

  @override
  String get noDriversYet => 'មិនទាន់មានអ្នកបើកបរទេ';

  @override
  String get addDriverSubtitle => 'បន្ថែមអ្នកបើកបរដើម្បីចាត់តាំងដំណើរ';

  @override
  String get noConductorsYet => 'មិនទាន់មានអ្នកដឹកអ្នកដំណើរទេ';

  @override
  String get addConductorSubtitle =>
      'បន្ថែមអ្នកដឹកអ្នកដំណើរដើម្បីគ្រប់គ្រងការឡើងឡាន';

  @override
  String get addDriver => 'បន្ថែមអ្នកបើកបរ';

  @override
  String get addConductor => 'បន្ថែមអ្នកដឹកអ្នកដំណើរ';

  @override
  String get activeStatus => 'សកម្ម';

  @override
  String get suspendedStatus => 'ផ្អាក';

  @override
  String get suspend => 'ផ្អាក';

  @override
  String get staffFullName => 'ឈ្មោះពេញ';

  @override
  String get staffFullNameHint => 'ឧ. សុខ ដារ៉ា';

  @override
  String get staffEmail => 'អ៊ីមែល';

  @override
  String get staffEmailHint => 'driver@example.com';

  @override
  String get invalidEmail => 'អ៊ីមែលមិនត្រឹមត្រូវ';

  @override
  String get staffPhone => 'ទូរស័ព្ទ';

  @override
  String get staffPhoneHint => '012 345 678';

  @override
  String get temporaryPassword => 'ពាក្យសម្ងាត់បណ្តោះអាសន្ន';

  @override
  String get min8Chars => 'យ៉ាងហោចណាស់ 8 តួ';

  @override
  String get staffInfoNote =>
      'ចែករំលែកអ៊ីមែល និងពាក្យសម្ងាត់ជាមួយបុគ្គលិក។ ពួកគេអាចផ្លាស់ប្តូរពាក្យសម្ងាត់របស់ពួកគេបន្ទាប់ពីចូល។';

  @override
  String get allSystemsNormal => 'ប្រព័ន្ធទាំងអស់ដំណើរការធម្មតា';

  @override
  String get allSystemsNormalSubtitle => 'យានជំនិះកងនាវាទាំងអស់ដំណើរការធម្មតា។';

  @override
  String get myCompany => 'ក្រុមហ៊ុនរបស់ខ្ញុំ';

  @override
  String get activeOperator => 'ប្រតិបត្តិករសកម្ម';

  @override
  String get superAdmin => 'អ្នកគ្រប់គ្រងកំពូល';

  @override
  String get systemControlPanel => 'ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ';

  @override
  String get systemOverview => 'ទិដ្ឋភាពទូទៅនៃប្រព័ន្ធ';

  @override
  String get allOperatorsAndUsers => 'ប្រតិបត្តិករ និងអ្នកប្រើប្រាស់ទាំងអស់';

  @override
  String get liveTrips => 'ដំណើរផ្ទាល់';

  @override
  String get todaysTrips => 'ដំណើរថ្ងៃនេះ';

  @override
  String get operatorsSection => 'ប្រតិបត្តិករ';

  @override
  String get usersSection => 'អ្នកប្រើប្រាស់';

  @override
  String get passengers => 'អ្នកដំណើរ';

  @override
  String get suspendOperatorConfirm =>
      'ការផ្អាកប្រតិបត្តិករនេះនឹងរារាំងឡានក្រុងរបស់ពួកគេពីការបង្ហាញក្នុងការស្វែងរក។ បន្ត?';

  @override
  String get reactivateOperatorConfirm =>
      'នេះនឹងបើកដំណើរការប្រតិបត្តិករ និងសេវាកម្មរបស់ពួកគេឡើងវិញ។ បន្ត?';

  @override
  String get operatorActivated => 'ប្រតិបត្តិករត្រូវបានបើកដំណើរការ ✅';

  @override
  String get operatorSuspended => 'ប្រតិបត្តិករត្រូវបានផ្អាក ⛔';

  @override
  String get allFilter => 'ទាំងអស់';

  @override
  String get activeFilter => 'សកម្ម';

  @override
  String get inactiveFilter => 'អសកម្ម';

  @override
  String get noOperatorsFound => 'រកមិនឃើញប្រតិបត្តិករ';

  @override
  String get addOperator => 'បន្ថែមប្រតិបត្តិករ';

  @override
  String get busesLabel => 'ឡានក្រុង';

  @override
  String get routesLabel => 'ផ្លូវ';

  @override
  String get staffLabel => 'បុគ្គលិក';

  @override
  String get addNewOperator => 'បន្ថែមប្រតិបត្តិករថ្មី';

  @override
  String get logo => 'ស្លាកសញ្ញា';

  @override
  String get companyName => 'ឈ្មោះក្រុមហ៊ុន';

  @override
  String get companyNameHint => 'ឧ. Capitol Express';

  @override
  String get contactNumber => 'លេខទំនាក់ទំនង';

  @override
  String get contactNumberHint => '+855 23 123 456';

  @override
  String get createOperator => 'បង្កើតប្រតិបត្តិករ';

  @override
  String get operatorCreated => 'ប្រតិបត្តិករត្រូវបានបង្កើត ✅';

  @override
  String get userActivated => 'អ្នកប្រើប្រាស់ត្រូវបានបើកដំណើរការ ✅';

  @override
  String get userSuspended => 'អ្នកប្រើប្រាស់ត្រូវបានផ្អាក ⛔';

  @override
  String get changeRole => 'ផ្លាស់ប្តូរតួនាទី';

  @override
  String get save => 'រក្សាទុក';

  @override
  String roleUpdated(String role) {
    return 'តួនាទីត្រូវបានធ្វើបច្ចុប្បន្នភាពទៅ $role ✅';
  }

  @override
  String get searchByNameOrEmail => 'ស្វែងរកតាមឈ្មោះ ឬអ៊ីមែល...';

  @override
  String get allRole => 'ទាំងអស់';

  @override
  String activeUsersTab(int count) {
    return 'សកម្ម ($count)';
  }

  @override
  String suspendedUsersTab(int count) {
    return 'ផ្អាក ($count)';
  }

  @override
  String get noUsersFound => 'រកមិនឃើញអ្នកប្រើប្រាស់';

  @override
  String get sortBy => 'តម្រៀបតាម:';

  @override
  String get sortDeparture => 'ការចេញដំណើរ';

  @override
  String get sortPrice => 'តម្លៃ';

  @override
  String get sortDuration => 'រយៈពេល';

  @override
  String get standardBus => 'ឡានក្រុងស្តង់ដារ';

  @override
  String get bookButton => 'កក់';

  @override
  String get noBusesFound => 'រកមិនឃើញឡានក្រុង';

  @override
  String noSchedulesMessage(String origin, String destination) {
    return 'រកមិនឃើញកាលវិភាគពី $origin ទៅ $destination នៅថ្ងៃនេះទេ។';
  }

  @override
  String get tryDifferentDate => 'សាកល្បងកាលបរិច្ឆេទផ្សេង';

  @override
  String get notifications => 'ការជូនដំណឹង';

  @override
  String get markAllRead => 'សម្គាល់ថាបានអានទាំងអស់';

  @override
  String get noNotificationsYet => 'មិនទាន់មានការជូនដំណឹងទេ';

  @override
  String get noNotificationsSubtitle =>
      'ការធ្វើបច្ចុប្បន្នភាពការកក់ និងការជូនដំណឹងអំពីដំណើរនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get justNow => 'ទើបតែឥឡូវ';

  @override
  String minutesAgo(int minutes) {
    return '$minutesន មុន';
  }

  @override
  String hoursAgo(int hours) {
    return '$hoursម៉ មុន';
  }

  @override
  String daysAgo(int days) {
    return '$daysថ មុន';
  }

  @override
  String get language => 'ភាសា';

  @override
  String get english => 'English';

  @override
  String get khmer => 'ភាសាខ្មែរ';
}
