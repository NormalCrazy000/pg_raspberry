#!/usr/bin/env python3
"""Sintetizza da zero tutti i suoni del gioco in assets/audio/.

Uso: python3 tools/assets/make_audio.py
Richiede numpy; per la musica serve ffmpeg con libvorbis.
Tutto è generato da codice con un seme fisso: nessun campione di terzi.
"""
import subprocess
import wave
from pathlib import Path

import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio"
rng = np.random.default_rng(17)


def t_axis(duration):
    return np.arange(int(RATE * duration)) / RATE


def env(duration, attack=0.005, decay=None, release=0.02):
    """Inviluppo: attacco lineare, poi decadimento esponenziale (o sostegno) e coda."""
    t = t_axis(duration)
    e = np.minimum(1.0, t / max(attack, 1e-6))
    if decay:
        e *= np.exp(-t / decay)
    tail = int(RATE * release)
    if tail:
        e[-tail:] *= np.linspace(1.0, 0.0, tail)
    return e


def tone(freq, duration, shape="sine", harmonics=(1.0,)):
    """Oscillatore con frequenza costante o variabile (array)."""
    t = t_axis(duration)
    f = np.broadcast_to(freq, t.shape)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    if shape == "square":
        return np.sign(np.sin(phase)) * 0.6
    if shape == "triangle":
        return 2 / np.pi * np.arcsin(np.sin(phase))
    out = np.zeros_like(t)
    for i, amp in enumerate(harmonics, start=1):
        out += amp * np.sin(phase * i)
    return out / sum(harmonics)


def noise(duration):
    return rng.uniform(-1, 1, int(RATE * duration))


def lowpass(x, alpha):
    """Filtro passa-basso a un polo (alpha piccolo = più scuro)."""
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def note(n):
    """Frequenza della nota MIDI n."""
    return 440.0 * 2 ** ((n - 69) / 12)


def save_wav(name, x, gain=0.8):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) or 1.0
    data = (x / peak * gain * 32767).astype(np.int16)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())
    print(f"  {name}.wav  {len(x) / RATE:.2f}s")


def mix(*parts):
    length = max(len(p) for p in parts)
    out = np.zeros(length)
    for p in parts:
        out[:len(p)] += p
    return out


def at(x, seconds, total):
    """Posiziona il suono x a `seconds` dentro un buffer lungo `total` secondi."""
    out = np.zeros(int(RATE * total))
    start = int(RATE * seconds)
    end = min(len(out), start + len(x))
    out[start:end] += x[:end - start]
    return out


# --- Effetti sonori ---

def sfx():
    # Piolo normale: "tic" breve e rotondo. Il gioco ne alza l'intonazione a ogni colpo dello stesso tiro.
    d = 0.16
    save_wav("peg", tone(note(76), d, harmonics=(1, 0.3, 0.1)) * env(d, decay=0.04))

    # Bug: "zap" elettrico con un po' di rumore.
    d = 0.22
    f = np.linspace(note(84), note(72), int(RATE * d))
    save_wav("bug", (tone(f, d, "square") * 0.6 + lowpass(noise(d), 0.3) * 0.4) * env(d, decay=0.06))

    # Caffè: tre note che salgono, brillanti.
    d = 0.42
    notes = [note(n) for n in (79, 83, 86)]
    parts = [at(tone(f, 0.18, harmonics=(1, 0.5, 0.2)) * env(0.18, decay=0.07), i * 0.07, d) for i, f in enumerate(notes)]
    save_wav("coffee", mix(*parts))

    # Lancio: squittio da paperella di gomma (frequenza che sale e scende, con vibrato).
    d = 0.2
    t = t_axis(d)
    f = 900 + 600 * np.sin(np.pi * t / d) + 40 * np.sin(2 * np.pi * 38 * t)
    save_wav("launch", tone(f, d, harmonics=(1, 0.6, 0.35, 0.2)) * env(d, attack=0.01, release=0.05), gain=0.6)

    # Cestino: "clonk" metallico basso.
    d = 0.3
    save_wav("bucket", (tone(note(45), d, harmonics=(1, 0, 0.5, 0, 0.3)) * env(d, decay=0.08)
                        + lowpass(noise(d), 0.15) * env(d, decay=0.02) * 0.6))

    # Portale: glissando verso il basso e di nuovo su.
    d = 0.35
    t = t_axis(d)
    f = 300 + 500 * np.abs(np.cos(np.pi * t / d))
    save_wav("portal", tone(f, d, "triangle") * env(d, attack=0.02, release=0.08), gain=0.6)

    # Paperella extra: campanello a due note.
    d = 0.5
    save_wav("extra", mix(at(tone(note(84), 0.3, harmonics=(1, 0.4)) * env(0.3, decay=0.12), 0, d),
                          at(tone(note(91), 0.35, harmonics=(1, 0.4)) * env(0.35, decay=0.14), 0.1, d)))

    # Moltiplicatore: tre note veloci.
    d = 0.32
    save_wav("multiplier", mix(*[at(tone(note(n), 0.12, "square") * env(0.12, decay=0.05) * 0.5, i * 0.07, d)
                                 for i, n in enumerate((72, 76, 79))]))

    # Fine sfida: piccolo jingle in maggiore.
    d = 1.3
    melody = [(72, 0.0), (76, 0.12), (79, 0.24), (84, 0.36), (79, 0.56), (84, 0.68)]
    parts = [at(tone(note(n), 0.5, harmonics=(1, 0.5, 0.25)) * env(0.5, decay=0.18), s, d) for n, s in melody]
    parts.append(at(tone(note(48), 1.0, "triangle") * env(1.0, decay=0.4) * 0.6, 0.36, d))
    save_wav("win", mix(*parts))

    # Cambio turno / menu: tasto di tastiera meccanica.
    d = 0.06
    save_wav("click", lowpass(noise(d), 0.5) * env(d, attack=0.001, decay=0.012) + tone(2200, d) * env(d, decay=0.008) * 0.3,
             gain=0.5)


