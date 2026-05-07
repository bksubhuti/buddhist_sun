import re

moon_map = {
    'පසළොස්වක': 'FullMoon',
    'අමාවක': 'NewMoon'
}

season_map = {
    'ගිම්හාන': 'Gimhana',
    'වස්සාන': 'Vassana',
    'හේමන්ත': 'Hemanta'
}

with open('scratch_old_data.dart', 'r') as f:
    lines = f.readlines()

csv_lines = ["Date,MoonPhase,Season,Month,PoyaName"]
for line in lines:
    if "PoyaDay(d:" in line:
        matches = re.findall(r"PoyaDay\(d:\s*'([^']+)',\s*t:\s*'([^']+)',\s*r:\s*'([^']+)',\s*m:\s*'([^']+)',\s*me:\s*'([^']+)'\)", line)
        for m in matches:
            date, t, r, m_sinhala, poya_name = m
            moon_phase = moon_map.get(t, t)
            season = season_map.get(r, r)
            csv_lines.append(f"{date},{moon_phase},{season},{m_sinhala},{poya_name}")

with open('assets/calendars/sri_lanka.csv', 'w') as f:
    f.write("\n".join(csv_lines) + "\n")

print(f"Extracted {len(csv_lines)-1} records to sri_lanka.csv")
