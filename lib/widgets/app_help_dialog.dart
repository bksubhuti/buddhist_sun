import 'package:flutter/material.dart';

/// Represents a distinct section in a help dialog.
class HelpSection {
  final String? title;
  final IconData? icon;
  final String? content;
  final List<String>? bulletPoints;
  final bool isAlert;

  const HelpSection({
    this.title,
    this.icon,
    this.content,
    this.bulletPoints,
    this.isAlert = false,
  });
}

/// Displays a beautifully formatted, scrollable Help dialog with clean typography,
/// warning banners, and categorized bullet points without emojis or icon clutter.
void showAppHelpDialog(
  BuildContext context, {
  required String title,
  IconData? icon,
  required List<HelpSection> sections,
}) {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;

  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: primary.withAlpha(80),
            width: 1.5,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              tooltip: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                for (final section in sections) ...[
                  if (section.isAlert)
                    _buildAlertBox(context, section)
                  else
                    _buildStandardSection(context, section),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

Widget _buildAlertBox(BuildContext context, HelpSection section) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final alertColor = Colors.amber.shade800;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: alertColor.withAlpha(isDark ? 45 : 25),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: alertColor.withAlpha(140),
        width: 1.2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null)
          Text(
            section.title!,
            style: TextStyle(
              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        if (section.content != null) ...[
          const SizedBox(height: 6),
          Text(
            section.content!,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? Colors.amber.shade100 : Colors.brown.shade900,
            ),
          ),
        ],
        if (section.bulletPoints != null &&
            section.bulletPoints!.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final bullet in section.bulletPoints!)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: TextStyle(
                          color: alertColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark
                            ? Colors.amber.shade100
                            : Colors.brown.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    ),
  );
}

Widget _buildStandardSection(BuildContext context, HelpSection section) {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (section.title != null) ...[
        Text(
          section.title!,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 5),
      ],
      if (section.content != null)
        Text(
          section.content!,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: theme.colorScheme.onSurface.withAlpha(225),
          ),
        ),
      if (section.bulletPoints != null && section.bulletPoints!.isNotEmpty) ...[
        const SizedBox(height: 5),
        for (final bullet in section.bulletPoints!)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    )),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withAlpha(210),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Page-Specific Help Dialog Launchers
// ─────────────────────────────────────────────────────────────────────────────

/// 1. Home Screen (Noon & Dawn & Countdown Timer) Help Dialog
void showHomeHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Buddhist Sun & Solar Calculations',
    sections: [
      const HelpSection(
        title: 'High-Precision Algorithm (NREL SPA)',
        content:
            'Calculations in Buddhist Sun are powered by the National Renewable Energy Laboratory’s Solar Position Algorithm (NREL SPA). '
            'Unlike older algorithms (such as Meeus) which had up to a 1-minute margin of error, NREL SPA is the international gold standard and is accurate to within a few seconds for solar noon, sunrise, and twilights.',
      ),
      const HelpSection(
        title: 'Vinaya Eating Precaution & Mouth Rinsing',
        isAlert: true,
        content:
            'While the astronomical calculation is accurate within seconds, monks and 8/10-precept practitioners should be sure not to swallow any food and rinse the mouth one minute to 30 seconds before the time expires so that no food remains in the throat or mouth when solar noon arrives.',
      ),
      const HelpSection(
        title: 'Application Features',
        bulletPoints: [
          'Solar Noon & Dawn: Accurate daily solar noon and dawn according to Pa-Auk (-40m / -9.8°), Na-Uyana (-30m / -7.7°), or custom angles.',
          'Hands-Free Voice Timer: Spoken audio countdown announcements (TTS) with screen-off background support to warn you as noon approaches.',
          'Vinaya Compass: 3D Great-Circle Earth globe, 2D map, and traditional Buddhist rotating dial aligning toward Bodh Gaya.',
          'Moon Phase & Uposatha: Daily moon phase, illuminated fraction, and traditional Uposatha / Poya days (Thai, Myanmar, Sinhala).',
          'Sun & Shadow (Vinaya Ratio): Real-time shadow length and finger-breadth (aṅgula) stick ratios for physical noon verification.',
          'Buddhavassa (BE Calendar): Buddhist Era year reckoning, vassa counts, and Pakkha calendar days.',
          'Meditation Timer: Mindful timer with authentic singing bowl chimes, interval bells, and warm-up periods.',
          'Maraṇassati (Death Contemplation): Mindfulness of mortality with life expectancy calculations and contemplation alerts.',
          'GPS & 40,000+ City Database: Automatic location detection or full offline city search without internet.',
          'Safety Offsets: Configurable safety buffer (1–10 minutes) subtracting from noon or adding to dawn to safeguard Vinaya practice.',
        ],
      ),
      const HelpSection(
        title: 'Safety Margin in Settings',
        content:
            'The Safety setting subtracts minutes from Solar Noon to display it earlier, and adds minutes to Dawn to display it later. Even with NREL SPA accuracy, a safety buffer of 1 minute is recommended for peace of mind.',
      ),
      const HelpSection(
        title: 'Privacy Statement',
        content:
            'Buddhist Sun does not collect or share any personal information. GPS location is used solely on your device for astronomical calculations.\nhttps://americanmonk.org/privacy-policy-for-buddhist-sun-app/',
      ),
    ],
  );
}

