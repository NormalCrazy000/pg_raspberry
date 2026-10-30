#!/usr/bin/env bash
# Benchmark completo per il Raspberry Pi, in un solo comando:
#
#   wget -qO- https://raw.githubusercontent.com/NormalCrazy000/pg_raspberry/main/tools/pi_report.sh | bash
#
# Scarica l'ultima release del gioco, lancia le prove e salva tutto in ~/risultati_pi.txt.
# Durata: circa 5 minuti. Lo schermo del Pi deve essere acceso con il desktop avviato.
set -uo pipefail

REPO="NormalCrazy000/pg_raspberry"
WORK="$HOME/hotfix-friday-benchmark"
OUT="$HOME/risultati_pi.txt"
DURATION="${BENCH_DURATION:-20}" # secondi per ogni prova della scena di prova

# Da SSH il gioco va aperto sullo schermo del Pi.
export DISPLAY="${DISPLAY:-:0}"

case "$(uname -m)" in
	aarch64) platform="rpi-arm64" ;;
	armv7l | armv6l) platform="rpi-arm32" ;;
	x86_64) platform="linux-x86_64" ;; # utile per provare lo script su un PC
	*) echo "Architettura non supportata: $(uname -m)" >&2; exit 1 ;;
esac

echo "Scarico l'ultima versione del gioco ($platform)..."
rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK" || exit 1
downloaded=""
for name in "hotfix-friday-$platform.tar.gz" "pg_raspberry-$platform.tar.gz"; do
	if wget -q "https://github.com/$REPO/releases/latest/download/$name"; then
		downloaded="$name"
		break
	fi
done
if [ -z "$downloaded" ]; then
	echo "Download non riuscito: controlla la connessione a internet." >&2
	exit 1
fi
tar -xzf "$downloaded"
bin="$(find "$WORK" -maxdepth 2 -type f -executable \( -name '*.arm64' -o -name '*.arm32' -o -name '*.x86_64' \) | head -n1)"
if [ -z "$bin" ]; then
	echo "Eseguibile del gioco non trovato nell'archivio." >&2
	exit 1
fi
cd "$(dirname "$bin")" || exit 1
bin="./$(basename "$bin")"

section() { echo; echo "== $*"; }
bench() {
	echo "-- $*"
	"$bin" --bench --duration="$DURATION" "$@" 2>&1 | grep -E "Renderer|RISULTATO"
}
# Temperatura e throttling: prima dai file del kernel (leggibili da tutti), poi da vcgencmd
# (che senza il gruppo "video" non ha i permessi). Se nessuno funziona si va avanti senza.
system_state() {
	local temp_file="/sys/class/thermal/thermal_zone0/temp"
	local throttled_file="/sys/devices/platform/soc/soc:firmware/get_throttled"
	local raw="" value
	if [ -r "$temp_file" ]; then
		echo "temp=$(awk '{printf "%.1f", $1 / 1000}' "$temp_file")'C"
	elif command -v vcgencmd >/dev/null; then
		vcgencmd measure_temp 2>&1
	fi
	if [ -r "$throttled_file" ]; then
		raw="0x$(cat "$throttled_file")"
	elif command -v vcgencmd >/dev/null; then
		raw="$(vcgencmd get_throttled 2>/dev/null)"
		raw="${raw#*=}"
	fi
	if ! [[ "$raw" =~ ^0x[0-9a-fA-F]+$ ]]; then
		echo "stato di alimentazione non disponibile"
		return 0
	fi
	echo "throttled=$raw"
	value=$((raw))
	[ "$value" -eq 0 ] && echo "  ok: nessun problema di alimentazione o temperatura"
	(( value & 0x1 )) && echo "  ATTENZIONE: tensione troppo bassa adesso (alimentatore o cavo insufficiente)"
	(( value & 0x4 )) && echo "  ATTENZIONE: processore rallentato adesso"
	(( value & 0x8 )) && echo "  ATTENZIONE: limite di temperatura raggiunto adesso"
	(( value & 0x10000 )) && echo "  tensione bassa avvenuta dall'accensione"
	(( value & 0x40000 )) && echo "  rallentamento avvenuto dall'accensione"
	(( value & 0x80000 )) && echo "  limite di temperatura (60 gradi) raggiunto dall'accensione"
	return 0
}

echo "Avvio delle prove: il gioco si aprirà più volte sullo schermo. Non toccare nulla per circa 5 minuti."
{
	section "VERSIONE"
	echo "archivio: $downloaded"
	section "SISTEMA"
	tr -d '\0' < /proc/device-tree/model 2>/dev/null; echo
	uname -m
	grep -E "PRETTY_NAME" /etc/os-release
	free -h | head -2
	section "STATO INIZIALE"
	system_state
	section "GRAFICA"
	if command -v glxinfo >/dev/null; then
		glxinfo -B | grep -E "renderer|version"
	else
		echo "glxinfo non installato (facoltativo: sudo apt install mesa-utils)"
	fi
	section "SCENA DI PROVA"
	bench --pegs=100 --balls=1
	bench --pegs=100 --balls=5 --fx
	bench --pegs=200 --balls=10 --fx --novsync
	section "SFIDA VERA, GRAFICA AUTOMATICA"
	"$bin" --autoplay=normal --measure --seed=1 2>&1 | grep -E "PRESTAZIONI|PICCHI|^ +[0-9]+ ms"
	section "SFIDA VERA, GRAFICA ALTA"
	"$bin" --autoplay=normal --measure --seed=1 --graphics=high 2>&1 | grep -E "PRESTAZIONI|PICCHI|^ +[0-9]+ ms"
	section "SFIDA VERA, CPU DIFFICILE"
	"$bin" --autoplay=hard --measure --seed=2 2>&1 | grep -E "PRESTAZIONI|PICCHI|^ +[0-9]+ ms"
	section "STATO FINALE"
	system_state
} 2>&1 | tee "$OUT"

echo
echo "Fatto. Risultati salvati in: $OUT"
echo "Per vederli e copiarli:  cat $OUT"
