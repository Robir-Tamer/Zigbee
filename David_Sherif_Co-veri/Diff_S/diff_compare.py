#!/usr/bin/env python3
# diff_compare.py -- intuitive line-by-line PASS/FAIL comparison
# Usage: python diff_compare.py golden.txt questa.txt

import sys

def load(fname):
    with open(fname, 'r') as f:
        return [l.strip() for l in f.read().replace('\r','').split('\n') if l.strip() != '']

golden_file, sim_file = sys.argv[1], sys.argv[2]
G = load(golden_file)
S = load(sim_file)

print(f"Golden ({golden_file}): {len(G)} lines")
print(f"Sim    ({sim_file}): {len(S)} lines")
print("="*70)

n = max(len(G), len(S))
pass_cnt = 0
fail_cnt = 0
first_fails = []

GREEN = "\033[92m"; RED = "\033[91m"; RESET = "\033[0m"

for i in range(n):
    g = G[i] if i < len(G) else "<MISSING>"
    s = S[i] if i < len(S) else "<MISSING>"
    if g == s:
        pass_cnt += 1
    else:
        fail_cnt += 1
        if len(first_fails) < 30:
            first_fails.append((i+1, g, s))

print(f"\n{'LINE':>6} | {'GOLDEN':>10} | {'SIM':>10} | RESULT")
print("-"*45)
for line_no, g, s in first_fails:
    print(f"{line_no:>6} | {g:>10} | {s:>10} | {RED}FAIL{RESET}")

print("\n" + "="*70)
print(f"{GREEN}PASS{RESET}: {pass_cnt}   {RED}FAIL{RESET}: {fail_cnt}   TOTAL: {n}")
if fail_cnt == 0:
    print(f"{GREEN}>>> ALL SAMPLES MATCH <<<{RESET}")
else:
    print(f"{RED}>>> {fail_cnt} MISMATCHES FOUND (first {len(first_fails)} shown above) <<<{RESET}")