/// 2. Moon & Uposatha Page Help Dialog
void showMoonHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Moon & Uposatha Calendar',
    sections: [
      const HelpSection(
        title: 'Astronomical Moon Phase',
        content:
            'Displays the real-time moon phase and illuminated fraction percentage. The calendar details the lunar cycle from New Moon (Amāvāsyā) through First Quarter, Full Moon (Puṇṇamī), and Last Quarter.',
      ),
      const HelpSection(
        title: 'Regional Uposatha Traditions',
        content:
            'Theravada Buddhist monastic traditions count lunar calendar months and leap months (Adhikamāsa) slightly differently:',
        bulletPoints: [
          'Thai Tradition: Follows the Thai Royal / Chula Chakkrabongse lunar calendar (Thammayut and Mahanikaya).',
          'Myanmar Tradition: Follows the Myanmar lunar calendar and Watat intercalary month calculations.',
          'Sinhala Tradition: Follows the Sri Lankan Poya calendar (Duruthu through Unduvap).',
        ],
      ),
      const HelpSection(
        title: 'Poya & Uposatha Observances',
        bulletPoints: [
          'Poya / Uposatha Days: Full Moon (15th), New Moon (14th/15th), and Quarter Moon (8th day of waxing/waning).',
          'Pātīmokkha Recitation: Monastic gathering for the recitation of the rule on Full Moon and New Moon days.',
          'Upcoming Alerts: Enable scheduled notifications in Settings to receive reminders 1–3 days before each Uposatha.',
        ],
      ),
    ],
  );
}

/// 3. GPS & Location Page Help Dialog
void showGpsHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'GPS & Location Management',
    sections: [
      const HelpSection(
        title: 'Automatic GPS Detection',
        content:
            'Tap the GPS button to detect your exact coordinates (latitude, longitude, and elevation). Because Solar Noon depends directly on your longitude, GPS provides the most accurate solar times.',
      ),
      const HelpSection(
        title: 'Offline City Database',
        content:
            'If you are offline or in a secluded monastery without satellite/internet connectivity, use the City Search tab to choose from over 40,000 cities worldwide.',
      ),
      const HelpSection(
        title: 'Timezones & Daylight Saving Time (DST)',
        content:
            'When using GPS, your timezone offset is determined by your phone’s system clock. If your region observes Daylight Saving Time, ensure your device clock is updated or adjust the offset in Settings.',
      ),
    ],
  );
}

