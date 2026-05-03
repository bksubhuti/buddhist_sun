import re
import json
import os

with open("buddhavassa/index.html", "r") as f:
    content = f.read()

# Extract defaultPoyaList
poya_list_match = re.search(r'const defaultPoyaList = (\[.*?\]);', content, re.DOTALL)

# Extract vesakDates
vesak_dates_match = re.search(r'const vesakDates = ({.*?});', content, re.DOTALL)

# Tithi arrays
tithi_si_match = re.search(r'const tithiPaliS = (\[.*?\]);', content, re.DOTALL)
tithi_en_match = re.search(r'const tithiPaliE = (\[.*?\]);', content, re.DOTALL)

print("Extraction complete, generating Dart file...")

dart_code = """
class PoyaDay {
  final String d;
  final String t;
  final String r;
  final String m;
  final String me;

  const PoyaDay({
    required this.d,
    required this.t,
    required this.r,
    required this.m,
    required this.me,
  });
}

class BuddhavassaData {
  static const Map<String, dynamic> i18n = {
    'si': {
        'title': "බුද්ධ වර්ෂය", 'dateLabel': "දිනය තෝරන්න ( ක්‍රි.ව)", 'atikkanta': "අතික්කන්ත(ඉකුත් වූ)", 'avasittha': "අවසිට්ඨ(ඉතිරි)",
        'poyaMenu': "පොහොය දින🌛", 'vasMenu': "වස් කාලය ⛈️", 'contactMenu': "ℹ️", 'poyaTitle': "පොහොය දින ලැයිස්තුව",
        'vasTitle': "වස් පිළිබඳව", 'contactTitle': " තොරතුරු සහ බාගත කිරීම්", 'poyaSuffix': " පෝය",
        'vas1': "පෙරවස් සමාදන්වීම", 'vas2': "පෙරවස් පවාරණය", 'vas3': "පසුවස් සමාදන්වීම", 'vas4': "පසුවස් පවාරණය",
        'animals': ["සප්ප","අස්ස","අජ","කපි","කුක්කුට","සෝන","සූකර","මුසික","උසභ","ව්‍යග්ග","සස","නාග"],
        'seasons': { 'Hemanta': "හේමන්ත", 'Gimhana': "ගිම්හාන", 'Vassana': "වස්සාන", 'ReHemanta': "නැවත හේමන්ත" },
        'paksha': { 'Kanha': "කණ්හ පක්ඛෙ", 'Sukka': "සුක්ක පක්ඛෙ" },
        'week': ["රවිවාරං","චන්දවාරං","භුම්මවාරං","බුධවාරං","ගුරුවාරං","සුක්කවාරං","සෝරවාරං"],
    },
    'en': {
        'title': "Buddhist Era", 'dateLabel': "Select Date (C.E.)", 'atikkanta': "Atikkanta(Elapsed)", 'avasittha': "Avasiṭṭha(remaining)",
        'poyaMenu': "Poya Days🌛", 'vasMenu': "Vas Season ⛈️", 'contactMenu': "ℹ️", 'poyaTitle': "Poya Day List",
        'vasTitle': "About Vas Season", 'contactTitle': "Contact & Downloads", 'poyaSuffix': " Poya",
        'vas1': "Entering Hera-vas", 'vas2': "Pavāraṇā (Hera-vas)", 'vas3': "Entering Pasu-vas", 'vas4': "Pavāraṇā (Pasu-vas)",
        'animals': ["Sappa","Assa","Aja","Kapi","Kukkuṭa","Sona","Sūkara","Musika","Usabha","Vyaggha","Sasa","Nāga"],
        'seasons': { 'Hemanta': "Hemanta", 'Gimhana': "Gimhāna", 'Vassana': "Vassāna", 'ReHemanta': "Late Hemanta" },
        'paksha': { 'Kanha': "Kaṇha pakkhe", 'Sukka': "Sukka pakkhe" },
        'week': ["Ravivāraṃ","Candavāraṃ","Bhummavāraṃ","Budhavāraṃ","Guruvāraṃ","Sukkavāraṃ","Soravāraṃ"],
    }
  };

  static String paliTemplate(String lang, String a, String s, String m, String p, String t, String w) {
    if (lang == 'si') {
      return "අයං\\n$a සංවච්ඡරෙ\\n$s උතු අස්මිං උතුම්හි\\n$m මාසස්ස\\n$p\\n$t\\n$w\\nඉදන්ති දට්ඨබ්බං.";
    } else {
      return "Ayaṃ\\n$a saṃvacchare\\n$s utu asmiṃ utumhi\\n$m māsassa\\n$p\\n$t\\n$w\\nidanti daṭṭhabbaṃ.";
    }
  }

"""

# parse vesak dates
vd_str = vesak_dates_match.group(1)
vd_str = vd_str.replace('\n', '').replace('  ', '')
vd_str = re.sub(r'([0-9]{4}):', r"'\1':", vd_str)
vd_str = re.sub(r'"([0-9]{4}-[0-9]{2}-[0-9]{2})"', r"'\1'", vd_str)
dart_code += f"  static const Map<String, String> vesakDates = {vd_str};\n\n"

# parse tithi arrays
ts_str = tithi_si_match.group(1).replace('"', "'")
te_str = tithi_en_match.group(1).replace('"', "'")

dart_code += f"  static const List<String> tithiPaliS = {ts_str};\n"
dart_code += f"  static const List<String> tithiPaliE = {te_str};\n\n"

# parse poya list
poya_str = poya_list_match.group(1)
# clean up the JS array to Dart List of PoyaDay objects
poya_str = re.sub(r'\{d:\s*"([^"]+)",\s*t:\s*"([^"]+)",\s*r:\s*"([^"]+)",\s*m:\s*"([^"]+)",\s*me:\s*"([^"]+)"\}', 
                  r"PoyaDay(d: '\1', t: '\2', r: '\3', m: '\4', me: '\5')", poya_str)
dart_code += f"  static const List<PoyaDay> poyaList = {poya_str};\n"
dart_code += "}\n"

os.makedirs("lib/utils", exist_ok=True)
with open("lib/utils/buddhavassa_data.dart", "w") as f:
    f.write(dart_code)

print("lib/utils/buddhavassa_data.dart created successfully!")
