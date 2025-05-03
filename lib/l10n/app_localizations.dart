import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
    Locale('en')
  ];

  /// No description provided for @textappLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get textappLanguage;

  /// No description provided for @textareYouSureYouWantToSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get textareYouSureYouWantToSignOut;

  /// No description provided for @textcancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get textcancel;

  /// No description provided for @textclearCompletedItems.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed Items'**
  String get textclearCompletedItems;

  /// No description provided for @textclearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed'**
  String get textclearCompleted;

  /// No description provided for @textclearItems.
  ///
  /// In en, this message translates to:
  /// **'Clear Items'**
  String get textclearItems;

  /// No description provided for @textclearedCompletedItems.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} completed items'**
  String textclearedCompletedItems(int count);

  /// No description provided for @textcouldNotOpenPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Could not open Play Store'**
  String get textcouldNotOpenPlayStore;

  /// No description provided for @textcreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get textcreate;

  /// No description provided for @textdarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get textdarkMode;

  /// No description provided for @textdeleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete List'**
  String get textdeleteList;

  /// No description provided for @textdelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get textdelete;

  /// No description provided for @textenableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get textenableNotifications;

  /// No description provided for @textenglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get textenglish;

  /// No description provided for @texterrorDeletingList.
  ///
  /// In en, this message translates to:
  /// **'Error deleting list: {error}'**
  String texterrorDeletingList(String error);

  /// No description provided for @texterrorFetchingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error fetching maintenance status: {error}'**
  String texterrorFetchingStatus(String error);

  /// No description provided for @texterrorSharingList.
  ///
  /// In en, this message translates to:
  /// **'Error sharing list: {error}'**
  String texterrorSharingList(String error);

  /// No description provided for @textexportList.
  ///
  /// In en, this message translates to:
  /// **'Export List'**
  String get textexportList;

  /// No description provided for @textfailedToSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Google'**
  String get textfailedToSignInWithGoogle;

  /// No description provided for @textlistDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'List deleted successfully'**
  String get textlistDeletedSuccessfully;

  /// No description provided for @textloading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get textloading;

  /// No description provided for @textowner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get textowner;

  /// No description provided for @textpleaseEnterATaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task title'**
  String get textpleaseEnterATaskTitle;

  /// No description provided for @textprivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get textprivacyPolicy;

  /// No description provided for @textprofileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get textprofileUpdatedSuccessfully;

  /// No description provided for @textrenameList.
  ///
  /// In en, this message translates to:
  /// **'Rename List'**
  String get textrenameList;

  /// No description provided for @textsaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get textsaveChanges;

  /// No description provided for @textsave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get textsave;

  /// No description provided for @textselectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get textselectLanguage;

  /// No description provided for @textsettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get textsettings;

  /// No description provided for @textsignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get textsignOut;

  /// No description provided for @texttoggleDarklightTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle dark/light theme'**
  String get texttoggleDarklightTheme;

  /// No description provided for @textuserAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User added successfully'**
  String get textuserAddedSuccessfully;

  /// No description provided for @textuserAlreadyHasAccessToThisList.
  ///
  /// In en, this message translates to:
  /// **'User already has access to this list'**
  String get textuserAlreadyHasAccessToThisList;

  /// No description provided for @textuserRemoved.
  ///
  /// In en, this message translates to:
  /// **'User removed'**
  String get textuserRemoved;

  /// No description provided for @textversion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get textversion;

  /// No description provided for @textviewRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'View Recycle Bin'**
  String get textviewRecycleBin;

  /// No description provided for @titleAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get titleAbout;

  /// No description provided for @titleAccessYourListsAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Access your lists and settings'**
  String get titleAccessYourListsAndSettings;

  /// No description provided for @titleAddItemsToYourList.
  ///
  /// In en, this message translates to:
  /// **'Add items to your list'**
  String get titleAddItemsToYourList;

  /// No description provided for @titleAppInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get titleAppInformation;

  /// No description provided for @titleAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get titleAppearance;

  /// No description provided for @titleCreateNewList.
  ///
  /// In en, this message translates to:
  /// **'Create New List'**
  String get titleCreateNewList;

  /// No description provided for @titleCrowdin.
  ///
  /// In en, this message translates to:
  /// **'Crowdin'**
  String get titleCrowdin;

  /// No description provided for @titleDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get titleDeadline;

  /// No description provided for @titleDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get titleDescription;

  /// No description provided for @titleGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get titleGithub;

  /// No description provided for @titleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get titleLanguage;

  /// No description provided for @titleLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get titleLocation;

  /// No description provided for @titleMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get titleMyProfile;

  /// No description provided for @titleNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get titleNotifications;

  /// No description provided for @titleOpenTheDrawerFromTheLeft.
  ///
  /// In en, this message translates to:
  /// **'Open the drawer from the left'**
  String get titleOpenTheDrawerFromTheLeft;

  /// No description provided for @titleReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get titleReleaseNotes;

  /// No description provided for @titleSelectAShoppingListToView.
  ///
  /// In en, this message translates to:
  /// **'Select a shopping list to view'**
  String get titleSelectAShoppingListToView;

  /// No description provided for @titleShareCollaborate.
  ///
  /// In en, this message translates to:
  /// **'Share & Collaborate'**
  String get titleShareCollaborate;

  /// No description provided for @titleShopsync.
  ///
  /// In en, this message translates to:
  /// **'ShopSync'**
  String get titleShopsync;

  /// No description provided for @titleSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get titleSignOut;

  /// No description provided for @titleSmartLists.
  ///
  /// In en, this message translates to:
  /// **'Smart Lists'**
  String get titleSmartLists;

  /// No description provided for @titleTaskName.
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get titleTaskName;

  /// No description provided for @titleWelcomeToShopsync.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ShopSync'**
  String get titleWelcomeToShopsync;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
