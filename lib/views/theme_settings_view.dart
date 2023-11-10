import 'package:buddhist_sun/src/provider/theme_change_notifier.dart';
import 'package:buddhist_sun/views/use_m3_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:buddhist_sun/src/models/select_theme_widget.dart';
import 'package:provider/provider.dart';

class ThemeSettingView extends StatelessWidget {
  const ThemeSettingView();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(AppLocalizations.of(context)!.theme,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 32.0),
            child: DarkModeSettingView(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: ListTile(
              title: Text(
                "Color",
              ),
              trailing: const SelectThemeWidget(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: ListTile(
              title: Text("Material 3"),
              trailing: const M3SwitchWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class DarkModeSettingView extends StatelessWidget {
  const DarkModeSettingView();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: ToggleButtons(
        onPressed: (int index) {
          Provider.of<ThemeChangeNotifier>(context, listen: false)
              .toggleTheme(index);
        },
        isSelected: context.read<ThemeChangeNotifier>().isSelected,
        children: const <Widget>[
          Icon(Icons.wb_sunny),
          Icon(Icons.color_lens),
          Icon(Icons.bedtime),
        ],
      ),
      title: Text(
        "Dark Mode",
      ),
    );
  }
}
