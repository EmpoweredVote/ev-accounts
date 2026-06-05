"""
Reads migration SQL files and splits them into per-politician chunks,
printing each chunk so it can be applied via execute_sql.
Usage: python3 apply_stances_batch.py 234
"""
import sys
import re

mignum = sys.argv[1]
fname_map = {
    '233': 'backend/migrations/233_ca_assembly_stances.sql',
    '234': 'backend/migrations/234_ca_state_senate_stances.sql',
}

fname = fname_map[mignum]
with open(fname, encoding='utf-8') as f:
    content = f.read()

# Strip BEGIN/COMMIT wrappers
content = re.sub(r'^\s*BEGIN;\s*', '', content)
content = re.sub(r'\s*COMMIT;\s*$', '', content)
content = content.strip()

# Split into blocks by politician_id pairs (each pair = answer + context inserts)
# Each "block" starts with a comment line
blocks = re.split(r'\n(?=-- )', content)
blocks = [b.strip() for b in blocks if b.strip() and not b.strip().startswith('--\n') and 'INSERT' in b]

print(f"Total blocks: {len(blocks)}", file=sys.stderr)

# Group into batches of 20 blocks each
batch_size = 20
for i in range(0, len(blocks), batch_size):
    batch = blocks[i:i+batch_size]
    sql = 'BEGIN;\n\n' + '\n\n'.join(batch) + '\n\nCOMMIT;'
    print(f"=== BATCH {i//batch_size + 1} ({len(batch)} stances, blocks {i+1}-{i+len(batch)}) ===")
    print(sql[:200] + '...' if len(sql) > 200 else sql)
    print()
