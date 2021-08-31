import 'package:buddhist_sun/src/models/world_cities.dart';
import 'package:buddhist_sun/src/services/get_world_cities.dart';
import 'package:flutter/material.dart';
import 'package:buddhist_sun/src/models/prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key, required this.goToHome}) : super(key: key);
  final VoidCallback goToHome;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final dbService = DatabaseService();
  String searchKey = "Mand";
  late double _offset = 0;
  List<String> safetyItems = <String>[
    "none",
    "1 minute",
    "2 minutes",
    "3 minutes",
    "4 minutes",
    "5 minutes",
    "10 minutes",
  ];

  List<String> _dawnMethodItems = <String>[
    "Nauticle Twilight",
    "Pa-Auk",
    "Na-Uyana",
    "Civil Twilight",
    "Sunrise",
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    dbService.dispose();
    super.dispose();
  }

  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: TextField(
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  fontSize: 15),
                              decoration: InputDecoration(
                                  labelText: "Decimal number",
                                  border: OutlineInputBorder()),
                              onChanged: (String data) async {
                                _offset = double.parse(data);
                              },
                            ),
                          ),
                          SizedBox(height: 6.0),
                          IconButton(
                            icon: Icon(Icons.save),
                            onPressed: () async {
                              setState(() {
                                Prefs.offset = _offset;
                              });
                              widget.goToHome();
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 6.0),
                      Text("Current offset is ${Prefs.offset}"),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 25),
              Card(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      SizedBox(height: 6.0),
                      Text("Safety:",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 18,
                          )),
                      SizedBox(width: 10.0),
                      DropdownButton<String>(
                          value: Prefs.safety,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                          isDense: true,
                          onChanged: (newValue) {
                            setState(() {
                              Prefs.safety = newValue!;
                            });
                          },
                          items: safetyItems.map<DropdownMenuItem<String>>(
                            (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .appBarTheme
                                          .backgroundColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ).toList()),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Card(
                margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      SizedBox(height: 6.0),
                      Text("Dawn:",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          )),
                      SizedBox(
                        width: 10.0,
                        height: 20,
                      ),
                      DropdownButton<String>(
                          value: Prefs.dawnVal,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                          isDense: true,
                          onChanged: (newValue) {
                            setState(() {
                              Prefs.dawnVal = newValue!;
                            });
                          },
                          items: _dawnMethodItems.map<DropdownMenuItem<String>>(
                            (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .appBarTheme
                                          .backgroundColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ).toList()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 20),
                decoration: InputDecoration(
                    labelText: "Search for city",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                controller: controller,
                onChanged: (String data) {
                  setState(() {
                    searchKey = data;
                  });
                  print(data);
                },
              ),
              FutureBuilder<List<WorldCities>>(
                  future: dbService.getWorldCities(searchKey),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    return ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              onTap: () async {
                                Prefs.cityName =
                                    snapshot.data![index].cityAscii;
                                Prefs.lat = snapshot.data![index].lat;
                                Prefs.lng = snapshot.data![index].lng;
                                widget.goToHome();
                              },
                              title: Text(
                                  "${snapshot.data![index].cityAscii}, ${snapshot.data![index].country} ",
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 19)),
                              subtitle: Text(
                                  snapshot.data![index].lat.toString() +
                                      "," +
                                      snapshot.data![index].lng.toString()),
                            ),
                          );
                        });
                  })
            ],
          ),
        ),
      ),
    );
  }
}
