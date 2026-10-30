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
system_state() {
	if command -v vcgencmd >/dev/null; then
		vcgencmd measure_temp
		vcgencmd get_throttled
	else
		echo "vcgencmd non disponibile"
	fi
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
