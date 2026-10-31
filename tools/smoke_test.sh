#!/usr/bin/env bash
# Test rapido: gioca N sfide automatiche, N allenamenti e un torneo da 4 senza finestra, prova il tabellone
# del torneo e fallisce se qualcosa si blocca o dà errori di script.
# Uso: tools/smoke_test.sh [N]   (default 10)   — serve aver importato il progetto (editor o tools/export.sh)
set -uo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot3-headless}"
count="${1:-10}"
failed=0
for mode in "" --training; do
	for seed in $(seq 1 "$count"); do
		output="$(timeout 120 "$GODOT" --path . --fixed-fps 60 --autoplay=normal $mode --seed="$seed" 2>&1)"
		if echo "$output" | grep -q "SCRIPT ERROR" || ! echo "$output" | grep -q "AUTOPLAY"; then
			echo "FALLITO seme $seed $mode"
			echo "$output" | grep -E "SCRIPT ERROR|at:" | head -5
			failed=1
		else
			echo "$output" | grep "AUTOPLAY"
		fi
	done
done
output="$(timeout 300 "$GODOT" --path . --fixed-fps 60 --autoplay=normal --tournament --seed=1 2>&1)"
if echo "$output" | grep -q "SCRIPT ERROR" || ! echo "$output" | grep -q "AUTOPLAY campione"; then
	echo "FALLITO torneo"
	echo "$output" | grep -E "SCRIPT ERROR|at:" | head -5
	failed=1
else
	echo "$output" | grep "AUTOPLAY"
fi
output="$("$GODOT" --path . -s tools/test_bracket.gd 2>&1)"
echo "$output" | grep -E "TEST BRACKET|ERRORE"
echo "$output" | grep -q "TEST BRACKET OK" || failed=1
if [ "$failed" -ne 0 ]; then
	echo "Test fallito" >&2
	exit 1
fi
echo "Tutte le $count sfide, i $count allenamenti e il torneo completati senza errori"
