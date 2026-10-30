#!/usr/bin/env bash
# Esporta il gioco per desktop Linux e Raspberry Pi.
# Uso: tools/export.sh [x86_64|arm64|arm32|all]   (default: all)
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot3-headless}"
target="${1:-all}"

export_preset() {
	local preset="$1" dir="$2" bin="$3"
	mkdir -p "build/$dir"
	"$GODOT" --path . --export "$preset" "build/$dir/$bin"
	cp tools/rpi_bench.sh "build/$dir/"
	tar -czf "build/pg_raspberry-$dir.tar.gz" -C build "$dir"
	echo "-> build/pg_raspberry-$dir.tar.gz"
}

case "$target" in
	x86_64) export_preset "Linux x86_64" linux-x86_64 pg_raspberry.x86_64 ;;
	arm64) export_preset "Raspberry Pi arm64" rpi-arm64 pg_raspberry.arm64 ;;
	arm32) export_preset "Raspberry Pi arm32" rpi-arm32 pg_raspberry.arm32 ;;
	all)
		"$0" x86_64
		"$0" arm64
		"$0" arm32
		;;
	*) echo "Target sconosciuto: $target" >&2; exit 1 ;;
esac
