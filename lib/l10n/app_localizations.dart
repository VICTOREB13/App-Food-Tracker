import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domains/app_localizations_settings.dart';
import 'en/app_localizations_en.dart';
import 'es/app_localizations_es.dart';

export 'domains/app_localizations_core.dart';
export 'domains/app_localizations_dashboard.dart';
export 'domains/app_localizations_meal.dart';
export 'domains/app_localizations_metrics.dart';
export 'domains/app_localizations_profile.dart';
export 'domains/app_localizations_settings.dart';
export 'en/app_localizations_en.dart';
export 'es/app_localizations_es.dart';

/// Unified localizations facade providing full domain access via [AppLocalizations.of(context)].
abstract class AppLocalizations extends AppLocalizationsSettings {
  AppLocalizations(super.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsEs();
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue on GitHub with '
    'a reproducible sample app and the gen-l10n configuration that was used.',
  );
}
