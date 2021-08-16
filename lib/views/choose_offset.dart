import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChooseOffset extends StatefulWidget {
  const ChooseOffset({Key? key, required this.goToHome}) : super(key: key);
  final VoidCallback goToHome;

  @override
  _ChooseOffsetState createState() => _ChooseOffsetState();
}

class _ChooseOffsetState extends State<ChooseOffset> {
  late double _offset = 0;

  @override
  void initState() {
    setPrefs();
    super.initState();
  }

  void setPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _offset = prefs.getDouble("offset") ?? 6.5;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current offset is $_offset"),
            SizedBox(height: 6.0),
            TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 22),
              decoration: InputDecoration(
                  labelText: "Type a decimal number",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)))),
              onChanged: (String data) async {
                _offset = double.parse(data);
              },
            ),
            SizedBox(height: 6.0),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setDouble("offset", _offset);
                setState(() {});
                widget.goToHome();
              },
              label: Text("Save Offset"),
            )
          ],
        ),
      ),
    );
  }
}
