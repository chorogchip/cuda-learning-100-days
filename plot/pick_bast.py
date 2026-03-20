#!/usr/bin/env python3
import re,sys

best={}
case=''
for line in open(sys.argv[1] if len(sys.argv)>1 else 0):
    if line.startswith('Executing:'):
        m=re.search(r'_([0-9]+)_([0-9]+)$', line.split()[-1])
        case=f'{m[1]} - {m[2]}' if m else ''
    elif '| N = ' in line:
        g=float(line.split()[0])
        m=re.search(r'N = 2\^(\d+)\s*=\s*(\d+)', line)
        k,n=map(int,m.groups())
        if n not in best or g>best[n][0]:
            best[n]=(g,case,k)

for n in sorted(best):
    g,c,k=best[n]
    print(f'N=2^{k:<2} = {n:<9} {g:<16.6f} {c}')
