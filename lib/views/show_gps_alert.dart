import 'package:flutter/material.dart';

Future showGpsPermissionInfoDialog(BuildContext context) async {
  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog help = AlertDialog(
    title: Text("GPS Permission"),
    content: SingleChildScrollView(
      child: Text(
          "Permission will be requested for GPS use. This allows for GPS Location Data to be gathered for determining the sun's position. "
          "GPS is only collected once for each time the GPS button is pressed.  No information "
          "is collected or sent back to us or a third party. Permission will be requested only one time if accepted.",
          style: TextStyle(fontSize: 16, color: Colors.blue)),
    ),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return help;
    },
  );
}
