import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChooseOffset extends StatefulWidget {
  const ChooseOffset({Key? key}) : super(key: key);

  @override
  _ChooseOffsetState createState() => _ChooseOffsetState();
}

class _ChooseOffsetState extends State<ChooseOffset> {
  late double _offset = 0;
/*
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setString("cityName",
                                    snapshot.data![index].cityAscii);
                                prefs.setDouble(
                                    "lat", snapshot.data![index].lat);
                                prefs.setDouble(
                                    "lng", snapshot.data![index].lng);
                                prefs.setDouble("offset", offfset);

                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setDouble("offset", offfset);

*/

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
          children: [
            Text(
                "offset is $_offset"), //prefs.setDouble("offset"),//, offfset),

            Container(
              child: TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 22),
                decoration: InputDecoration(
                    labelText: "Type a decimal number",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                onChanged: (String data) async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setDouble("offset", double.parse(data));

                  setState(() {});
                  print(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
