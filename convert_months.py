import csv
import os

sinhala_to_pali = {
    "මාඝ": "Magha",
    "ඵග්ගුන": "Phagguna",
    "චිත්ත": "Citta",
    "අධිවේසාඛ": "Adhivesakha",
    "වේසාඛ": "Vesakha",
    "ජෙට්ඨ": "Jettha",
    "ආසාළ්හ": "Asalha",
    "සාවන": "Savana",
    "පොට්ඨපාද": "Potthapada",
    "අස්සයුජ": "Assayuja",
    "කත්තික": "Kattika",
    "මාඝසිර": "Maghasira",
    "ඵුස්ස": "Phussa"
}

for file in ["sri_lanka.csv", "thai.csv", "myanmar.csv"]:
    path = f"assets/calendars/{file}"
    if not os.path.exists(path): continue
    with open(path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
    
    for i in range(1, len(rows)):
        if rows[i][3] in sinhala_to_pali:
            rows[i][3] = sinhala_to_pali[rows[i][3]]
            
    with open(path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(rows)

print("Done.")
