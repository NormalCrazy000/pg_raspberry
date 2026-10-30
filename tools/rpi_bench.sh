#!/usr/bin/env bash
# Esegue una serie di benchmark e mostra i risultati. Da lanciare sul Raspberry Pi
# nella cartella del gioco esportato (accanto al binario e al .pck).
# Uso: ./rpi_bench.sh [durata_secondi]   (default: 20)
set -euo pipefail
cd "$(dirname "$0")"

duration="${1:-20}"
bin=""
for candidate in hotfix-friday.arm64 hotfix-friday.arm32 hotfix-friday.x86_64; do
	if [ -x "$candidate" ]; then
		bin="$candidate"
		break
	fi
done
if [ -z "$bin" ]; then
	echo "Binario del gioco non trovato in $(pwd)" >&2
	exit 1
fi

run() {
	echo "== $* =="
	"./$bin" --bench --duration="$duration" "$@" 2>&1 | grep -E "Renderer|RISULTATO|Salvato"
}

run --pegs=100 --balls=1
run --pegs=100 --balls=5
run --pegs=100 --balls=5 --fx
run --pegs=200 --balls=5 --fx
run --pegs=100 --balls=1 --novsync
run --pegs=200 --balls=10 --fx --novsync

echo "== sfida vera: CPU contro CPU a tempo reale, con grafica e audio (circa 1-2 minuti) =="
"./$bin" --autoplay=normal --measure --seed=1 2>&1 | grep -E "PRESTAZIONI|AUTOPLAY"

echo
echo "Risultati completi (CSV): ~/.local/share/hotfix_friday/bench_results.csv"
