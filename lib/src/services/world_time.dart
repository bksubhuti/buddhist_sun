import 'package:intl/intl.dart' as intl;

class WorldTime {
  String location = "new york";
  String time = "not set"; // time in that location
  String flag = "not set flag"; // url to flag asset
  String shorturl = "not set url"; // url to call location for api endpoint
  bool isDayTime = false;

  WorldTime(
      {required this.location, required this.flag, required this.shorturl});

  Future<void> getTime() async {
    try {
      // var url = Uri.parse('http://worldtimeapi.org/api/timezone/$shorturl');
      // http.Response response = await http.get(url);
      /// Map data = jsonDecode(response.body);

      // get the data properties
      //String datetime = data['datetime'];
      //String offset = data['utc_offset'].substring(1, 3);

      DateTime now = DateTime.now(); // = DateTime.parse(datetime);
      //now = now.add(Duration(hours: int.parse(offset)));

      //isDayTime = (now.hour > 6 && now.hour < 20) ? true : false;

      // set the time property
      time = intl.DateFormat.jm().format(now);
    }
    //try
    catch (e) {
      print('error $e');
      time = "could not set time";
    }
  }
}
