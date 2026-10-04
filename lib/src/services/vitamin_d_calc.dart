import 'dart:math' as math;

import 'package:buddhist_sun/src/services/solar_calc.dart';

/// Vitamin D (cholecalciferol) estimates from sun exposure.
///
/// This is a rough educational model, not a medical tool. It combines:
///  * Clear-sky UV Index from solar elevation (Madronich approximation:
///    UVI ≈ 12.5 · cos(SZA)^2.42 for ~300 DU ozone).
///  * Erythemal irradiance: 1 UVI = 0.025 W/m².
///  * Minimal Erythema Dose (MED) per Fitzpatrick skin type.
///  * Holick's rule of thumb: 1 MED on the whole body ≈ 10,000 IU
///    (conservative end of the 10,000–25,000 IU range).
///  * Fraction of body surface uncovered (rule of nines).
///  * Body surface area from weight (Livingston & Lee 2001:
///    BSA = 0.1173 · kg^0.6466), relative to a 1.8 m² reference adult.
///  * Low-sun penalty: below ~45° elevation the vitamin D-effective UVB
///    falls off faster than erythemal UV (longer ozone path), so efficiency
///    tapers linearly from 45° down to zero at 15°.
///  * Saturation: production is linear up to ½ MED for the day, then
///    previtamin D plateaus and production tapers linearly to zero at 1 MED.
///  * Shaved scalp (monastics): ~3.5% of body surface, shaded by regrowth
///    as exp(-days/6).
///  * Posture: the dose model is calibrated for an upright person. Lying
///    down turns the exposed side toward the sky; relative gain is derived
///    from a cylinder model (half direct, half diffuse UV). Sunburn time is
///    unchanged because the most exposed surface always faces the sky.

/// Solar elevation (degrees) at or above which vitamin D synthesis is
/// considered efficient — your shadow is shorter than you are.
const double vitDOptimalElevation = 45.0;

/// Elevation (degrees) below which essentially no vitamin D is produced.
const double vitDMinElevation = 15.0;

const double _iuPerFullBodyMed = 10000.0;
const double _referenceBsa = 1.8;
const double _wattsPerUvi = 0.025;

enum VitDSkinType { type1, type2, type3, type4, type5, type6 }

extension VitDSkinTypeInfo on VitDSkinType {
  int get number => index + 1;

  /// Minimal erythema dose in J/m² (erythemally weighted).
  double get medJm2 => const [200.0, 250.0, 300.0, 450.0, 600.0, 1000.0][index];
}

/// How much of the body is uncovered: monastic robe arrangements first,
/// then lay clothing. New values must be appended (index is persisted).
enum VitDCoverage {
  fullRobe,
  oneShoulder,
  upperBare,
  bathingCloth,
  layFaceHands,
  layShortSleeves,
  layShorts,
  laySwimwear,
  femaleFaceHands,
  femaleShortSleeves,
  femaleShorts,
  femaleSwimwear,
  angsa, // monk: aṅsa shoulder cloth over the left shoulder
}

extension VitDCoverageInfo on VitDCoverage {
  /// Fraction of total body surface exposed to the sun (rule of nines).
  /// Monastic values exclude the scalp, which is added via hair growth
  /// (see [exposedFractionFor]); lay values assume hair covers the scalp.
  double get exposedFraction =>
      const [
        0.085, 0.185, 0.585, 0.715, // monk
        0.10, 0.20, 0.38, 0.80, // lay male
        0.10, 0.20, 0.38, 0.75, // lay female (swim top covers the chest)
        0.33, // aṅsa: right arm, left forearm, right shoulder and chest bare
      ][index];

  bool get isLay => !monastic.contains(this);
  bool get isFemale => female.contains(this);

  /// The male lay option with the same clothing (female options share
  /// the male drawing and labels).
  VitDCoverage get maleEquivalent =>
      isFemale ? lay[female.indexOf(this)] : this;

  /// Display order, least to most skin exposed.
  static const List<VitDCoverage> monastic = [
    VitDCoverage.fullRobe,
    VitDCoverage.oneShoulder,
    VitDCoverage.angsa,
    VitDCoverage.upperBare,
    VitDCoverage.bathingCloth,
  ];

  static const List<VitDCoverage> lay = [
    VitDCoverage.layFaceHands,
    VitDCoverage.layShortSleeves,
    VitDCoverage.layShorts,
    VitDCoverage.laySwimwear,
  ];

  static const List<VitDCoverage> female = [
    VitDCoverage.femaleFaceHands,
    VitDCoverage.femaleShortSleeves,
    VitDCoverage.femaleShorts,
    VitDCoverage.femaleSwimwear,
  ];
}

