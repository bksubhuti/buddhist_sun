import 'package:buddhist_sun/src/provider/locale_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buddhist_sun/src/models/prefs.dart';
import 'package:buddhist_sun/src/models/colored_text.dart';

class SelectLanguageWidget extends StatelessWidget {
  SelectLanguageWidget({Key? key}) : super(key: key);
  final _languageItems = <String>[
    'English',
    'မြန်မာ',
    'සිංහල',
    'ภาษาไทย',
    'ខ្មែរ',
    '中文',
    'Tiếng Việt',
    'हिन्दी',
    'বাংলা',
    'ພາສາລາວ',
    'Español',
    'Français',
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex =
        Prefs.localeVal < _languageItems.length ? Prefs.localeVal : 0;

    return DropdownButton<String>(
      value: _languageItems[currentIndex],
      underline: const SizedBox(),
      style: TextStyle(
        color: Theme.of(context).primaryColor,
      ),
      isDense: true,
      onChanged: (newValue) {
        if (newValue == null) return;
        Prefs.localeVal = _languageItems.indexOf(newValue);
        final localeProvider =
            Provider.of<LocaleChangeNotifier>(context, listen: false);
        localeProvider.localeVal = Prefs.localeVal;
      },
      items: _languageItems.map<DropdownMenuItem<String>>(
        (String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: ColoredText(
              value,
              style: TextStyle(
                color: (!Prefs.darkThemeOn)
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}
