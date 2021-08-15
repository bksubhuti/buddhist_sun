import 'package:buddhist_sun/src/models/world_cities.dart';
import 'package:buddhist_sun/src/services/get_world_cities.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChooseLocation extends StatefulWidget {
  @override
  _ChooseLocationState createState() => _ChooseLocationState();
}

class _ChooseLocationState extends State<ChooseLocation> {
  final dbService = DatabaseService();
  String searchKey = "";

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
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                style: TextStyle(fontSize: 22),
                decoration: InputDecoration(
                    labelText: "Type to search for city",
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
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setString("cityName",
                                    snapshot.data![index].cityAscii);
                                prefs.setDouble(
                                    "lat", snapshot.data![index].lat);
                                prefs.setDouble(
                                    "lng", snapshot.data![index].lng);
                                //Navigator.pop(context);
                                print(
                                    'tapped ${snapshot.data![index].cityAscii},  ${snapshot.data![index].lat},  ${snapshot.data![index].lng}');
                              },
                              title: Text(
                                  "${snapshot.data![index].cityAscii}, ${snapshot.data![index].country} ",
                                  style: TextStyle(fontSize: 20)),
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