/// Share of body surface that is scalp.
const double vitDScalpFraction = 0.035;

/// Maximum hair growth days offered in the selector.
const int vitDMaxHairDays = 14;

/// 0..1 fraction of scalp UV reaching the skin after [days] of regrowth.
double scalpExposure(int days) =>
    math.exp(-days.clamp(0, vitDMaxHairDays) / 6.0);

/// Total exposed body fraction, including a shaved scalp for monastics.
double exposedFractionFor(VitDCoverage c, int hairDays) => c.isLay
    ? c.exposedFraction
    : c.exposedFraction + vitDScalpFraction * scalpExposure(hairDays);

enum VitDPosture { standing, walking, sitting, lying }

/// Average UV on body skin relative to a horizontal surface for an upright
/// cylinder: direct beam cot(e)/π plus half-sky diffuse, split 50/50.
double _uprightGeometry(double elevationDeg) {
  final e = elevationDeg.clamp(5.0, 90.0) * math.pi / 180.0;
  return 0.5 * (math.cos(e) / math.sin(e)) / math.pi + 0.25;
}

/// Vitamin D multiplier relative to standing for [posture] at the sun's
/// elevation. Lying flat is ~1.6× at noon but worse than standing when the
/// sun is low; sitting is halfway between.
double postureFactor(VitDPosture posture, double elevationDeg) {
  final lying = 0.5 / _uprightGeometry(elevationDeg);
  switch (posture) {
    case VitDPosture.standing:
    case VitDPosture.walking:
      return 1.0;
    case VitDPosture.sitting:
      return (1.0 + lying) / 2.0;
    case VitDPosture.lying:
      return lying;
  }
}

/// Sky condition multiplier on clear-sky UV.
enum VitDSky { clear, partlyCloudy, mostlyCloudy, overcast }

extension VitDSkyInfo on VitDSky {
  double get factor => const [1.0, 0.85, 0.6, 0.3][index];
}

/// Clear-sky UV Index estimate from solar elevation, scaled by sky factor.
double estimateUvIndex(double elevationDeg, {double skyFactor = 1.0}) {
  if (elevationDeg <= 0) return 0.0;
  final mu = math.sin(elevationDeg * math.pi / 180.0);
  return 12.5 * math.pow(mu, 2.42) * skyFactor;
}

/// 0..1 efficiency of vitamin D synthesis relative to high sun.
double vitaminDElevationEfficiency(double elevationDeg) {
  if (elevationDeg >= vitDOptimalElevation) return 1.0;
  if (elevationDeg <= vitDMinElevation) return 0.0;
  return (elevationDeg - vitDMinElevation) /
      (vitDOptimalElevation - vitDMinElevation);
}

/// Body surface area (m²) from weight alone (Livingston & Lee).
double bodySurfaceArea(double weightKg) =>
    0.1173 * math.pow(weightKg.clamp(20.0, 250.0), 0.6466);

/// Suggested daily vitamin D amount in IU: ~20 IU/kg, rounded to 100,
/// clamped to 600–4000 IU (IOM RDA to tolerable upper intake).
int suggestedDailyIu(double weightKg) {
  final raw = (weightKg * 20.0 / 100.0).round() * 100;
  return raw.clamp(600, 4000);
}

/// Instantaneous rates for the given sun and person.
class VitDRate {
  final double elevation;
  final double uvIndex;
  final double efficiency;

  /// IU produced per minute (before saturation taper).
  final double iuPerMinute;

  /// Fraction of one MED accumulated per minute (sunburn progress).
  final double medPerMinute;

  const VitDRate({
    required this.elevation,
    required this.uvIndex,
    required this.efficiency,
    required this.iuPerMinute,
    required this.medPerMinute,
  });

  /// Minutes until 1 MED (sunburn) from zero, or null if no UV.
  double? get minutesToBurn => medPerMinute > 0 ? 1.0 / medPerMinute : null;
}

VitDRate computeVitDRate({
  required double elevationDeg,
  required VitDSkinType skin,
  required VitDCoverage coverage,
  required VitDSky sky,
  required double weightKg,
  VitDPosture posture = VitDPosture.standing,
  int hairDays = 0,
}) {
  final uvi = estimateUvIndex(elevationDeg, skyFactor: sky.factor);
  final eff = vitaminDElevationEfficiency(elevationDeg);
  final medPerMin = uvi * _wattsPerUvi * 60.0 / skin.medJm2;
  final iuPerMin = medPerMin *
      _iuPerFullBodyMed *
      exposedFractionFor(coverage, hairDays) *
      postureFactor(posture, elevationDeg) *
      (bodySurfaceArea(weightKg) / _referenceBsa) *
      eff;
  return VitDRate(
    elevation: elevationDeg,
    uvIndex: uvi,
    efficiency: eff,
    iuPerMinute: iuPerMin,
    medPerMinute: medPerMin,
  );
}

