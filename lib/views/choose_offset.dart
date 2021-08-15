import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChooseOffset extends StatefulWidget {
  const ChooseOffset({Key? key}) : super(key: key);

  @override
  _ChooseOffsetState createState() => _ChooseOffsetState();
}

class _ChooseOffsetState extends State<ChooseOffset> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: TextField(
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 22),
            decoration: InputDecoration(
                labelText: "Type a decimal number",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)))),
            onChanged: (String data) {
              setState(() {});
              print(data);
            },
          ),
        ),
      ),
    );
  }
}
