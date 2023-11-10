import 'package:buddhist_sun/src/models/theme_data.dart';
import 'package:buddhist_sun/src/provider/theme_change_notifier.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

class SelectThemeWidget extends StatelessWidget {
  const SelectThemeWidget();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final localeProvider =
        Provider.of<ThemeChangeNotifier>(context, listen: false);

    return SizedBox(
      width: 150,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<int>(
              padding: EdgeInsets.zero,
              onSelected: (val) {
                Prefs.themeIndex = val;
                Prefs.themeName = myFlexSchemes[val].name;
                localeProvider.themeIndex = val;
              },
              itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
                for (int i = 0; i < myFlexSchemes.length; i++)
                  PopupMenuItem<int>(
                    value: i,
                    child: ListTile(
                      leading: Icon(Icons.lens,
                          color: isLight
                              ? myFlexSchemes[i].light.primary
                              : myFlexSchemes[i].dark.primary,
                          size: 35),
                      title: Text(myFlexSchemes[i].name),
                    ),
                  )
              ],
              child: Icon(
                Icons.lens,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