/// Result of integrating exposure over a time span.
class VitDIncrement {
  final double iu;
  final double med;
  const VitDIncrement(this.iu, this.med);
}

/// Day's dose (MED) below which vitamin D production is still linear.
const double vitDSaturationStart = 0.5;

/// Cumulative production efficiency from 0 to [med]: 1 up to
/// [vitDSaturationStart], then falling linearly to 0 at 1 MED.
double _cumulativeTaper(double med) {
  const s0 = vitDSaturationStart;
  final m = med.clamp(0.0, 1.0);
  if (m <= s0) return m;
  // ∫ (1 - x) / (1 - s0) dx from s0 to m
  final span = 1.0 - s0;
  return s0 + ((m - s0) - (m * m - s0 * s0) / 2.0) / span;
}

/// Integrates exposure over [seconds] at a constant [rate], given the MED
/// already accumulated today ([medSoFar]). IU production is full up to
/// ½ MED, then tapers to zero at 1 MED (previtamin D saturation).
VitDIncrement integrateExposure(
    VitDRate rate, double seconds, double medSoFar) {
  if (seconds <= 0) return const VitDIncrement(0, 0);
  final minutes = seconds / 60.0;
  final dMed = rate.medPerMinute * minutes;
  final double avgTaper;
  if (dMed <= 0) {
    avgTaper = medSoFar <= vitDSaturationStart
        ? 1.0
        : ((1.0 - medSoFar) / (1.0 - vitDSaturationStart)).clamp(0.0, 1.0);
  } else {
    avgTaper = (_cumulativeTaper(medSoFar + dMed) -
            _cumulativeTaper(medSoFar)) /
        dMed;
  }
  return VitDIncrement(rate.iuPerMinute * minutes * avgTaper, dMed);
}

/// Minutes of continuous exposure from [start] needed to make [targetIu]
/// more IU, following the sun's path and the day's saturation taper.
/// Returns null if not reachable within [maxMinutes] (sun too low/setting,
/// or saturation reached first).
double? minutesToProduce({
  required double targetIu,
  required DateTime start,
  required double medSoFar,
  required VitDRate Function(DateTime) rateAt,
  int maxMinutes = 240,
}) {
  if (targetIu <= 0) return 0;
  double iu = 0;
  double med = medSoFar;
  for (int m = 0; m < maxMinutes; m++) {
    final r = rateAt(start.add(Duration(minutes: m, seconds: 30)));
    final inc = integrateExposure(r, 60, med);
    if (iu + inc.iu >= targetIu) {
      return m + (inc.iu > 0 ? (targetIu - iu) / inc.iu : 0);
    }
    iu += inc.iu;
    med += inc.med;
    if (med >= 1.0) return null;
  }
  return null;
}

/// Today's window(s) when the sun is at or above [vitDOptimalElevation].
class VitDSunWindow {
  final DateTime? start;
  final DateTime? end;
  final double peakElevation;
  final DateTime peakTime;
  const VitDSunWindow({
    this.start,
    this.end,
    required this.peakElevation,
    required this.peakTime,
  });

  bool get reaches45 => start != null && end != null;
}

/// Scans [day] in 5-minute steps to find when the sun is above 45°.
VitDSunWindow findVitDSunWindow(DateTime day, {double? lat, double? lng}) {
  DateTime? start;
  DateTime? end;
  double peak = -90;
  DateTime peakTime = DateTime(day.year, day.month, day.day, 12);
  final base = DateTime(day.year, day.month, day.day);
  for (int m = 0; m <= 24 * 60; m += 5) {
    final t = base.add(Duration(minutes: m));
    final el = getSolarPositionAt(t, lat: lat, lng: lng).elevation;
    if (el > peak) {
      peak = el;
      peakTime = t;
    }
    if (el >= vitDOptimalElevation) {
      start ??= t;
      end = t;
    }
  }
  return VitDSunWindow(
      start: start, end: end, peakElevation: peak, peakTime: peakTime);
}

/// Session length as m:ss (e.g. 300.4 s → "5:00"), rounded to the nearest
/// second so a session stopped at 5:00 never reads as 6 minutes.
String formatSessionDuration(double seconds) {
  final total = seconds.round();
  final m = total ~/ 60;
  final sec = (total % 60).toString().padLeft(2, '0');
  return '$m:$sec';
}
