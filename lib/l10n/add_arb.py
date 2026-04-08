import json
import glob

arb_files = glob.glob('/Users/bhantesubhuti/git/buddhist_sun/lib/l10n/*.arb')

for file in arb_files:
    with open(file, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    if 'autoStartDawnTimer' not in data:
        data['autoStartDawnTimer'] = 'Auto-Start Dawn Timer'
    if 'autoStartNoonTimer' not in data:
        data['autoStartNoonTimer'] = 'Auto-Start Noon Timer'
        
    with open(file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
print("Updated all ARB files with autoStartDawnTimer and autoStartNoonTimer")
