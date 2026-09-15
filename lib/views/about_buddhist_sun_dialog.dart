import 'package:buddhist_sun/src/models/colored_text.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';

showAboutBuddhistSunDialog(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  showAboutDialog(
    applicationIcon:
        Image.asset('assets/buddhist_sun_app_logo.png', width: 50, height: 50),
    context: context,
    applicationName: AppLocalizations.of(context)!.buddhistSun,
    applicationVersion: 'Version - ${info.version}+${info.buildNumber}',
    applicationLegalese: 'GNU General Public License v3\n'
        'Meditation timer adapted from ekaTimer (GPLv3)\n'
        'Audio samples from BigSoundBank.com, Freesound.org, Pixabay.com, and Suno.com\n'
        'Earth 3D textures by Solar System Scope (CC BY 4.0)',
    children: [ColoredText(AppLocalizations.of(context)!.about_content)],
  );
}
