import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class MyThemes {
  static const orange2Name = 'Orange 2';
  static const FlexSchemeColor myScheme1Dark = FlexSchemeColor(
    primary: Color(0xFF9E7389),
    primaryContainer: Color(0xFF775C69),
    secondary: Color(0xFF738F81),
    secondaryContainer: Color(0xFF5C7267),
    // Again we use same secondaryVariant color as optional custom app bar color.
    appBarColor: Color(0xFF5C7267),
  );

  static const FlexSchemeColor myScheme1Light = FlexSchemeColor(
    primary: Color(0xFF4E0028),
    primaryContainer: Color(0xFF320019),
    secondary: Color(0xFF003419),
    secondaryContainer: Color(0xFF002411),
    // The built in schemes use their secondary variant color as their
    // custom app bar color, it could of course be any color, but for consistency
    // we will do the same in this custom FlexSchemeColor.
    appBarColor: Color(0xFF002411),
  );
}

// Create a custom flex scheme color for a light theme.
const FlexSchemeColor myScheme1Light = FlexSchemeColor(
  primary: Color(0xFF4E0028),
  primaryContainer: Color(0xFF320019),
  secondary: Color(0xFF003419),
  secondaryContainer: Color(0xFF002411),
  // The built in schemes use their secondary variant color as their
  // custom app bar color, it could of course be any color, but for consistency
  // we will do the same in this custom FlexSchemeColor.
  appBarColor: Color(0xFF002411),
);
// Create a corresponding custom flex scheme color for a dark theme.
const FlexSchemeColor myScheme1Dark = FlexSchemeColor(
  primary: Color(0xFF9E7389),
  primaryContainer: Color(0xFF775C69),
  secondary: Color(0xFF738F81),
  secondaryContainer: Color(0xFF5C7267),
  // Again we use same secondaryVariant color as optional custom app bar color.
  appBarColor: Color(0xFF5C7267),
);

// You can build a scheme the long way, by specifying all the required hand
// picked scheme colors, like above, or can also build schemes from a
// single primary color. With the [.from] factory, then the only required color
// is the primary color, the other colors will be computed. You can optionally
// also provide the primaryVariant, secondary and secondaryVariant colors with
// the factory, but any color that is not provided will always be computed for
// the full set of required colors in a FlexSchemeColor.

// In this example we create our 2nd scheme from just a primary color
// for the light and dark schemes. The custom app bar color will in this case
// also receive the same color value as the one that is computed for
// secondaryVariant color, this is the default with the [from] factory.
final FlexSchemeColor myScheme2Light =
    FlexSchemeColor.from(primary: const Color(0xFF4C4E06));
final FlexSchemeColor myScheme2Dark =
    FlexSchemeColor.from(primary: const Color(0xFF9D9E76));

// For our 3rd custom scheme we will define primary and secondary colors, but no
// variant colors, we will not make any dark scheme definitions either.
final FlexSchemeColor myScheme3Light = FlexSchemeColor.from(
  primary: const Color(0xFF993200),
  secondary: const Color(0xFF1B5C62),
);

