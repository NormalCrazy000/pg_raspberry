#!/usr/bin/env bash
# Installa Hotfix Friday per l'utente corrente (nessun permesso di amministratore).
# Va lanciato dalla cartella del gioco estratta dall'archivio (accanto al binario e al .pck).
#
#   ./install.sh               installa e aggiunge il gioco al menu delle applicazioni
#   ./install.sh --autostart   come sopra, e avvia il gioco a schermo intero all'accensione (Raspberry Pi portatile)
#   ./install.sh --uninstall   rimuove gioco, voce di menu e avvio automatico (le statistiche restano)
set -euo pipefail
cd "$(dirname "$0")"

DEST="$HOME/.local/share/hotfix-friday-game"
LAUNCHER="$HOME/.local/bin/hotfix-friday"
DESKTOP="$HOME/.local/share/applications/hotfix-friday.desktop"
AUTOSTART="$HOME/.config/autostart/hotfix-friday.desktop"

if [ "${1:-}" = "--uninstall" ]; then
	rm -rf "$DEST" "$LAUNCHER" "$DESKTOP" "$AUTOSTART"
	echo "Hotfix Friday rimosso. Statistiche e opzioni restano in ~/.local/share/hotfix_friday/"
	exit 0
fi

bin=""
for candidate in pg_raspberry.x86_64 pg_raspberry.arm64 pg_raspberry.arm32; do
	if [ -x "$candidate" ]; then
		bin="$candidate"
		break
	fi
done
if [ -z "$bin" ]; then
	echo "Binario del gioco non trovato in $(pwd)" >&2
	exit 1
fi

mkdir -p "$DEST" "$(dirname "$LAUNCHER")" "$(dirname "$DESKTOP")"
cp "$bin" "${bin%.*}.pck" icon.png "$DEST/"
cat > "$LAUNCHER" <<SCRIPT
#!/usr/bin/env bash
exec "$DEST/$bin" "\$@"
SCRIPT
chmod +x "$LAUNCHER"

write_desktop() {
	cat > "$1" <<ENTRY
[Desktop Entry]
Type=Application
Name=Hotfix Friday
Comment=Peg shooter a turni in un ufficio di programmatori
Exec=$LAUNCHER $2
Icon=$DEST/icon.png
Terminal=false
Categories=Game;ArcadeGame;
ENTRY
}
write_desktop "$DESKTOP" ""
echo "Installato in $DEST"
echo "Avvio: hotfix-friday (o dal menu delle applicazioni, sezione Giochi)"

if [ "${1:-}" = "--autostart" ]; then
	mkdir -p "$(dirname "$AUTOSTART")"
	write_desktop "$AUTOSTART" "--fullscreen"
	echo "Avvio automatico a schermo intero attivato ($AUTOSTART)"
fi
