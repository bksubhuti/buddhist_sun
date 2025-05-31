import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

showAboutBuddhistSunDialog(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  showAboutDialog(
    applicationIcon:
        Image.asset('assets/buddhist_sun_app_logo.png', width: 50, height: 50),
    context: context,
    applicationName: AppLocalizations.of(context)!.buddhistSun,
    applicationVersion: 'Version - ${info.version}+${info.buildNumber}',
    children: [ColoredText(AppLocalizations.of(context)!.about_content)],
  );
}
