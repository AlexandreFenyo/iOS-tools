#!/bin/bash
#
# generate_oid_dictionary.sh
#
# Generates a static OID dictionary (oid_dictionary.json) from net-snmp's snmptranslate.
# Run this on a server where snmptranslate and python3 are installed.
#
# Usage: ./generate_oid_dictionary.sh
# Output: oid_dictionary.json in the current directory

set -euo pipefail

exec python3 - "$@" << 'PYEOF'
import subprocess
import json
import re
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

OUTFILE = "oid_dictionary.json"
PARALLEL = 50
LIMIT = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 0

def get_all_oids():
    result = subprocess.run(
        ['snmptranslate', '-mall', '-To'],
        capture_output=True, text=True
    )
    oids = sorted(set(line.strip() for line in result.stdout.strip().split('\n')
                       if line.strip() and line.strip().startswith('.')))
    return oids

def translate_one(label):
    """Run snmptranslate -Td on one OID label and return (label, raw_output)."""
    try:
        result = subprocess.run(
            ['snmptranslate', '-mall', '-Td', label],
            capture_output=True, text=True, timeout=10
        )
        return (label, result.stdout.strip())
    except Exception:
        return (label, '')

def get_numeric(label):
    """Run snmptranslate -On to get the numeric OID."""
    try:
        result = subprocess.run(
            ['snmptranslate', '-mall', '-On', label],
            capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip()
    except Exception:
        return ''

def parse_td_output(text):
    if not text:
        return None

    lines = text.split('\n')
    if not lines:
        return None

    info = {}
    info['oid'] = lines[0].strip()

    for line in lines:
        if '  -- FROM' in line:
            info['mib'] = re.sub(r'.*--\s*FROM\s*', '', line).strip()
        elif '  -- TEXTUAL CONVENTION' in line:
            info['conv'] = re.sub(r'.*--\s*TEXTUAL CONVENTION\s*', '', line).strip()
        elif re.match(r'\s+SYNTAX\s', line) and '::=' not in line:
            info['syntax'] = re.sub(r'^\s*SYNTAX\s+', '', line).strip()
        elif '  DISPLAY-HINT' in line:
            info['hint'] = re.sub(r'.*DISPLAY-HINT\s*', '', line).strip()
        elif '  MAX-ACCESS' in line:
            info['access'] = re.sub(r'.*MAX-ACCESS\s*', '', line).strip()
        elif re.match(r'\s+STATUS\s', line):
            info['status'] = re.sub(r'^\s*STATUS\s+', '', line).strip()
        elif '::= ' in line:
            info['line'] = re.sub(r'::=\s*', '', line).strip()

    desc_started = False
    desc_lines = []
    for line in lines:
        if desc_started:
            if '::= ' in line:
                break
            desc_lines.append(line)
        elif 'DESCRIPTION' in line:
            desc_started = True
            remainder = re.sub(r'.*DESCRIPTION\s*', '', line).strip()
            if remainder.startswith('"'):
                remainder = remainder[1:]
            if remainder:
                desc_lines.append(remainder)

    desc = ' '.join(l.strip() for l in desc_lines).strip()
    if desc.endswith('"'):
        desc = desc[:-1]
    info['description'] = desc

    for key in ('mib', 'conv', 'syntax', 'hint', 'access', 'status', 'line', 'description'):
        if key not in info:
            info[key] = ''

    return info

# --- Main ---

print("Step 1: Enumerating all OIDs from MIBs...")
all_oids = get_all_oids()
if LIMIT:
    all_oids = all_oids[:LIMIT]
    print(f"  Found {len(all_oids)} OIDs (limited to {LIMIT}).")
else:
    print(f"  Found {len(all_oids)} OIDs.")

print("Step 2: Translating each OID (parallel)...")
raw_results = {}
done = 0
with ThreadPoolExecutor(max_workers=PARALLEL) as pool:
    futures = {pool.submit(translate_one, label): label for label in all_oids}
    for future in as_completed(futures):
        label, raw = future.result()
        if raw:
            raw_results[label] = raw
        done += 1
        if done % 1000 == 0:
            print(f"  {done} / {len(all_oids)}...")

print(f"  Got {len(raw_results)} non-empty translations.")

print("Step 3: Parsing translations...")
data = {}
aliases = {}
for label, raw in raw_results.items():
    info = parse_td_output(raw)
    if info is None or not info.get('oid'):
        continue

    oid_full = info['oid']
    if not oid_full:
        continue

    # Remove empty fields to save space
    info = {k: v for k, v in info.items() if v}

    # Primary key: MODULE::name
    data[oid_full] = info

    # Alias: short name -> MODULE::name
    if '::' in oid_full:
        short_name = oid_full.split('::')[1]
        if short_name and short_name not in data:
            aliases[short_name] = oid_full

print(f"  {len(data)} primary entries, {len(aliases)} short-name aliases.")

print("Step 4: Adding numeric OID aliases (parallel)...")
primary_keys = list(data.keys())
done = 0
with ThreadPoolExecutor(max_workers=PARALLEL) as pool:
    futures = {pool.submit(get_numeric, sym): sym for sym in primary_keys}
    for future in as_completed(futures):
        sym = futures[future]
        numeric = future.result()
        if numeric and numeric.startswith('.') and numeric not in data:
            aliases[numeric] = sym
        done += 1
        if done % 1000 == 0:
            print(f"  {done} / {len(primary_keys)}...")

print(f"  {len(aliases)} total aliases.")

print(f"Step 5: Writing {OUTFILE}...")
output = {"data": data, "aliases": aliases}
with open(OUTFILE, 'w') as f:
    json.dump(output, f, ensure_ascii=False, separators=(',', ':'))

size = os.path.getsize(OUTFILE)
if size > 1024 * 1024:
    print(f"  {len(data)} entries + {len(aliases)} aliases, {size / 1024 / 1024:.1f} MB")
else:
    print(f"  {len(data)} entries + {len(aliases)} aliases, {size / 1024:.0f} KB")
print("Done.")
PYEOF
