import 'package:intl/intl.dart';

void main() {
  int time = DateTime.parse("2026-05-01").millisecondsSinceEpoch;
  int nextA = DateTime.parse("2026-05-16").millisecondsSinceEpoch;
  int nextF = DateTime.parse("2026-05-01").millisecondsSinceEpoch;

  String paksha = "Sukka";
  if (nextA <= nextF) {
    paksha = "Kanha";
  }
  print("May 1 Paksha: $paksha");
}