/// 4. Compass & Direction Page Help Dialog
void showCompassHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Pilgrimage Compass & 3D Earth',
    sections: [
      const HelpSection(
        title: 'Three Interactive View Modes',
        bulletPoints: [
          'Buddhist Compass Dial: Traditional rotating dial with Buddha center, sacred pointer, heading degree, and haptic lock when facing the destination.',
          '2D Map: Google Map displaying your current location, target pilgrimage site, and geodesic path.',
          '3D Earth Globe: 3D spherical Earth displaying the true Great-Circle curve across continents with day/night atmospheric glow (textures courtesy of Solar System Scope, CC BY 4.0).',
        ],
      ),
      const HelpSection(
        title: 'Direction Alignment on 3D Earth',
        content:
            'When "Aligned" mode is active, the Earth globe rotates so your Great-Circle flight path points straight forward (12 o’clock). This gives an intuitive understanding of the physical direction to Bodh Gaya across the curved planet. Tap the bottom-left chip to switch to "North Up".',
      ),
      const HelpSection(
        title: 'Auto-Framing & Zoom Controls',
        bulletPoints: [
          'Regional Routes: Routes like Sri Lanka to Bodh Gaya automatically zoom to occupy 65% of the card between the two points.',
          'Intercontinental / Antipodal: Faraway destinations like Statue of Liberty display the entire Earth sphere taking up 65% of the card with both points visible near the limbs.',
          'Zoom Buttons (+ / -): Use the buttons in the bottom-right corner for single-tap zooming, or pinch to zoom without interfering with page scrolling.',
          'Recenter: Tap the focus button in the bottom-right or the direction badge below the card to smoothly recenter the camera.',
        ],
      ),
      const HelpSection(
        title: 'Sacred Pilgrimage Sites',
        content:
            'Select from the Four Main Holy Sites (Bodh Gaya, Lumbini, Sarnath, Kusinara), celebrated pagodas (Shwedagon, Mahamuni, Wat Phra Kaew, Sri Dalada Maligawa), or enter your own custom latitude/longitude.',
      ),
    ],
  );
}

/// 5. Sun & Shadow Page Help Dialog
void showSunShadowHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Sun & Shadow (Vinaya Gnomon)',
    sections: [
      const HelpSection(
        title: 'Vinaya Mid-Day Shadow Rule',
        content:
            'The Vinaya Piṭaka (Pācittiya 37) defines the meal period up until solar noon. The commentary and ancient manuals describe verifying solar noon using a gnomon (vertical stick) cast in sunlight: the shadow shrinks until solar noon (zenith) and begins lengthening immediately afterward.',
      ),
      const HelpSection(
        title: 'Sugata Span & Finger Breadths (Aṅgula)',
        bulletPoints: [
          '1 Sugata Span = 12 finger breadths (aṅgula).',
          'A vertical gnomon stick (height H) casts a shadow of length L.',
          'The shadow ratio L / H equals cot(solar altitude).',
          'At solar noon, the shadow reaches its minimum length and points true Solar North (in the northern tropics/temperate zone) or true Solar South.',
        ],
      ),
      const HelpSection(
        title: 'Compass Alignment & Shadow Tracking',
        content:
            'Tap the compass icon in the AppBar to align your device with the sun’s azimuth. The interactive dial displays the sun’s exact angle, altitude above the horizon, and remaining time until solar noon.',
      ),
    ],
  );
}

/// 6. Buddhavassa (BE Calendar) Page Help Dialog
void showBuddhavassaHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Buddhavassa (Buddhist Era)',
    sections: [
      const HelpSection(
        title: 'Buddhist Era (B.E.) Calculation',
        content:
            'The Buddhist Era (Buddha Sāsana / Buddhavassa) counts years elapsed since the Parinibbāna of Gotama Buddha (reckoned traditionally as 544 or 543 BCE).',
      ),
      const HelpSection(
        title: 'Regional Traditions',
        bulletPoints: [
          'Sri Lanka & Myanmar: The Buddhist year increments on the Vesak Full Moon (May). CE + 544 years.',
          'Thailand & Cambodia: The official Buddhist year increments on January 1st. CE + 543 years.',
        ],
      ),
      const HelpSection(
        title: 'Vas (Vassa) Season & Pakkha Observance',
        bulletPoints: [
          'Hera-vas (Purimikā Vassāvāsa): The first rains retreat, entering on the day after the Āsāḷha Full Moon.',
          'Pasu-vas (Pacchimikā Vassāvāsa): The second rains retreat, entering one month later.',
          'Pavāraṇā: The formal invitation marking the conclusion of the three-month retreat.',
          'Pakkha Days: Fortnight list detailing the 14th and 15th waxing/waning observance days throughout the year.',
        ],
      ),
    ],
  );
}

