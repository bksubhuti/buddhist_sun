import 'package:buddhist_sun/views/dark_mode_settings_view.dart';
import 'package:buddhist_sun/views/use_m3_widget.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/select_theme_widget.dart';

class ThemeSettingView extends StatelessWidget {
  const ThemeSettingView({key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.color_lens),
        title: Text(AppLocalizations.of(context)!.theme,
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 32.0),
            child: DarkModeSettingView(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: ListTile(
              title: Text(
                AppLocalizations.of(context)!.color,
              ),
              trailing: const SelectThemeWidget(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: ListTile(
              title: Text(AppLocalizations.of(context)!.material3),
              trailing: const M3SwitchWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
