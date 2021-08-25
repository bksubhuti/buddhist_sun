
class SolarTimerService {

  static final SolarTimerService _singleton = SolarTimerService._internal();

  factory SolarTimerService() {
    return _singleton;
  }

  SolarTimerService._internal();

  bool textToSpeech = true;
  
}