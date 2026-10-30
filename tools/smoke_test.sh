#!/usr/bin/env bash
# Test rapido: gioca N sfide automatiche senza finestra e fallisce se una si blocca o dà errori di script.
# Uso: tools/smoke_test.sh [N]   (default 10)   — serve aver importato il progetto (editor o tools/export.sh)
set -uo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot3-headless}"
count="${1:-10}"
failed=0
for seed in $(seq 1 "$count"); do
	output="$(timeout 120 "$GODOT" --path . --fixed-fps 60 --autoplay=normal --seed="$seed" 2>&1)"
	if echo "$output" | grep -q "SCRIPT ERROR" || ! echo "$output" | grep -q "AUTOPLAY vincitore"; then
		echo "FALLITO seme $seed"
		echo "$output" | grep -E "SCRIPT ERROR|at:" | head -5
		failed=1
	else
		echo "$output" | grep "AUTOPLAY vincitore"
	fi
done
if [ "$failed" -ne 0 ]; then
	echo "Test fallito" >&2
	exit 1
fi
echo "Tutte le $count sfide completate senza errori"
