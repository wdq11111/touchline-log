import json,re,sys,glob,os
D=os.path.dirname(os.path.abspath(__file__))
keys=json.load(open(f'{D}/_keys.json'))
ph=lambda s:sorted(re.findall(r'\{\w+\}',s))
ok=True
for f in sorted(glob.glob(f'{D}/src/*.json')):
    code=os.path.basename(f)[:-5]; arr=json.load(open(f))
    if len(arr)!=len(keys): print(code,'LENGTH',len(arr),'vs',len(keys)); ok=False; continue
    bad=[(i,keys[i],arr[i]) for i in range(len(keys)) if ph(keys[i])!=ph(arr[i])]
    for b in bad: print(code,'PLACEHOLDER',b); ok=False
    if not bad:
        json.dump(dict(zip(keys,arr)),open(f'{D}/{code}.json','w'),ensure_ascii=False,separators=(',',':'))
        print(code,'ok')
sys.exit(0 if ok else 1)