/// 7. Meditation Timer Page Help Dialog
void showMeditationTimerHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Meditation Timer',
    sections: [
      const HelpSection(
        title: 'Meditation Modes',
        bulletPoints: [
          'Timed Mode: Set a specific duration in minutes or hours with quick-access preset chips.',
          'End-At Mode: Set the timer to conclude at an exact clock time (e.g., finish at 06:00 AM before dawn).',
          'Unlimited Mode: Sit freely with open-ended time tracking and milestone chimes.',
        ],
      ),
      const HelpSection(
        title: 'Authentic Temple Bells',
        bulletPoints: [
          'Start, Warm-Up, Interval, and End Bells: Choose from Burmese Gong, Tibetan Singing Bowl, Rin Gong, or Zen Clapper.',
          'Warm-Up Period: Configurable preparatory time (15s to 3m) to settle posture and mind before the session begins.',
          'Periodic Interval Chimes: Sound a gentle chime every 5, 10, 15, 20, or 30 minutes to sustain mindful awareness.',
        ],
      ),
      const HelpSection(
        title: 'Background Audio Playback',
        content:
            'The meditation timer continues playing bell sounds in the background even when your screen is locked or turned off. Adjust bell volume independently using the on-screen slider.',
      ),
    ],
  );
}

/// 8. Maraṇassati (Death Contemplation) Help Dialog
void showDeathContemplationHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Maraṇassati (Death Contemplation)',
    sections: [
      const HelpSection(
        title: 'Canonical Purpose of Maraṇassati',
        content:
            'As taught in the Maraṇassati Suttas (AN 6.19 and AN 8.73), mindfulness of death is highly praised by the Buddha: '
            '“Mindfulness of death, monks, when developed and cultivated, is of great fruit and great benefit; it culminates in the Deathless.” '
            'It awakens spiritual urgency (saṁvega), dissolves heedlessness (pamāda), and cuts away trivial worldly clinging.',
      ),
      const HelpSection(
        title: 'Life Expectancy & Mortality Metrics',
        bulletPoints: [
          'Estimated Days Lived & Remaining: Based on your birth date and regional life expectancy tables.',
          'Breath & Heartbeat Count: Visualizing the finite number of breaths remaining in this human life.',
          'Percentage of Life Lived: A reminder that time passes swiftly like water flowing down a mountain stream.',
        ],
      ),
      const HelpSection(
        title: 'Scheduled Contemplation Reminders',
        content:
            'You can configure random notifications throughout the day. Each reminder prompts a brief moment of pausing, reflecting on impermanence (anicca), and returning to breath or wholesome thoughts.',
      ),
    ],
  );
}

/// 9. Settings Page Help Dialog
void showSettingsHelpDialog(BuildContext context) {
  showAppHelpDialog(
    context,
    title: 'Settings & Preferences',
    sections: [
      const HelpSection(
        title: 'Dawn Calculation Formulas',
        bulletPoints: [
          'Pa-Auk Method: Sunrise minus 40 minutes (solar depression angle of -9.8°).',
          'Na-Uyana Method: Sunrise minus 30 minutes (solar depression angle of -7.7°).',
          'Civil Twilight: Solar center is 6° below the horizon.',
          'Nautical Twilight: Solar center is 12° below the horizon.',
          'Astronomical Twilight: Solar center is 18° below the horizon (first light under dark skies).',
          'Custom Angle: Specify your monastery’s preferred depression angle.',
        ],
      ),
      const HelpSection(
        title: 'Safety Margin (Buffer Offset)',
        content:
            'Subtracts minutes from Solar Noon to make the displayed noon earlier, and adds minutes to Dawn to make dawn later. This guarantees that you will not inadvertently transgress monastic eating or dawn boundaries.',
      ),
      const HelpSection(
        title: 'Voice (TTS) Countdown & Background Playback',
        content:
            'Enables spoken voice warnings as noon approaches. To ensure reliable audio when the screen is off, enable "TTS with screen off" and allow battery optimization exemptions if prompted by Android.',
      ),
    ],
  );
}
