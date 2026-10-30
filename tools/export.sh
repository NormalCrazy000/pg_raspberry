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
	cp tools/rpi_bench.sh tools/install.sh icon.png "build/$dir/"
	tar -czf "build/$dir.tar.gz" -C build "$dir"
	echo "-> build/$dir.tar.gz"
}

case "$target" in
	x86_64) export_preset "Linux x86_64" hotfix-friday-linux-x86_64 hotfix-friday.x86_64 ;;
	arm64) export_preset "Raspberry Pi arm64" hotfix-friday-rpi-arm64 hotfix-friday.arm64 ;;
	arm32) export_preset "Raspberry Pi arm32" hotfix-friday-rpi-arm32 hotfix-friday.arm32 ;;
	all)
		"$0" x86_64
		"$0" arm64
		"$0" arm32
		;;
	*) echo "Target sconosciuto: $target" >&2; exit 1 ;;
esac
