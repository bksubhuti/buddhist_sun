// To parse this JSON data, do
//
//     final WorldCities = WorldCitiesFromJson(jsonString);

import 'dart:convert';

List<WorldCities> worldCitiesFromJson(String str) => List<WorldCities>.from(
    json.decode(str).map((x) => WorldCities.fromJson(x)));

String WorldCitiesToJson(List<WorldCities> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class WorldCities {
  WorldCities({
    this.adminName = "",
    this.capital = "",
    this.city = "",
    this.cityAscii = "",
    this.country = "",
    this.id = 0,
    this.iso2 = "",
    this.iso3 = "",
    this.lat = 0.0,
    this.lng = 0.0,
    this.population = 0,
  });

  String? adminName;
  String capital;
  String city;
  String cityAscii;
  String country;
  int id;
  String iso2;
  String iso3;
  double lat;
  double lng;
  int population;

  factory WorldCities.fromJson(Map<dynamic, dynamic> json) {
    return WorldCities(
      adminName: json["admin_name"] ?? "n/a",
      capital: json["capital"] ?? "n/a",
      city: json["city"] ?? "n/a",
      cityAscii: json["city_ascii"] ?? "n/a",
      country: json["country"] ?? "n/a",
      id: json["id"] ?? 0,
      iso2: json["iso2"] ?? "n/a",
      iso3: json["iso3"] ?? "n/a",
      lat: json["lat"] ?? 0.0,
      lng: json["lng"] ?? 0.0,
      population: json["population"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        "admin_name": adminName,
        "capital": capital,
        "city": city,
        "city_ascii": cityAscii,
        "country": country,
        "id": id,
        "iso2": iso2,
        "iso3": iso3,
        "lat": lat,
        "lng": lng,
        "population": population,
      };
}
