#!/usr/bin/env python3
"""Synthesises PLACEHOLDER sound effects and a music loop for Hose Survivors.

All audio is generated from scratch (no samples), so it is licence-free.
Re-run with:  python3 tools/gen_audio.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rnd = random.Random(1)


def write(rel, samples, volume=0.8):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(32767 * volume * s / peak)) for s in samples))
    print("wrote", rel, "%.2fs" % (len(samples) / RATE))


def square(ph):
    return 1.0 if (ph % 1.0) < 0.5 else -1.0


def tri(ph):
    return 4.0 * abs((ph % 1.0) - 0.5) - 1.0


def tone(dur, f0, f1=None, wave_fn=square, attack=0.005, decay_pow=1.5, vib=0.0):
    n = int(dur * RATE)
    out, ph = [], 0.0
    f1 = f0 if f1 is None else f1
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t + vib * math.sin(i / RATE * 40)
        ph += f / RATE
        env = min(1.0, i / (attack * RATE + 1)) * (1.0 - t) ** decay_pow
        out.append(wave_fn(ph) * env)
    return out


def noise(dur, lp0=0.5, lp1=0.1, decay_pow=1.5, attack=0.004):
    n = int(dur * RATE)
    out, y = [], 0.0
    for i in range(n):
        t = i / n
        k = lp0 + (lp1 - lp0) * t
        y += k * (rnd.uniform(-1, 1) - y)
        env = min(1.0, i / (attack * RATE + 1)) * (1.0 - t) ** decay_pow
        out.append(y * env)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def seq(*parts):
    out = []
    for p in parts:
        out += p
    return out


def scale(s, k):
    return [x * k for x in s]


def gen_sfx():
    write("sfx/hose_spray.wav", noise(0.45, 0.75, 0.35, 0.8, 0.03), 0.5)
    write("sfx/water_hit.wav", mix(noise(0.07, 0.6, 0.15, 2.0), scale(tone(0.07, 520, 180, tri), 0.5)), 0.5)
    write("sfx/enemy_death.wav", mix(noise(0.14, 0.4, 0.05, 1.5), scale(tone(0.14, 300, 70), 0.5)), 0.6)
    write("sfx/xp_pickup.wav", tone(0.07, 880, 1320, tri, decay_pow=1.0), 0.45)
    write("sfx/coin_pickup.wav", seq(tone(0.05, 1568, wave_fn=square), tone(0.12, 2093, wave_fn=square)), 0.35)
    write("sfx/heal.wav", seq(tone(0.08, 523, wave_fn=tri), tone(0.08, 659, wave_fn=tri), tone(0.16, 784, wave_fn=tri)), 0.6)
    write("sfx/level_up.wav", seq(*[tone(0.08, f, wave_fn=square, decay_pow=0.6) for f in (523, 659, 784, 1047)],
                                  tone(0.3, 1319, wave_fn=square)), 0.5)
    write("sfx/evolution.wav", mix(seq(*[tone(0.1, f, wave_fn=square, decay_pow=0.5) for f in (262, 330, 392, 523, 659, 784, 1047)],
                                       tone(0.6, 1568, wave_fn=square, vib=20)), scale(noise(1.3, 0.2, 0.6, 0.5), 0.3)), 0.6)
    write("sfx/player_hurt.wav", mix(tone(0.2, 220, 80, square), scale(noise(0.2, 0.5, 0.1), 0.6)), 0.7)
    write("sfx/boss_intro.wav", mix(tone(1.6, 82, 55, square, attack=0.2, decay_pow=0.6, vib=3),
                                    scale(tone(1.6, 41, 41, tri, attack=0.2, decay_pow=0.4), 1.0),
                                    scale(noise(1.6, 0.05, 0.3, 0.5, 0.3), 0.5)), 0.8)
    write("sfx/elite_intro.wav", seq(tone(0.15, 196, wave_fn=square), tone(0.15, 185, wave_fn=square), tone(0.4, 147, wave_fn=square)), 0.6)
    write("sfx/boss_attack.wav", mix(noise(0.4, 0.3, 0.02, 1.2), tone(0.4, 120, 40, square)), 0.8)
    write("sfx/telegraph.wav", tone(0.25, 660, 990, tri, decay_pow=0.5), 0.4)
    write("sfx/crate_open.wav", seq(tone(0.06, 392), tone(0.06, 523), tone(0.06, 659), tone(0.25, 1047, vib=15)), 0.5)
    write("sfx/ui_move.wav", tone(0.04, 440, wave_fn=square), 0.3)
    write("sfx/ui_select.wav", seq(tone(0.05, 660, wave_fn=square), tone(0.09, 990, wave_fn=square)), 0.4)
    write("sfx/victory.wav", seq(*[tone(d, f, wave_fn=square, decay_pow=0.5) for f, d in
                                   ((523, .15), (523, .15), (523, .15), (659, .3), (587, .15), (659, .15), (784, .2), (1047, .7))]), 0.5)
    write("sfx/defeat.wav", seq(*[tone(d, f, wave_fn=tri, decay_pow=0.6) for f, d in
                                  ((392, .25), (370, .25), (349, .25), (262, .9))]), 0.6)


def gen_music():
    """~22 s driving minor-key chiptune loop: bass + arp + noise drums."""
    bpm = 150
    step = 60.0 / bpm / 4  # 16th note
    n_step = int(step * RATE)
    roots = [45, 45, 41, 43, 45, 45, 48, 43]  # A minor-ish progression, midi notes (one per bar)
    arps = [(0, 3, 7, 12), (0, 3, 7, 12), (0, 4, 7, 12), (0, 4, 7, 11), (0, 3, 7, 12), (0, 3, 7, 15), (0, 4, 7, 12), (0, 4, 7, 14)]
    lead = [69, 0, 72, 0, 76, 0, 72, 74, 0, 72, 0, 69, 0, 67, 69, 0]
    total = n_step * 16 * len(roots)
    out = [0.0] * total

    def hz(m):
        return 440.0 * 2 ** ((m - 69) / 12.0)

    def add(start, s, k):
        for i, v in enumerate(s):
            if start + i < total:
                out[start + i] += v * k

    for bar, root in enumerate(roots):
        for s in range(16):
            at = (bar * 16 + s) * n_step
            # bass: driving 8ths with octave jumps
            if s % 2 == 0:
                add(at, tone(step * 1.8, hz(root - 12 + (12 if s % 8 == 6 else 0)), wave_fn=tri, decay_pow=0.7), 0.9)
            # arp
            add(at, tone(step * 0.9, hz(root + 12 + arps[bar][s % 4]), wave_fn=square, decay_pow=1.2), 0.22)
            # lead in second half of loop
            if bar >= 4 and lead[s]:
                add(at, tone(step * 1.6, hz(lead[s] + (root - 45)), wave_fn=square, decay_pow=0.8, vib=4), 0.3)
            # drums
            if s % 8 == 0 or (s % 16 == 10):
                add(at, tone(0.09, 150, 40, tri, decay_pow=1.0), 1.0)
            if s % 8 == 4:
                add(at, noise(0.1, 0.7, 0.3, 1.5), 0.6)
            if s % 2 == 1:
                add(at, noise(0.025, 0.9, 0.9, 1.0), 0.18)
    write("music/wasteland_loop.wav", out, 0.6)


if __name__ == "__main__":
    gen_sfx()
    gen_music()
