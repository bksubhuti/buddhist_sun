enum MeditationTimerMode {
  timed,
  endAt,
  unlimited,
}

enum MeditationTimerStatus {
  idle,
  delaying,
  running,
  paused,
  completed,
}

class MeditationSoundItem {
  final String id;
  final String displayName;
  final String? assetPath;

  const MeditationSoundItem({
    required this.id,
    required this.displayName,
    this.assetPath,
  });

  static const MeditationSoundItem none = MeditationSoundItem(
    id: 'none',
    displayName: 'None',
    assetPath: null,
  );

  static const List<MeditationSoundItem> allSounds = [
    MeditationSoundItem(id: 'none', displayName: 'None', assetPath: null),
    MeditationSoundItem(
      id: 'Bell',
      displayName: 'Bell',
      assetPath: 'assets/audio/meditation_sounds/Bell.wav',
    ),
    MeditationSoundItem(
      id: 'Bowl',
      displayName: 'Bowl',
      assetPath: 'assets/audio/meditation_sounds/Bowl.wav',
    ),
    MeditationSoundItem(
      id: 'BowlStrong',
      displayName: 'Deep Bowl',
      assetPath: 'assets/audio/meditation_sounds/BowlStrong.wav',
    ),
    MeditationSoundItem(
      id: 'Gong',
      displayName: 'Gong',
      assetPath: 'assets/audio/meditation_sounds/Gong.wav',
    ),
    MeditationSoundItem(
      id: 'ThreeBowl',
      displayName: 'Three Bowls',
      assetPath: 'assets/audio/meditation_sounds/ThreeBowl.wav',
    ),
    MeditationSoundItem(
      id: 'Sadhu',
      displayName: 'Sadhu',
      assetPath: 'assets/audio/meditation_sounds/Sadhu.wav',
    ),
    MeditationSoundItem(
      id: 'GardenBird',
      displayName: 'Garden Bird',
      assetPath: 'assets/audio/meditation_sounds/GardenBird.wav',
    ),
  ];

  static MeditationSoundItem fromId(String id) {
    return allSounds.firstWhere(
      (s) => s.id.toLowerCase() == id.toLowerCase(),
      orElse: () => allSounds[2], // default to Bowl
    );
  }
}
