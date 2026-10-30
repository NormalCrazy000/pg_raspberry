#!/usr/bin/env bash
# Esegue una serie di benchmark e mostra i risultati. Da lanciare sul Raspberry Pi
# nella cartella del gioco esportato (accanto al binario e al .pck).
# Uso: ./rpi_bench.sh [durata_secondi]   (default: 20)
set -euo pipefail
cd "$(dirname "$0")"

duration="${1:-20}"
bin=""
for candidate in pg_raspberry.arm64 pg_raspberry.arm32 pg_raspberry.x86_64; do
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

echo
echo "Risultati completi (CSV): ~/.local/share/godot/app_userdata/pg_raspberry/bench_results.csv"
