import 'dart:io';

import 'package:flutter/services.dart';
import 'package:buddhist_sun/src/models/world_cities.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  late Database _db;
  Future? _dbInit;

  Future initDatabase() async {
    bool newdb = false;
    _dbInit ??= await () async {
      _db = await openDatabase('assets/citydb.db');
      var databasePath = await getDatabasesPath();
      var path = join(databasePath, 'citydb.db');

      //Check if DB exists
      var exists = await databaseExists(path);

      if (!exists || newdb) {
        // or newdb is to always if db changes  (set to true for initial debug mode)
        print('Create a new copy from assets');

        //Check if parent directory exists
        try {
          await Directory(dirname(path)).create(recursive: true);
        } catch (_) {}

        //Copy from assets
        ByteData data = await rootBundle.load(join("assets", "citydb.db"));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        //Write and flush the bytes
        await File(path).writeAsBytes(bytes, flush: true);
      }

      //Open the database
      _db = await openDatabase(path, readOnly: true);
    }();
  }

  Future<List<WorldCities>> getWorldCities(searchKey) async {
    await initDatabase();
    String dbQuery =
        "select city, city_ascii, lat,lng,country,iso2,iso3,admin_name,capital,population, id	 from worldcities Where city_ascii = 'Tokyo';";

    if (searchKey != "") {
      if (searchKey.length > 2) {
        dbQuery =
            "select city, city_ascii, lat,lng,country,iso2,iso3,admin_name,capital,population, id	from worldcities WHERE city_ascii LIKE '$searchKey%';";
      }
    }

    List<Map> list = await _db.rawQuery(dbQuery);
    return list
        .map((worldcities) => WorldCities.fromJson(worldcities))
        .toList();

    //return list.map((trail) => Trail.fromJson(trail)).toList();
  }

  dispose() {
    _db.close();
  }
}