// Create a list with all color schemes we will use, starting with all
// the built-in ones and then adding our custom ones at the end.
final List<FlexSchemeData> myFlexSchemes = <FlexSchemeData>[
  // Use the built in FlexColor schemes, but exclude the placeholder for custom
  // scheme, a selection that would typically be used to compose a theme
  // interactively in the app using a color picker, we won't be doing that in
  // this example.
  ...FlexColor.schemesList,
  // Then add our first custom FlexSchemeData to the list, we give it a name
  // and description too.
  const FlexSchemeData(
    name: 'Toledo purple',
    description: 'Purple theme, created from full custom defined color scheme.',
    // FlexSchemeData holds separate defined color schemes for light and
    // matching dark theme colors. Dark theme colors need to be much less
    // saturated than light theme. Using the same colors in light and dark
    // theme modes does not look nice.
    light: myScheme1Light,
    dark: myScheme1Dark,
  ),
  // Do the same for our second custom scheme.
  FlexSchemeData(
    name: 'Olive green',
    description:
        'Olive green theme, created from primary light and dark colors.',
    light: myScheme2Light,
    dark: myScheme2Dark,
  ),
  // We also do the same for our 3rd custom scheme, BUT we create its matching
  // dark colors, from the light FlexSchemeColor with the toDark method.
  FlexSchemeData(
    name: 'Oregon orange',
    description: 'Custom orange and blue theme, from only light scheme colors.',
    light: myScheme3Light,
    // We create the dark desaturated colors from the light scheme.
    dark: myScheme3Light.toDark(),
  ),
  const FlexSchemeData(
    name: MyThemes.orange2Name,
    description: FlexColor.mangoDescription,
    light: FlexSchemeColor(
      primary: FlexColor.mangoLightPrimary,
      primaryContainer: FlexColor.mangoLightPrimaryContainer,
      secondary: FlexColor.mangoLightSecondary,
      secondaryContainer: FlexColor.mangoLightSecondaryContainer,
      tertiary: FlexColor.mangoLightTertiary,
      tertiaryContainer: FlexColor.mangoLightTertiaryContainer,
      appBarColor: FlexColor.mangoLightTertiary,
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: FlexColor.mangoDarkPrimary,
      primaryContainer: FlexColor.mangoDarkPrimaryContainer,
      secondary: FlexColor.mangoDarkSecondary,
      secondaryContainer: FlexColor.mangoDarkSecondaryContainer,
      tertiary: FlexColor.mangoDarkTertiary,
      tertiaryContainer: FlexColor.mangoDarkTertiaryContainer,
      appBarColor: FlexColor.mangoDarkTertiary,
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  ),
  const FlexSchemeData(
    name: 'Mahayana blue',
    description: 'Mahayana Blue Color grey blue',
    light: FlexSchemeColor(
      primary: Color(0xFF00296B),
      primaryContainer: Color(0xFFA0C2ED),
      secondary: Color(0xFFD26900),
      secondaryContainer: Color(0xFFFFD270),
      tertiary: Color(0xFF5C5C95),
      tertiaryContainer: Color(0xFFC8DBF8),
      appBarColor: Colors.red,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFB1CFF5),
      primaryContainer: Color(0xFF3873BA),
      secondary: Color(0xFFFFD270),
      secondaryContainer: Color(0xFFD26900),
      tertiary: Color(0xFFC9CBFC),
      tertiaryContainer: Color(0xFF535393),
    ),
  ),

  // @rydmike: DESIGN TIP: You cannot use same primary secondary colors in
  // light and dark mode, it creates themes with poor contrast in light or dark
  // mode depending on selected colors. The colors needs to be tunes for
  // each mode to look good.
  const FlexSchemeData(
    name: 'Pa-Auk Burgundy',
    description: 'Paauka Color Burgundy',
    light: FlexSchemeColor(
      primary: Color.fromARGB(255, 61, 10, 41),
      secondary: Color(0xFFD26900),
      swapOnMaterial3: true,
      appBarColor: FlexColor.mangoDarkTertiary,
    ),
    dark: FlexSchemeColor(
      primary: Color.fromARGB(255, 61, 10, 41),
      secondary: Color(0xFFD26900),
      swapOnMaterial3: true,
      appBarColor: FlexColor.amberDarkTertiary,
    ),
  ),
  const FlexSchemeData(
    name: 'Sayalay Pink',
    description: 'Pink Color of Nun',
    light: FlexSchemeColor(
      primary: Color.fromARGB(255, 209, 158, 190),
      secondary: Color.fromARGB(255, 72, 49, 69),
    ),
    dark: FlexSchemeColor(
      primary: Color.fromARGB(255, 209, 158, 190),
      secondary: Color.fromARGB(255, 72, 49, 69),
    ),
  ),
];
