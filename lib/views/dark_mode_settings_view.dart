import 'package:buddhist_sun/src/provider/theme_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DarkModeSettingView extends StatelessWidget {
  const DarkModeSettingView({key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: Consumer<ThemeChangeNotifier>(
          builder: ((context, themeChangeNotifier, child) => ToggleButtons(
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
              ))),
      title: Text(
        AppLocalizations.of(context)!.darkMode,
      ),
    );
  }
}
