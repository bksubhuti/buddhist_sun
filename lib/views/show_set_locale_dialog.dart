import 'package:buddhist_sun/src/models/select_language_widget.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/l10n/app_localizations.dart';

Future showSetLocaleDialog(BuildContext context) async {
  // set up the buttons
  Widget okButton = TextButton(
    child: Text(AppLocalizations.of(context)!.ok),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Set Locale"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            "Set Language \nသင်၏ဘာသာစကားကိုရွေးပါ\nඔබේ භාෂාව තෝරන්න\n选择你的语言\nChọn ngôn ngữ\n"),
        SelectLanguageWidget(),
      ],
    ),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
