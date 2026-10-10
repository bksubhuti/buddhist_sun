/// Static body size chart shown in Sun Settings so people can adjust the
/// average-adult estimates in their mind. Reference only: the app never asks
/// for or stores the user's weight.
///
/// Columns: kg, lb, vitamin D made per minute, daily need (IU), sun time
/// to reach that need — each relative to the ~68 kg average adult.
/// Precomputed from body surface area (Livingston & Lee) and ~20 IU/kg;
/// test/vitamin_d_test.dart checks the numbers.
const List<(int, int, String, int, String)> vitDBodySizeChart = [
  (45, 99, '−24%', 900, '−16%'),
  (55, 121, '−13%', 1100, '−10%'),
  (68, 150, '—', 1400, '—'),
  (80, 176, '+11%', 1600, '+3%'),
  (90, 198, '+20%', 1800, '+8%'),
  (100, 220, '+28%', 2000, '+12%'),
  (110, 243, '+36%', 2200, '+15%'),
];
