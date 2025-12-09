import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_ar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:webinar/common/data/app_language.dart';
import 'package:webinar/locator.dart';

AppLocalizations get appText {
  final currentLanguage = locator<AppLanguage>().currentLanguage.toLowerCase();

  // Return the appropriate localization instance based on current language
  switch (currentLanguage) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    default:
      return AppLocalizationsAr(); // Default to Arabic
  }
}
