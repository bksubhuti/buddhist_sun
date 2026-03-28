import json
import glob
import os

arb_files = glob.glob('/Users/bhantesubhuti/git/buddhist_sun/lib/l10n/*.arb')

for file in arb_files:
    with open(file, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    if 'buddhistSunCountdown' not in data:
        data['buddhistSunCountdown'] = 'Buddhist Sun Countdown'
        
    with open(file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
print("Updated all ARB files with buddhistSunCountdown")
