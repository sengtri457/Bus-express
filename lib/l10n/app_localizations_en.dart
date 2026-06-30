// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bus Express';

  @override
  String get appSplashSubtitle => 'Premium Travel Made Simple';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signInSubtitle => 'Sign in to your account to continue booking';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String accountSuspended(String status) {
    return 'Your account has been $status. Please contact support.';
  }

  @override
  String get googleSignInFailed =>
      'Could not launch Google sign-in. Please try again.';

  @override
  String get googleSignInError => 'Google sign-in failed. Please try again.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordMinLength8 => 'Password must be at least 8 characters';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get signupSubtitle => 'Join us and book your rides easily';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get nameTooShort => 'Name too short';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get phoneNumberHint => '+855 12 345 678';

  @override
  String get phoneRequired => 'Phone is required';

  @override
  String get enterValidPhone => 'Enter a valid phone number';

  @override
  String get continueButton => 'Continue';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get emailAddressHint => 'you@example.com';

  @override
  String get atLeast8Chars => 'At least 8 characters';

  @override
  String get includeUppercase => 'Include at least one uppercase letter';

  @override
  String get includeNumber => 'Include at least one number';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => '••••••••';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get iAgreeTo => 'I agree to the ';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get andConjunction => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signInLink => 'Sign In';

  @override
  String get stepPersonal => 'Personal';

  @override
  String get stepAccount => 'Account';

  @override
  String get passwordStrengthLabel => 'Password strength';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordFair => 'Fair';

  @override
  String get passwordGood => 'Good';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get passwordStrengthHint =>
      'Use 8+ characters, uppercase, numbers & symbols for strong password';

  @override
  String get agreeTermsError => 'Please agree to the Terms & Conditions';

  @override
  String get registrationFailed => 'Registration failed. Please try again.';

  @override
  String get accountCreatedTitle => 'Account Created!';

  @override
  String verificationSent(String email) {
    return 'We sent a verification link to\n$email\n\nPlease verify your email before signing in.';
  }

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get forgotPasswordTitle => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle =>
      'No worries! Enter your email and we\'ll send you a reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLoginLink => 'Back to Login';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String resetLinkSent(String email) {
    return 'We sent a password reset link to\n$email';
  }

  @override
  String get infoStep1 => 'Open the email we sent you';

  @override
  String get infoStep2 => 'Click the \"Reset Password\" link';

  @override
  String get infoStep3 => 'Create a new strong password';

  @override
  String get didNotReceiveEmail => 'Didn\'t receive the email?';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String resendInCountdown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get setNewPasswordSubtitle =>
      'Your new password must be different from your previous password.';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get newPasswordHint => '••••••••';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get confirmNewPasswordHint => '••••••••';

  @override
  String get passwordsDoNotMatchValidator => 'Passwords do not match';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get enterValidEmailAddress => 'Please enter a valid email address';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get passwordResetTitle => 'Password Reset!';

  @override
  String get passwordResetBody =>
      'Your password has been updated successfully. Please sign in with your new password.';

  @override
  String get navBookBus => 'Book Bus';

  @override
  String get navMyTickets => 'My Tickets';

  @override
  String get navProfile => 'Profile';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navRoutes => 'Routes';

  @override
  String get navBuses => 'Buses';

  @override
  String get navSchedules => 'Schedules';

  @override
  String get navStaff => 'Staff';

  @override
  String get navOperators => 'Operators';

  @override
  String get navUsers => 'Users';

  @override
  String homeHelloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeWhereGoing => 'Where are you going today?';

  @override
  String get homeOurPartners => 'Our Partners';

  @override
  String get homePopularRoutes => 'Popular Routes';

  @override
  String get homeOriginLabel => 'Origin';

  @override
  String get homeOriginHint => 'From where?';

  @override
  String get homeDestinationLabel => 'Destination';

  @override
  String get homeDestinationHint => 'Where to?';

  @override
  String get homeTravelDate => 'Travel Date';

  @override
  String get homeSearchBuses => 'Search Buses';

  @override
  String get homeErrorOriginDestination =>
      'Please enter origin and destination';

  @override
  String get homeNoOperators => 'No operators available at the moment';

  @override
  String get profileMyProfile => 'My Profile';

  @override
  String profileErrorLoading(String error) {
    return 'Error loading profile: $error';
  }

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String profileFailedUpdate(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get profilePasswordUpdated => 'Password updated successfully!';

  @override
  String profileFailedPassword(String error) {
    return 'Failed to update password: $error';
  }

  @override
  String profileErrorSignOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get profilePersonalDetails => 'Personal Details';

  @override
  String get profileFullNameLabel => 'Full Name';

  @override
  String get profileFullNameHint => 'Enter your name';

  @override
  String get profileSaveDetails => 'Save Details';

  @override
  String get profileSecurityPassword => 'Security & Password';

  @override
  String get profileUpdatePassword => 'Update Password';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get scheduleSelectSeat => 'Select Seat';

  @override
  String get schedulePleaseSelectSeat => 'Please select at least one seat';

  @override
  String get scheduleAvailable => 'Available';

  @override
  String get scheduleSelected => 'Selected';

  @override
  String get scheduleBooked => 'Booked';

  @override
  String get scheduleTripEnded => 'This trip has ended / is completed.';

  @override
  String get scheduleTripCancelled => 'This trip has been cancelled.';

  @override
  String get scheduleTripOver =>
      'This trip is over / has departed (Time over).';

  @override
  String get scheduleNoSeatSelected => 'No seat selected';

  @override
  String scheduleSeatCount(int count, String seats) {
    return '$count seat(s): $seats';
  }

  @override
  String get scheduleContinue => 'Continue';

  @override
  String get scheduleFrontLabel => 'FRONT';

  @override
  String get scheduleDoorLabel => 'DOOR';

  @override
  String scheduleSeatsLeft(int count) {
    return '$count seats left';
  }

  @override
  String get scheduleBackLabel => 'BACK';

  @override
  String get bookingConfirmTitle => 'Confirm Booking';

  @override
  String get bookingTripDetails => 'Trip Details';

  @override
  String get bookingDate => 'Date';

  @override
  String get bookingSeats => 'Seats';

  @override
  String get bookingBus => 'Bus';

  @override
  String get bookingPassenger => 'Passenger';

  @override
  String get bookingUseSavedInfo => 'Use saved info';

  @override
  String get bookingEnterFullName => 'Enter your full name';

  @override
  String get bookingAgeLabel => 'Age';

  @override
  String get bookingEnterAge => 'Enter your age';

  @override
  String get bookingEnterValidAge => 'Enter a valid age';

  @override
  String get bookingPhoneLabel => 'Phone Number';

  @override
  String get bookingPhoneHelper =>
      'Include country code (e.g. +1XXXXXXXXX) for OTP';

  @override
  String get bookingEnterPhone => 'Enter your phone number';

  @override
  String get bookingIncludeCountryCode =>
      'Include country code (e.g. +1XXXXXXXXX)';

  @override
  String get bookingEnterValidPhone =>
      'Enter a valid phone number (8–15 digits)';

  @override
  String get bookingNationalityLabel => 'Nationality';

  @override
  String get bookingEnterNationality => 'Enter your nationality';

  @override
  String get bookingEmailHolder => 'Email';

  @override
  String get bookingEmailHelper => 'Receipt will be sent here';

  @override
  String get bookingEnterValidEmail => 'Enter a valid email address';

  @override
  String get bookingDetailsSaved =>
      'Your details are saved for future bookings';

  @override
  String get bookingPayment => 'Payment';

  @override
  String get bookingPromoCodeHint => 'Promo code';

  @override
  String get bookingPromoCodeRequired => 'Please enter a promo code';

  @override
  String get bookingPromoInvalid => 'Invalid promo code';

  @override
  String get bookingPromoInactive => 'This promo code is no longer active';

  @override
  String get bookingPromoExpired => 'This promo code has expired';

  @override
  String bookingMinPurchase(String amount) {
    return 'Minimum purchase of $amount required';
  }

  @override
  String get bookingPromoMaxUsage =>
      'This promo code has reached its usage limit';

  @override
  String bookingPromoPerUser(int used, int max) {
    return 'You have used this promo code $used out of $max times';
  }

  @override
  String bookingPromoPercentage(String value) {
    return '$value% OFF';
  }

  @override
  String bookingPromoFixed(String value) {
    return '\$$value OFF';
  }

  @override
  String get bookingPromoFailed => 'Failed to validate promo code';

  @override
  String get bookingPromoRemove => 'Remove';

  @override
  String get bookingPromoApply => 'Apply';

  @override
  String get bookingPricePerSeat => 'Price per seat';

  @override
  String get bookingNumberOfSeats => 'Number of seats';

  @override
  String get bookingDiscount => 'Discount';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingNotice =>
      'Arrive 15 minutes before departure. Show your QR ticket to the conductor when boarding.';

  @override
  String get bookingInvalidPhoneFormat => 'Invalid phone number format.';

  @override
  String get bookingInvalidPhoneMessage =>
      'Invalid phone number. Enter a real number with correct country code (e.g. +1234567890).';

  @override
  String get bookingInvalidEmail => 'Enter a valid email address.';

  @override
  String get bookingTripDeparted => 'already departed';

  @override
  String get bookingTripEnded => 'already ended';

  @override
  String get bookingTripCancelled => 'been cancelled';

  @override
  String bookingTripNotBookable(String reason) {
    return 'This trip has $reason and cannot be booked.';
  }

  @override
  String get bookingFailedCreateTrip =>
      'Failed to create trip. Check RLS policies on trips table.';

  @override
  String bookingFailedCreateBooking(String seat) {
    return 'Failed to create booking for seat $seat. Check RLS policies on bookings table.';
  }

  @override
  String get bookingNotificationTitle => 'Booking Confirmed';

  @override
  String bookingNotificationBody(
    int count,
    String origin,
    String destination,
    String time,
  ) {
    return '$count seat(s) on $origin → $destination ($time)';
  }

  @override
  String bookingFailedGeneric(String message) {
    return 'Booking failed: $message';
  }

  @override
  String get bookingReceiptSent => 'Receipt sent to your email';

  @override
  String get bookingConfirmButton => 'Confirm Booking';

  @override
  String bookingConfirmCountSeats(int count) {
    return 'Confirm $count Seats';
  }

  @override
  String get liveTrackingAppBar => 'Live Tracking';

  @override
  String get liveTripNotFound => 'Trip not found. It may have been cancelled.';

  @override
  String get liveCouldNotLoad =>
      'Could not load tracking data. Check your connection.';

  @override
  String get liveSomethingWrong => 'Something went wrong.';

  @override
  String get liveRetry => 'Retry';

  @override
  String get liveTooltipFollowBus => 'Follow bus';

  @override
  String get liveTooltipFollowingBus => 'Following bus';

  @override
  String get liveTripNotStarted => 'Trip Not Started Yet';

  @override
  String get liveTripNotStartedDesc =>
      'The bus will appear on the map once the driver starts the trip.';

  @override
  String get liveStatusOnWay => 'Bus is on the way';

  @override
  String get liveStatusLocating => 'Locating bus...';

  @override
  String get liveStatusCompleted => 'Trip completed';

  @override
  String get liveStatusCancelled => 'Trip cancelled';

  @override
  String get liveStatusWaiting => 'Waiting for departure';

  @override
  String liveDepartedAt(String time) {
    return 'Departed at $time';
  }

  @override
  String get liveBadge => 'LIVE';

  @override
  String get liveBusLocation => 'Bus Location';

  @override
  String get liveScheduledSchedule => 'Scheduled Schedule';

  @override
  String get liveEstimatedArrival => 'Estimated Arrival';

  @override
  String liveDelayMinutes(int delay) {
    return '+$delay min';
  }

  @override
  String get liveUpdatesEvery5 => 'Location updates every 5 seconds';

  @override
  String get liveTrackingStarts => 'Tracking starts when driver departs';

  @override
  String liveIncidentReported(String Type) {
    return '$Type Reported';
  }

  @override
  String get myTicketsTitle => 'My Tickets';

  @override
  String myTicketsUpcoming(int count) {
    return 'Upcoming ($count)';
  }

  @override
  String myTicketsPast(int count) {
    return 'Past ($count)';
  }

  @override
  String get myTicketsNoUpcoming => 'No upcoming trips';

  @override
  String get myTicketsNoUpcomingSub => 'Book a bus ticket to see it here';

  @override
  String get myTicketsNoPast => 'No past trips';

  @override
  String get myTicketsNoPastSub => 'Your completed trips will appear here';

  @override
  String get myTicketsSuccessSingular => 'Booking Confirmed!';

  @override
  String myTicketsSuccessPlural(int count) {
    return '$count Seats Confirmed!';
  }

  @override
  String get myTicketsSuccessDescSingular =>
      'Your ticket is ready. Show the QR code to the conductor when boarding.';

  @override
  String myTicketsSuccessDescPlural(int count) {
    return 'Your $count tickets are ready. Each seat has its own QR code.';
  }

  @override
  String get myTicketsViewSingular => 'View My Ticket';

  @override
  String get myTicketsViewPlural => 'View My Tickets';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptBusExpress => 'BUS EXPRESS';

  @override
  String get receiptOfficial => 'OFFICIAL RECEIPT';

  @override
  String get receiptReceiptNo => 'Receipt #';

  @override
  String get receiptIssued => 'Issued';

  @override
  String get receiptRoute => 'Route';

  @override
  String get receiptDeparture => 'Departure';

  @override
  String get receiptBookingDetails => 'Booking Details';

  @override
  String get receiptTableSeat => 'Seat';

  @override
  String get receiptTableStatus => 'Status';

  @override
  String get receiptTablePrice => 'Price';

  @override
  String get receiptTotal => 'Total: ';

  @override
  String get receiptThankYou => 'Thank you for traveling with Bus Express!';

  @override
  String get receiptKeepRecord =>
      'This is your official receipt. Please keep it for your records.';

  @override
  String get receiptShare => 'Share Receipt (PDF)';

  @override
  String get receiptGenerating => 'Generating...';

  @override
  String get promotionsTitle => 'All Promotions';

  @override
  String promotionsCopied(String code) {
    return 'Promo code \"$code\" copied!';
  }

  @override
  String get promotionsNoPromotions => 'No promotions available right now';

  @override
  String get promotionsNoPromotionsSub =>
      'Check back later for exciting offers!';

  @override
  String promotionsMinPurchase(String amount) {
    return 'Min. purchase: $amount';
  }

  @override
  String get cancelSheetTitle => 'Cancel Booking?';

  @override
  String get cancelSheetConfirm => 'Are you sure you want to cancel your trip?';

  @override
  String get cancelSheetRoute => 'Route';

  @override
  String get cancelSheetSeat => 'Seat';

  @override
  String get cancelSheetAmount => 'Amount';

  @override
  String get cancelSheetPolicy =>
      'Cancellations must be made at least 2 hours before departure. Trips already in progress cannot be cancelled.';

  @override
  String get cancelSheetKeep => 'Keep Booking';

  @override
  String get cancelSheetYesCancel => 'Yes, Cancel';

  @override
  String get cancelSuccessTitle => 'Booking Cancelled';

  @override
  String cancelSuccessDesc(String origin, String destination, String seat) {
    return 'Your booking for $origin → $destination (Seat $seat) has been cancelled.';
  }

  @override
  String get cancelSuccessNote =>
      'Your booking has been cancelled. If payment was made, the refund will be credited to your wallet.';

  @override
  String get cancelSheetDone => 'Done';

  @override
  String get offersSectionTitle => 'Offers for you';

  @override
  String get offersViewMore => 'View more';

  @override
  String get offersCategoryAll => 'All';

  @override
  String get offersCategoryBus => 'Bus';

  @override
  String get offersCategoryTrain => 'Train';

  @override
  String get offersNoOffers => 'No offers available for this category';

  @override
  String get popularRoutesNoRoutes => 'No routes available yet';

  @override
  String get routeSelectorTitle => 'Select Route';

  @override
  String get routeSelectorSearchHint => 'Search destinations...';

  @override
  String get routeSelectorNoRoutes => 'No routes available';

  @override
  String routeSelectorNoMatch(String query) {
    return 'No routes match \"$query\"';
  }

  @override
  String get ticketCardNewBooking => 'New Booking';

  @override
  String ticketCardSeats(int count) {
    return '$count seats';
  }

  @override
  String get ticketCardTrackLive => 'Track Live';

  @override
  String get ticketCardTrackBus => 'Track Bus';

  @override
  String get ticketCardViewQrSingular => 'Tap to view QR code';

  @override
  String ticketCardViewQrPlural(int count) {
    return 'Tap to view $count QR codes';
  }

  @override
  String get ticketCardViewReceipt => 'View Receipt';

  @override
  String get ticketDetailTrackLive => 'Track Live';

  @override
  String get ticketDetailTrackBus => 'Track Bus';

  @override
  String get ticketDetailCancelTooLate =>
      'Cannot cancel — departure is less than 2 hours away.';

  @override
  String get ticketDetailCancelledSingular => 'Booking cancelled';

  @override
  String ticketDetailCancelledPlural(int count) {
    return '$count bookings cancelled';
  }

  @override
  String ticketDetailErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get ticketDetailConfirmCancelTitleSingular => 'Cancel Booking?';

  @override
  String ticketDetailConfirmCancelTitlePlural(int count) {
    return 'Cancel $count Seats?';
  }

  @override
  String get ticketDetailConfirmPolicy =>
      'Cancellations must be made at least 2 hours before departure.';

  @override
  String get ticketDetailKeepIt => 'Keep It';

  @override
  String get ticketDetailYesCancel => 'Yes, Cancel';

  @override
  String ticketDetailSeatCount(int count) {
    return '$count seat(s)';
  }

  @override
  String ticketDetailTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String ticketDetailCancelAll(int count) {
    return 'Cancel All $count Seats';
  }

  @override
  String get ticketDetailCancelBooking => 'Cancel Booking';

  @override
  String ticketDetailSeatTab(String seat) {
    return 'Seat $seat';
  }

  @override
  String get ticketDetailDeparture => 'Departure';

  @override
  String get ticketDetailArrival => 'Arrival';

  @override
  String get ticketDetailTicketPrice => 'Ticket price';

  @override
  String get ticketDetailPayment => 'Payment';

  @override
  String get ticketDetailQrError => 'QR Error';

  @override
  String get ticketDetailStatusUsed => 'Ticket already used';

  @override
  String get ticketDetailStatusCancelled => 'Ticket cancelled';

  @override
  String get ticketDetailStatusExpired => 'Ticket expired';

  @override
  String get ticketDetailStatusNoData => 'No ticket data';

  @override
  String get ticketDetailInfoValid =>
      'Show this QR code to the conductor when boarding.';

  @override
  String get ticketDetailInfoUsed =>
      'This ticket has already been used for boarding.';

  @override
  String get ticketDetailInfoCancelled => 'This booking has been cancelled.';

  @override
  String get ticketDetailInfoExpired => 'This ticket has expired.';

  @override
  String get ticketDetailInfoUnknown => 'Ticket status is unknown.';

  @override
  String get cancelServiceSuccess => 'Booking cancelled successfully.';

  @override
  String get cancelServiceTooLate =>
      'Cannot cancel — departure is less than 2 hours away.';

  @override
  String get cancelServiceAlreadyBoarded =>
      'Cannot cancel — you have already boarded this bus.';

  @override
  String get cancelServiceAlreadyCancelled =>
      'This booking is already cancelled.';

  @override
  String get cancelServiceTripStarted =>
      'Cannot cancel — the trip has already started or completed.';

  @override
  String get cancelServiceError => 'Something went wrong. Please try again.';

  @override
  String driverHomeHello(String name) {
    return 'Hello, $name';
  }

  @override
  String get driverHomeDashboard => 'Driver Dashboard';

  @override
  String get driverHomeTodaysTrip => 'Today\'s Trip';

  @override
  String get driverHomeNoTripToday => 'No trip today';

  @override
  String get driverHomeNoTripSubtitle =>
      'You have no scheduled trips for today';

  @override
  String get driverHomeUpcomingTrips => 'Upcoming Trips';

  @override
  String get driverHomeQuickStats => 'Quick Stats';

  @override
  String get driverHomeStatTotalTrips => 'Total Trips';

  @override
  String get driverHomeStatCompleted => 'Completed';

  @override
  String get driverHomeStatPassengers => 'Passengers';

  @override
  String get driverHomeFailedLoad => 'Failed to load data';

  @override
  String get driverHomeRetry => 'Retry';

  @override
  String get driverTripAppBarTitle => 'Trip Management';

  @override
  String get driverTripReportIncident => 'Report Incident';

  @override
  String get driverTripRouteLabel => 'Route';

  @override
  String get driverTripBusLabel => 'Bus';

  @override
  String get driverTripDateLabel => 'Date';

  @override
  String get driverTripStatusReady => 'Ready to Depart';

  @override
  String get driverTripStatusInProgress => 'Trip In Progress';

  @override
  String get driverTripStatusCompleted => 'Trip Completed';

  @override
  String get driverTripStatusCancelled => 'Trip Cancelled';

  @override
  String get driverTripStatusUnknown => 'Unknown';

  @override
  String driverTripDepartedAt(String time) {
    return 'Departed at $time';
  }

  @override
  String driverTripArrivedAt(String time) {
    return 'Arrived at $time';
  }

  @override
  String get driverTripTapStart => 'Tap \"Start Trip\" when ready';

  @override
  String get driverTripGpsActive => 'GPS Tracking Active';

  @override
  String get driverTripPassengersTitle => 'Passengers';

  @override
  String driverTripPassengerCount(int boarded, int total) {
    return '$boarded/$total boarded';
  }

  @override
  String get driverTripNoPassengers => 'No passengers booked yet';

  @override
  String driverTripSeatInfo(String number, String phone) {
    return 'Seat $number • $phone';
  }

  @override
  String get driverTripUnknownPassenger => 'Unknown Passenger';

  @override
  String get driverTripStartTripBtn => 'Start Trip';

  @override
  String get driverTripEndTripArrivedBtn => 'End Trip (Arrived)';

  @override
  String driverTripEndTripCountdown(String countdown) {
    return 'End Trip (ready in $countdown)';
  }

  @override
  String get driverTripStartDialogTitle => 'Start Trip';

  @override
  String get driverTripStartDialogMessage =>
      'Are you ready to depart? This will notify all passengers.';

  @override
  String get driverTripStartNowLabel => 'Start Now';

  @override
  String get driverTripEndDialogTitle => 'End Trip';

  @override
  String driverTripEndDialogMessageDelay(int delay) {
    return 'Trip was delayed by $delay min due to incidents. Confirm arrival?';
  }

  @override
  String get driverTripEndDialogMessageNormal =>
      'Confirm you have arrived at the destination?';

  @override
  String get driverTripEndTripLabel => 'End Trip';

  @override
  String get driverTripCancel => 'Cancel';

  @override
  String driverTripBusNotFull(int boarded, int capacity) {
    return 'Bus is not full ($boarded/$capacity). Waiting for Conductor permission.';
  }

  @override
  String get driverTripStartedSnack => 'Trip started! GPS tracking active.';

  @override
  String driverTripFailedStart(String error) {
    return 'Failed to start trip: $error';
  }

  @override
  String driverTripWaitCountdown(String time, String countdown) {
    return 'Arrival at $time. Please wait $countdown to end the trip.';
  }

  @override
  String get driverTripCompletedSnack => 'Trip completed successfully!';

  @override
  String driverTripFailedEnd(String error) {
    return 'Failed to end trip: $error';
  }

  @override
  String get driverTripNotificationTitle => 'Trip Started';

  @override
  String driverTripNotificationBody(String origin, String destination) {
    return 'Your bus from $origin → $destination has departed! Track it live.';
  }

  @override
  String get driverTripNA => 'N/A';

  @override
  String driverTripDelayInfo(int delay, int count) {
    return '$delay min delay ($count incident(s))';
  }

  @override
  String driverTripAdjustedEta(String time) {
    return 'Adjusted ETA: $time';
  }

  @override
  String get driverTripOverdue => 'Overdue';

  @override
  String get driverTripTimeFallback => '--:--';

  @override
  String get driverIncidentAppBarTitle => 'Report Incident';

  @override
  String get driverIncidentHeaderWarning =>
      'Report any incidents that affect this trip immediately. Your report will be sent to the operator.';

  @override
  String get driverIncidentTypeLabel => 'Incident Type';

  @override
  String get driverIncidentTypeDelay => 'Delay';

  @override
  String get driverIncidentTypeBreakdown => 'Breakdown';

  @override
  String get driverIncidentTypeAccident => 'Accident';

  @override
  String get driverIncidentTypeOther => 'Other';

  @override
  String get driverIncidentLocationLabel => 'Incident Location';

  @override
  String get driverIncidentDetectingLocation => 'Detecting location...';

  @override
  String get driverIncidentAccessingGps => 'Accessing GPS...';

  @override
  String get driverIncidentGpsDenied => 'GPS Permission Denied';

  @override
  String get driverIncidentResolvingAddress => 'Resolving address...';

  @override
  String get driverIncidentUnknownLocation => 'Unknown Location';

  @override
  String get driverIncidentFailedDetect => 'Failed to detect location';

  @override
  String get driverIncidentAutoDetecting => 'Auto-detecting Location...';

  @override
  String get driverIncidentAutoDetected => 'Auto-detected Location';

  @override
  String get driverIncidentLocationService => 'Location Service';

  @override
  String get driverIncidentRefreshLocation => 'Refresh Location';

  @override
  String get driverIncidentDescriptionLabel => 'Description';

  @override
  String get driverIncidentHintText =>
      'Describe what happened in detail...\n\ne.g. \"Bus broke down near Kampong Thom, waiting for repair. Estimated delay: 30 minutes.\"';

  @override
  String get driverIncidentSubmitReport => 'Submit Report';

  @override
  String get driverIncidentPleaseDescribe => 'Please describe the incident';

  @override
  String get driverIncidentNotLoggedIn => 'Not logged in';

  @override
  String get driverIncidentReportedTitle => 'Incident Reported';

  @override
  String get driverIncidentReportedMessage =>
      'Your incident report has been submitted successfully.';

  @override
  String get driverIncidentOK => 'OK';

  @override
  String driverIncidentFailedError(String message) {
    return 'Failed: $message';
  }

  @override
  String get driverIncidentIssueFallback => 'Issue';

  @override
  String get driverIncidentPreviousReports => 'Previous Reports This Trip';

  @override
  String driverIncidentNotificationTitle(String type) {
    return 'Trip Alert: $type';
  }

  @override
  String driverIncidentNotificationBody(String type, int delay) {
    return 'Your bus reported a $type. Estimated delay: $delay min. We apologize for the inconvenience.';
  }

  @override
  String get activeTripAppBarTitle => 'Active Trip';

  @override
  String get activeTripGpsNotStarted => 'GPS not started';

  @override
  String get activeTripRequestingPermission =>
      'Requesting location permission…';

  @override
  String get activeTripGpsDisabled =>
      'Location service is disabled. Enable it in Settings.';

  @override
  String get activeTripPermissionDenied =>
      'Location permission denied. Enable it in Settings.';

  @override
  String activeTripPermissionFailed(String error) {
    return 'Permission check failed: $error';
  }

  @override
  String get activeTripGpsActiveMessage => 'GPS active – tracking location';

  @override
  String activeTripGpsPositionError(String error) {
    return 'Could not get GPS position: $error';
  }

  @override
  String get activeTripGpsSignalLost => 'GPS signal lost. Retrying…';

  @override
  String get activeTripGpsStopped => 'GPS stopped';

  @override
  String get activeTripCouldNotStart => 'Could not start trip. Try again.';

  @override
  String get activeTripCouldNotEnd => 'Could not end trip. Try again.';

  @override
  String get activeTripEndDialogTitle => 'End this trip?';

  @override
  String get activeTripEndDialogMessage =>
      'Make sure all passengers have boarded. This cannot be undone.';

  @override
  String get activeTripEndTripLabel => 'End trip';

  @override
  String get activeTripCompletedSnack => 'Trip completed. Great job!';

  @override
  String get activeTripTripStatus => 'Trip Status';

  @override
  String get activeTripDepartedLabel => 'Departed';

  @override
  String get activeTripArrivedLabel => 'Arrived';

  @override
  String get activeTripGpsTracking => 'GPS Tracking';

  @override
  String get activeTripCoordLat => 'LAT';

  @override
  String get activeTripCoordLng => 'LNG';

  @override
  String get activeTripCoordAcc => 'ACC';

  @override
  String get activeTripStartTrip => 'Start Trip';

  @override
  String get activeTripPleaseWait => 'Please wait…';

  @override
  String get activeTripCompletedBadge => 'Trip Completed';

  @override
  String activeTripArrivedAt(String time) {
    return 'Arrived at $time';
  }

  @override
  String activeTripTimeFormatHm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String activeTripTimeFormatM(int m) {
    return '${m}m';
  }

  @override
  String get tripPunctScheduled => 'Scheduled';

  @override
  String get tripPunctDelayedDeparture => 'Delayed Departure';

  @override
  String tripPunctOverdueMins(int minutes) {
    return 'Overdue by $minutes mins';
  }

  @override
  String get tripPunctOnTime => 'On Time';

  @override
  String get tripPunctReadyDepart => 'Ready to depart on time';

  @override
  String get tripPunctOnTrack => 'On Track';

  @override
  String get tripPunctInProgress => 'Trip in progress';

  @override
  String tripPunctDepartedLate(int minutes) {
    return 'Departed $minutes mins late';
  }

  @override
  String tripPunctDepartedEarly(int minutes) {
    return 'Departed $minutes mins early';
  }

  @override
  String get tripPunctDepartedOnTime => 'Departed on time';

  @override
  String get tripPunctRunningLate => 'Running Late';

  @override
  String get tripPunctDelayed => 'Delayed';

  @override
  String get tripPunctCompleted => 'Completed';

  @override
  String get tripPunctTripFinished => 'Trip finished';

  @override
  String tripPunctArrivedAt(String time) {
    return 'Arrived at $time';
  }

  @override
  String tripPunctArrivedLate(int minutes) {
    return 'Arrived $minutes mins late';
  }

  @override
  String tripPunctArrivedEarly(int minutes) {
    return 'Arrived $minutes mins early';
  }

  @override
  String get tripPunctArrivedOnTime => 'Arrived on time';

  @override
  String get tripPunctDelayedArrival => 'Delayed Arrival';

  @override
  String get tripPunctOnTimeArrival => 'On Time Arrival';

  @override
  String get tripPunctCancelled => 'Cancelled';

  @override
  String get tripPunctMessageCancelled => 'Trip was cancelled';

  @override
  String tripPunctTripStatus(String status) {
    return 'Trip status: $status';
  }

  @override
  String get tripPunctErrorComputing => 'Error computing status';

  @override
  String get todayTripCardTapToManage => 'Tap to manage';

  @override
  String todayTripCardDurationMin(int minutes) {
    return '$minutes min';
  }

  @override
  String todayTripCardDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String todayTripCardBusInfo(String model, String plate) {
    return '$model • $plate';
  }

  @override
  String todayTripCardCapacity(int capacity) {
    return '$capacity seats';
  }

  @override
  String get todayTripCardNoSchedule => 'No schedule assigned';

  @override
  String get todayTripCardNoScheduleDesc =>
      'This trip has no schedule linked.\nContact your operator to fix it.';

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
    return 'Hello, $name';
  }

  @override
  String get conductorHomeDashboard => 'Conductor Dashboard';

  @override
  String get conductorHomeQuickActions => 'Quick Actions';

  @override
  String get conductorHomeScanTicket => 'Scan Ticket';

  @override
  String get conductorHomePassengerList => 'Passenger List';

  @override
  String get conductorHomeStatTotal => 'Total';

  @override
  String get conductorHomeStatBoarded => 'Boarded';

  @override
  String get conductorHomeStatWaiting => 'Waiting';

  @override
  String get conductorHomeTodaysTrip => 'Today\'s Trip';

  @override
  String get conductorHomeNoTripToday => 'No trip today';

  @override
  String get conductorHomeNoTripSubtitle =>
      'You have no assigned trips for today';

  @override
  String get conductorPassAppBarTitle => 'Passenger List';

  @override
  String conductorPassRoute(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String conductorPassBoardedProgress(int boarded, int total) {
    return '$boarded / $total boarded';
  }

  @override
  String conductorPassFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String conductorPassFilterWaiting(int count) {
    return 'Waiting ($count)';
  }

  @override
  String conductorPassFilterBoarded(int count) {
    return 'Boarded ($count)';
  }

  @override
  String get conductorPassNoPassengers => 'No passengers booked';

  @override
  String conductorPassNoFilterPassengers(String status) {
    return 'No $status passengers';
  }

  @override
  String get conductorPassMarkedBoarded => 'Passenger marked as boarded ✅';

  @override
  String conductorPassError(String error) {
    return 'Error: $error';
  }

  @override
  String get conductorPassTripStartAllowed =>
      'Trip start allowed by conductor ✅';

  @override
  String get conductorPassAllowStart => 'Allow Trip Start';

  @override
  String get conductorPassUnknownPassenger => 'Unknown';

  @override
  String conductorPassSeatInfo(String number, String phone) {
    return 'Seat $number • $phone';
  }

  @override
  String get conductorPassWalkin => 'Walk-in';

  @override
  String get conductorPassStatusBoarded => 'Boarded';

  @override
  String get conductorPassBoardBtn => 'Board';

  @override
  String get conductorPassRLSError =>
      'Update blocked by Supabase RLS policy. Conductor role cannot update trips.';

  @override
  String get conductorScanAppBarTitle => 'Scan Ticket';

  @override
  String get conductorScanInvalidQr => 'Invalid QR Code';

  @override
  String get conductorScanTicketNotFound =>
      'This ticket was not found in the system.';

  @override
  String get conductorScanNoBooking => 'No Booking Found';

  @override
  String get conductorScanNoBookingDesc =>
      'This ticket is not associated with a booking.';

  @override
  String get conductorScanWrongTrip => 'Wrong Trip';

  @override
  String get conductorScanWrongTripDesc =>
      'This ticket is not for this trip. Please check the bus.';

  @override
  String get conductorScanAlreadyScanned => 'Already Scanned';

  @override
  String conductorScanScannedAt(String time) {
    return 'Scanned at $time';
  }

  @override
  String get conductorScanAlreadyUsed => 'This ticket has already been used.';

  @override
  String get conductorScanInvalidTicket => 'Invalid Ticket';

  @override
  String conductorScanTicketStatusInvalid(String status) {
    return 'This ticket is $status and cannot be used.';
  }

  @override
  String get conductorScanBoardedSuccess => 'Boarded! ✅';

  @override
  String conductorScanPassengerSeat(String name, String number) {
    return '$name • Seat $number';
  }

  @override
  String get conductorScanScanError => 'Scan Error';

  @override
  String get conductorScanProcessing => 'Processing...';

  @override
  String get conductorScanHintText => 'Point camera at passenger QR code';

  @override
  String get conductorScanNotifTitle => 'Ticket Validated';

  @override
  String conductorScanNotifBody(String seat) {
    return 'Your ticket for seat $seat has been scanned. Enjoy your trip!';
  }

  @override
  String get operatorPanel => 'Operator Panel';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get todaysSummary => 'Today\'s Summary';

  @override
  String get statActive => 'Active';

  @override
  String get statInactive => 'Inactive';

  @override
  String get statBookings => 'Bookings';

  @override
  String get statUpcomingTrips => 'Upcoming Trips';

  @override
  String get fleetOverview => 'Fleet Overview';

  @override
  String get statActiveBuses => 'Active Buses';

  @override
  String get statActiveRoutes => 'Active Routes';

  @override
  String get statSchedules => 'Schedules';

  @override
  String get statStaff => 'Staff';

  @override
  String get fleetAlerts => 'Fleet Alerts';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get addNewRoute => 'Add New Route';

  @override
  String get addNewRouteSubtitle => 'Create a new bus route';

  @override
  String get addNewBus => 'Add New Bus';

  @override
  String get addNewBusSubtitle => 'Register a bus to your fleet';

  @override
  String get addStaffMember => 'Add Staff Member';

  @override
  String get addStaffMemberSubtitle => 'Hire a driver or conductor';

  @override
  String get refresh => 'Refresh';

  @override
  String get signOut => 'Sign out';

  @override
  String operatorErrorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get noBusesYet => 'No buses yet';

  @override
  String get addYourFirstBus => 'Add your first bus to get started';

  @override
  String get addBus => 'Add Bus';

  @override
  String busCapacity(int capacity) {
    return '$capacity seats';
  }

  @override
  String get edit => 'Edit';

  @override
  String get setActive => 'Set Active';

  @override
  String get underMaintenance => 'Under Maintenance';

  @override
  String get retireBus => 'Retire Bus';

  @override
  String get status => 'Status';

  @override
  String get busUpdated => 'Bus updated ✅';

  @override
  String get busAdded => 'Bus added ✅';

  @override
  String get editBus => 'Edit Bus';

  @override
  String get plateNumber => 'Plate Number';

  @override
  String get plateNumberHint => 'e.g. PP-1234-AA';

  @override
  String get required => 'Required';

  @override
  String get busModel => 'Bus Model';

  @override
  String get busModelHint => 'e.g. Hyundai Universe';

  @override
  String get seatCapacity => 'Seat Capacity';

  @override
  String get seatCapacityHint => 'e.g. 40';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String failedToUpdate(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get deleteRoute => 'Delete Route';

  @override
  String get deleteRouteConfirm =>
      'Are you sure? This will also remove associated schedules.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noRoutesYet => 'No routes yet';

  @override
  String get addYourFirstRoute => 'Add your first route to get started';

  @override
  String get addRoute => 'Add Route';

  @override
  String distanceKmLabel(int distance) {
    return '$distance km';
  }

  @override
  String durationMinLabel(int duration) {
    return '$duration min';
  }

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get activate => 'Activate';

  @override
  String get routeUpdated => 'Route updated ✅';

  @override
  String get routeCreated => 'Route created ✅';

  @override
  String get editRoute => 'Edit Route';

  @override
  String get originCity => 'Origin City';

  @override
  String get originCityHint => 'e.g. Phnom Penh';

  @override
  String get destinationCity => 'Destination City';

  @override
  String get destinationCityHint => 'e.g. Siem Reap';

  @override
  String get distanceKmHint => '314';

  @override
  String get durationMinHint => '360';

  @override
  String get createRoute => 'Create Route';

  @override
  String get deleteSchedule => 'Delete Schedule';

  @override
  String get deleteScheduleConfirm =>
      'This will remove the schedule permanently.';

  @override
  String get confirm => 'Confirm';

  @override
  String get noSchedulesYet => 'No schedules yet';

  @override
  String get createScheduleSubtitle =>
      'Create a schedule to start taking bookings';

  @override
  String get everyDay => 'Every day';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get scheduleActive => 'Active';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get departureLabel => 'Departure';

  @override
  String get arrivalLabel => 'Arrival';

  @override
  String get perSeat => 'per seat';

  @override
  String get addSchedule => 'Add Schedule';

  @override
  String get editSchedule => 'Edit Schedule';

  @override
  String get newSchedule => 'New Schedule';

  @override
  String get routeDropdown => 'Route';

  @override
  String get busDropdown => 'Bus';

  @override
  String get driverDropdown => 'Driver';

  @override
  String get conductorOptional => 'Conductor (optional)';

  @override
  String get noConductor => 'No conductor';

  @override
  String get pricePerSeat => 'Price per seat (\$)';

  @override
  String get priceHint => 'e.g. 12.00';

  @override
  String get operatingDays => 'Operating Days';

  @override
  String get pleaseSelectRoute => 'Please select a route';

  @override
  String get pleaseSelectBus => 'Please select a bus';

  @override
  String get pleaseSelectDriver => 'Please select a driver';

  @override
  String get pleaseEnterPrice => 'Please enter a price';

  @override
  String get pleaseSelectAtLeastOneDay => 'Please select at least one day';

  @override
  String get scheduleUpdated => 'Schedule updated ✅';

  @override
  String get scheduleCreated => 'Schedule created ✅';

  @override
  String get createSchedule => 'Create Schedule';

  @override
  String get staffActivated => 'Staff activated ✅';

  @override
  String get staffSuspended => 'Staff suspended ⛔';

  @override
  String driversTab(int count) {
    return 'Drivers ($count)';
  }

  @override
  String conductorsTab(int count) {
    return 'Conductors ($count)';
  }

  @override
  String get noDriversYet => 'No drivers yet';

  @override
  String get addDriverSubtitle => 'Add a driver to assign to trips';

  @override
  String get noConductorsYet => 'No conductors yet';

  @override
  String get addConductorSubtitle => 'Add a conductor to manage boarding';

  @override
  String get addDriver => 'Add Driver';

  @override
  String get addConductor => 'Add Conductor';

  @override
  String get activeStatus => 'Active';

  @override
  String get suspendedStatus => 'Suspended';

  @override
  String get suspend => 'Suspend';

  @override
  String get staffFullName => 'Full Name';

  @override
  String get staffFullNameHint => 'e.g. Sok Dara';

  @override
  String get staffEmail => 'Email';

  @override
  String get staffEmailHint => 'driver@example.com';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get staffPhone => 'Phone';

  @override
  String get staffPhoneHint => '012 345 678';

  @override
  String get temporaryPassword => 'Temporary Password';

  @override
  String get min8Chars => 'Min 8 characters';

  @override
  String get staffInfoNote =>
      'Share the email and password with the staff member. They can change their password after logging in.';

  @override
  String get allSystemsNormal => 'All Systems Normal';

  @override
  String get allSystemsNormalSubtitle =>
      'All fleet vehicles operating normally.';

  @override
  String get myCompany => 'My Company';

  @override
  String get activeOperator => 'Active Operator';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get systemControlPanel => 'System Control Panel';

  @override
  String get systemOverview => 'System Overview';

  @override
  String get allOperatorsAndUsers => 'All operators & users';

  @override
  String get liveTrips => 'Live Trips';

  @override
  String get todaysTrips => 'Today\'s Trips';

  @override
  String get operatorsSection => 'Operators';

  @override
  String get usersSection => 'Users';

  @override
  String get passengers => 'Passengers';

  @override
  String get suspendOperatorConfirm =>
      'Suspending this operator will prevent their buses from appearing in searches. Continue?';

  @override
  String get reactivateOperatorConfirm =>
      'This will reactivate the operator and their services. Continue?';

  @override
  String get operatorActivated => 'Operator activated ✅';

  @override
  String get operatorSuspended => 'Operator suspended ⛔';

  @override
  String get allFilter => 'All';

  @override
  String get activeFilter => 'Active';

  @override
  String get inactiveFilter => 'Inactive';

  @override
  String get noOperatorsFound => 'No operators found';

  @override
  String get addOperator => 'Add Operator';

  @override
  String get busesLabel => 'Buses';

  @override
  String get routesLabel => 'Routes';

  @override
  String get staffLabel => 'Staff';

  @override
  String get addNewOperator => 'Add New Operator';

  @override
  String get logo => 'Logo';

  @override
  String get companyName => 'Company Name';

  @override
  String get companyNameHint => 'e.g. Capitol Express';

  @override
  String get contactNumber => 'Contact Number';

  @override
  String get contactNumberHint => '+855 23 123 456';

  @override
  String get createOperator => 'Create Operator';

  @override
  String get operatorCreated => 'Operator created ✅';

  @override
  String get userActivated => 'User activated ✅';

  @override
  String get userSuspended => 'User suspended ⛔';

  @override
  String get changeRole => 'Change Role';

  @override
  String get save => 'Save';

  @override
  String roleUpdated(String role) {
    return 'Role updated to $role ✅';
  }

  @override
  String get searchByNameOrEmail => 'Search by name or email...';

  @override
  String get allRole => 'All';

  @override
  String activeUsersTab(int count) {
    return 'Active ($count)';
  }

  @override
  String suspendedUsersTab(int count) {
    return 'Suspended ($count)';
  }

  @override
  String get noUsersFound => 'No users found';

  @override
  String get sortBy => 'Sort by:';

  @override
  String get sortDeparture => 'Departure';

  @override
  String get sortPrice => 'Price';

  @override
  String get sortDuration => 'Duration';

  @override
  String get standardBus => 'Standard Bus';

  @override
  String get bookButton => 'Book';

  @override
  String get noBusesFound => 'No buses found';

  @override
  String noSchedulesMessage(String origin, String destination) {
    return 'No schedules from $origin to $destination on this date.';
  }

  @override
  String get tryDifferentDate => 'Try Different Date';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get noNotificationsSubtitle =>
      'Booking updates and trip alerts will appear here.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get khmer => 'ភាសាខ្មែរ';
}