# --- Musica ---

def music():
    """Loop lo-fi di 8 battute a 84 BPM: piano elettrico, basso, cassa e charleston."""
    bpm = 84
    beat = 60 / bpm
    bars = 8
    total = bars * 4 * beat
    length = int(RATE * total)
    out = np.zeros(length + RATE * 3)  # spazio per le code delle note oltre la fine
    chords = [  # Am7, Dm7, G7, Cmaj7 (due volte)
        (57, 60, 64, 67), (50, 57, 60, 65), (55, 59, 62, 65), (48, 55, 59, 64),
    ] * 2

    def add(x, seconds):
        start = int(RATE * seconds)
        end = min(len(out), start + len(x))
        out[start:end] += x[:end - start]

    for bar, chord in enumerate(chords):
        bar_start = bar * 4 * beat
        # Piano elettrico: accordo sul primo e sul terzo tempo, con tremolo morbido.
        for hit in (0, 2.5):
            d = 2.0 * beat
            t = t_axis(d)
            trem = 1 + 0.15 * np.sin(2 * np.pi * 4.5 * t)
            for n in chord:
                add(tone(note(n + 12), d, harmonics=(1, 0.35, 0.12)) * env(d, attack=0.01, decay=0.9) * trem * 0.12,
                    bar_start + hit * beat)
        # Basso: fondamentale sul primo tempo, quinta sul terzo.
        root = chord[0] - 12
        for beat_i, n in ((0, root), (2, root + 7), (3.5, root + 12)):
            d = 0.9 * beat
            add(tone(note(n), d, "triangle") * env(d, attack=0.01, decay=0.35) * 0.35, bar_start + beat_i * beat)
        # Cassa sui tempi 1 e 3, rullante leggero su 2 e 4, charleston in ottavi.
        for beat_i in range(4):
            if beat_i in (0, 2):
                d = 0.25
                t = t_axis(d)
                add(tone(60 + 90 * np.exp(-t / 0.03), d) * env(d, decay=0.08) * 0.5, bar_start + beat_i * beat)
            else:
                d = 0.15
                add(lowpass(noise(d), 0.35) * env(d, decay=0.04) * 0.18, bar_start + beat_i * beat)
        for eighth in range(8):
            d = 0.05
            hat = (noise(d) - lowpass(noise(d), 0.2)) * env(d, attack=0.001, decay=0.012)
            add(hat * (0.08 if eighth % 2 else 0.05), bar_start + eighth * beat / 2)

    # Le code oltre la fine vengono riportate all'inizio: il loop non ha salti.
    tail = out[length:]
    out = out[:length]
    out[:len(tail)] += tail
    # Un filo di fruscio da vinile, per l'atmosfera lo-fi.
    out += lowpass(noise(total), 0.05)[:length] * 0.015
    wav = OUT / "music_tmp.wav"
    save_wav("music_tmp", out, gain=0.7)
    ogg = OUT / "music.ogg"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "3", str(ogg)],
                   check=True)
    wav.unlink()
    print(f"  music.ogg  {total:.1f}s (loop)")


if __name__ == "__main__":
    print(f"Genero i suoni in {OUT}")
    sfx()
    music()
