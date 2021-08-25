mixin SolarTimerDelegate {

  void update();
}


class SolarTimerService {

  static final SolarTimerService _singleton = SolarTimerService._internal();

  factory SolarTimerService() {
    return _singleton;
  }

  SolarTimerService._internal();

  SolarTimerDelegate? delegate;
  bool textToSpeech = true;

}