import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

extension Tr on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this)!;
}
