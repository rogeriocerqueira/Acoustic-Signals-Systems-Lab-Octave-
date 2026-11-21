#!/usr/bin/env python3
"""
make_gifs.py - gera os diagramas animados (GIF) usados no README.

    python3 tools/make_gifs.py            # todos, em docs/gif/
    python3 tools/make_gifs.py stft ks    # apenas alguns

Requer: numpy, matplotlib, pillow  (pip install numpy matplotlib pillow)

São ilustrações didáticas dos conceitos de cada experimento. Os cálculos
reais do laboratório continuam no Octave; aqui os sinais são pequenos e
escolhidos para ficarem legíveis na animação.
"""
import sys
from pathlib import Path

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter

OUT = Path(__file__).resolve().parent.parent / "docs" / "gif"

# paleta consistente em todos os GIFs
BLUE, RED, GREEN, ORANGE = "#2563eb", "#dc2626", "#16a34a", "#ea580c"
GRAY, LIGHT, INK = "#6b7280", "#e5e7eb", "#111827"

plt.rcParams.update({
    "figure.facecolor": "white", "axes.facecolor": "white",
    "axes.edgecolor": GRAY, "axes.labelcolor": INK, "axes.titleweight": "bold",
    "axes.spines.top": False, "axes.spines.right": False,
    "xtick.color": GRAY, "ytick.color": GRAY, "font.size": 10,
    "axes.grid": True, "grid.color": LIGHT, "grid.linewidth": 0.8,
})


def save(anim, name, fps):
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.gif"
    anim.save(path, writer=PillowWriter(fps=fps), dpi=80)
    plt.close(anim._fig)
    print(f"  > docs/gif/{name}.gif  ({path.stat().st_size/1024:.0f} KB)")


def hann(n):
    return 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(n) / n)


# ---------------------------------------------------------------- 1. STFT
def gif_stft():
    """Janela deslizante preenchendo o espectrograma, coluna por coluna (EX01)."""
    fs = 8000
    t = np.arange(int(1.6 * fs)) / fs
    x = np.zeros_like(t)
    for f0, t0 in [(196, 0.05), (247, 0.55), (294, 1.05)]:        # Sol, Si, Ré
        m = t >= t0
        tt = t[m] - t0
        for n in range(1, 9):
            x[m] += np.sin(2 * np.pi * n * f0 * tt) / n * np.exp(-tt * (2 + 0.6 * n))
    x /= np.abs(x).max()
    L, H = 400, 100
    frames = 1 + (len(x) - L) // H
    w = hann(L)
    S = np.array([np.abs(np.fft.rfft(x[m*H:m*H+L] * w, 1024)) for m in range(frames)]).T
    S = 20 * np.log10(S / S.max() + 1e-6)
    f = np.fft.rfftfreq(1024, 1 / fs)
    tc = (np.arange(frames) * H + L / 2) / fs

    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 5), gridspec_kw={"height_ratios": [1, 1.4]})
    fig.suptitle("STFT: uma FFT por janela, lado a lado no tempo", fontweight="bold")
    a1.plot(t, x, color=GRAY, lw=0.6)
    win_fill = a1.fill_between([0, 0], -1.1, 1.1, color=ORANGE, alpha=0.25)
    win_line, = a1.plot([], [], color=ORANGE, lw=2)
    a1.set_xlim(0, t[-1]); a1.set_ylim(-1.1, 1.1); a1.set_ylabel("x[n]")
    a1.set_title("janela de Hann deslizando sobre o sinal", fontsize=9, fontweight="normal")
    disp = np.full_like(S, np.nan)
    im = a2.imshow(disp, origin="lower", aspect="auto", cmap="magma", vmin=-70, vmax=0,
                   extent=[0, t[-1], 0, fs / 2])
    a2.set_ylim(0, 2000); a2.set_xlabel("Tempo (s)"); a2.set_ylabel("Frequência (Hz)")
    a2.grid(False)
    fig.tight_layout()

    step = 3
    def update(k):
        nonlocal win_fill
        m = min(k * step, frames - 1)
        t0, t1 = m * H / fs, (m * H + L) / fs
        win_fill.remove()
        win_fill = a1.fill_between([t0, t1], -1.1, 1.1, color=ORANGE, alpha=0.25)
        tw = np.linspace(t0, t1, L)
        win_line.set_data(tw, w * 1.05)
        disp[:, :m + 1] = S[:, :m + 1]
        im.set_data(disp)
        return im, win_line

    n = frames // step + 8                 # alguns quadros parados no fim
    save(FuncAnimation(fig, update, frames=n, blit=False), "stft", fps=15)


# ---------------------------------------------------------------- 2. corda palhetada
def gif_pluck():
    """Movimento de Helmholtz e o filtro pente da posição da palhetada (EX05)."""
    xs = np.linspace(0, 1, 400)
    N = 60
    n = np.arange(1, N + 1)
    betas = [1 / 4, 1 / 12]
    labels = ["perto do braço  (β = 1/4)", "perto da ponte  (β = 1/12)"]
    # deslocamento inicial triangular -> série de senos
    coefs = [2 * np.sin(n * np.pi * b) / (n**2 * np.pi**2 * b * (1 - b)) for b in betas]

    fig, axes = plt.subplots(2, 2, figsize=(9, 5), gridspec_kw={"height_ratios": [1, 1]})
    fig.suptitle("Onde você palheta decide quais harmônicos existem", fontweight="bold")
    lines = []
    for j, (b, lab, c) in enumerate(zip(betas, labels, coefs)):
        ax = axes[0, j]
        ax.axhline(0, color=LIGHT, lw=1)
        ln, = ax.plot([], [], color=BLUE, lw=2.5)
        ax.plot([b], [1.05], marker="v", color=ORANGE, ms=10)
        ax.text(b + 0.02, 1.05, "palheta", color=ORANGE, va="center", fontsize=9)
        ax.set_xlim(0, 1); ax.set_ylim(-1.15, 1.25)
        ax.set_xticks([0, 1]); ax.set_xticklabels(["ponte", "pestana"])
        ax.set_yticks([]); ax.set_title(lab, fontsize=10)
        lines.append(ln)

        ax2 = axes[1, j]
        amp = np.abs(np.sin(n[:24] * np.pi * b)) / n[:24]
        amp_db = 20 * np.log10(amp / amp.max() + 1e-4)
        notch = np.abs(np.sin(n[:24] * np.pi * b)) < 0.05
        ax2.bar(n[:24][~notch], amp_db[~notch] + 45, bottom=-45, color=BLUE, width=0.7)
        ax2.bar(n[:24][notch], 2, bottom=-45, color=RED, width=0.7)
        for k in n[:24][notch]:
            ax2.annotate("✕", (k, -40), ha="center", color=RED, fontsize=11, fontweight="bold")
        ax2.set_ylim(-45, 3); ax2.set_xlim(0.3, 24.7)
        ax2.set_xlabel("harmônico n"); ax2.set_ylabel("dB")
        ax2.set_title("|sin(nπβ)| / n  (✕ = harmônico apagado)", fontsize=9, fontweight="normal")
    fig.tight_layout()

    F = 48
    def update(k):
        ph = 2 * np.pi * k / F
        for ln, c in zip(lines, coefs):
            y = (c[:, None] * np.sin(np.outer(n, np.pi * xs)) * np.cos(n[:, None] * ph)).sum(0)
            ln.set_data(xs, y)
        return lines

    save(FuncAnimation(fig, update, frames=F, blit=True), "pluck", fps=16)


# ---------------------------------------------------------------- 3. Karplus-Strong
def gif_karplus_strong():
    """Ruído circulando no laço de atraso e virando uma nota periódica (EX06)."""
    rng = np.random.default_rng(4)
    L, periods, g = 60, 70, 0.995
    buf = rng.uniform(-1, 1, L)
    snaps, out = [], []
    for p in range(periods):
        snaps.append(buf.copy())
        out.extend(buf)
        new = np.empty(L)
        prev = buf[-1]
        for i in range(L):                       # y[n] = g * (y[n-L] + y[n-L-1]) / 2
            new[i] = g * 0.5 * (buf[i] + (buf[i - 1] if i else prev))
        buf = new
    out = np.array(out)

    fig = plt.figure(figsize=(9, 5))
    fig.suptitle("Karplus-Strong: ruído + atraso + média = corda", fontweight="bold")
    gs = fig.add_gridspec(2, 2, width_ratios=[1, 2.2], height_ratios=[1, 1])
    ad = fig.add_subplot(gs[:, 0]); ad.axis("off")
    box = dict(boxstyle="round,pad=0.4", fc="white", ec=INK, lw=1.2)
    ad.set_xlim(0, 1); ad.set_ylim(0, 1)
    ad.text(0.5, 0.85, "atraso  z⁻ᴸ\n(L amostras)", ha="center", va="center", bbox=box)
    ad.text(0.5, 0.5, "média\n(y[n] + y[n−1]) / 2", ha="center", va="center", bbox=box, fontsize=9)
    ad.text(0.5, 0.18, "ganho g < 1", ha="center", va="center", bbox=box)
    for y0, y1 in [(0.76, 0.6), (0.4, 0.25)]:
        ad.annotate("", (0.5, y1), (0.5, y0), arrowprops=dict(arrowstyle="->", color=INK, lw=1.3))
    ad.annotate("", (0.12, 0.85), (0.12, 0.18), arrowprops=dict(arrowstyle="->", color=ORANGE, lw=1.6,
                connectionstyle="arc3,rad=0"))
    ad.plot([0.12, 0.3], [0.18, 0.18], color=ORANGE, lw=1.6)
    ad.plot([0.12, 0.3], [0.85, 0.85], color=ORANGE, lw=1.6)
    ad.text(0.04, 0.52, "laço", rotation=90, color=ORANGE, va="center", fontweight="bold")
    ad.text(0.5, 0.02, "um período = uma volta no laço", ha="center", fontsize=8, color=GRAY)

    ab = fig.add_subplot(gs[0, 1])
    sb = ab.stem(np.arange(L), snaps[0], basefmt=" ")
    sb.markerline.set_color(BLUE); sb.markerline.set_markersize(3); sb.stemlines.set_color(BLUE)
    ab.set_ylim(-1.1, 1.1); ab.set_xlim(-1, L)
    title = ab.set_title("", fontsize=10)
    ab.set_ylabel("buffer")
    ao = fig.add_subplot(gs[1, 1])
    lo, = ao.plot([], [], color=INK, lw=0.7)
    ao.set_xlim(0, len(out)); ao.set_ylim(-1.1, 1.1)
    ao.set_xlabel("amostras de saída"); ao.set_ylabel("y[n]")
    fig.tight_layout()

    def update(k):
        p = min(k, periods - 1)
        segs = [[[i, 0], [i, v]] for i, v in enumerate(snaps[p])]
        sb.stemlines.set_segments(segs)
        sb.markerline.set_ydata(snaps[p])
        lo.set_data(np.arange((p + 1) * L), out[:(p + 1) * L])
        state = "ruído" if p < 3 else ("suavizando" if p < 20 else "periódico → nota afinada")
        title.set_text(f"volta {p + 1:2d} no laço: {state}")
        return lo,

    save(FuncAnimation(fig, update, frames=periods + 10, blit=False), "karplus_strong", fps=10)


# ---------------------------------------------------------------- 4. aliasing
def gif_aliasing():
    """Senoide com frequência crescente: acima de fs/2 ela 'volta' (EX07)."""
    fs = 20.0
    tc = np.linspace(0, 1, 1000)
    ts = np.arange(0, 1 + 1e-9, 1 / fs)
    freqs = np.concatenate([np.linspace(1, 19, 54), np.full(8, 19)])

    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 5.2), gridspec_kw={"height_ratios": [1.3, 1]})
    fig.suptitle("Aliasing: o que passa de fs/2 é refletido de volta", fontweight="bold")
    lc, = a1.plot([], [], color=GRAY, lw=1, label="sinal real")
    la, = a1.plot([], [], color=RED, lw=2, label="o que as amostras 'enxergam'")
    ls, = a1.plot([], [], "o", color=INK, ms=5, label="amostras")
    a1.set_xlim(0, 1); a1.set_ylim(-1.3, 1.6); a1.set_xlabel("tempo (s)")
    a1.legend(loc="upper right", ncol=3, fontsize=8, frameon=False)
    a2.axvspan(fs / 2, fs, color=RED, alpha=0.08)
    a2.axvline(fs / 2, color=RED, ls="--", lw=1.2)
    a2.text(fs / 2 + 0.2, 0.85, "Nyquist  fs/2", color=RED, fontsize=9)
    a2.text(fs * 0.76, 0.88, "não representável", color=RED, alpha=0.7, fontsize=9, ha="center")
    mt, = a2.plot([], [], "|", color=GRAY, ms=30, mew=3)
    ma, = a2.plot([], [], "|", color=RED, ms=30, mew=4)
    arr = a2.annotate("", (0, 0), (0, 0))
    a2.set_xlim(0, fs); a2.set_ylim(0, 1); a2.set_yticks([])
    a2.set_xlabel("frequência (Hz)   |   fs = 20 Hz")
    txt = a2.text(0.3, 0.85, "", fontsize=10, fontweight="bold")
    fig.tight_layout()

    def update(k):
        nonlocal arr
        f = freqs[k]
        fa = abs(f - round(f / fs) * fs)
        lc.set_data(tc, np.cos(2 * np.pi * f * tc))
        la.set_data(tc, np.cos(2 * np.pi * fa * tc))
        ls.set_data(ts, np.cos(2 * np.pi * f * ts))
        mt.set_data([f], [0.5]); ma.set_data([fa], [0.5])
        arr.remove()
        if f > fs / 2 + 0.05:
            arr = a2.annotate("", (fa, 0.3), (f, 0.3),
                              arrowprops=dict(arrowstyle="->", color=RED, lw=1.5, connectionstyle="arc3,rad=0.3"))
        else:
            arr = a2.annotate("", (0, 0), (0, 0))
        txt.set_text(f"real {f:4.1f} Hz  →  ouvido {fa:4.1f} Hz")
        txt.set_color(RED if f > fs / 2 else INK)
        return lc, la, ls

    save(FuncAnimation(fig, update, frames=len(freqs), blit=False), "aliasing", fps=12)


# ---------------------------------------------------------------- 5. convolução
def gif_convolution():
    """h[n] invertida deslizando sobre x[n]: soma dos produtos = y[n] (EX08)."""
    x = np.zeros(30); x[[3, 11, 15, 22]] = [1.0, 0.6, -0.8, 0.9]           # "palhetadas"
    h = np.exp(-np.arange(10) / 2.5) * np.cos(np.arange(10) * 1.3)         # IR curta
    y = np.convolve(x, h)
    N = len(y)
    nn = np.arange(N)

    fig, axs = plt.subplots(3, 1, figsize=(8, 5.6), sharex=True)
    fig.suptitle("Convolução: y[n] = Σ x[k] · h[n − k]", fontweight="bold")
    for ax in axs:
        ax.set_xlim(-10, N); ax.axhline(0, color=LIGHT, lw=1)
    sx = axs[0].stem(np.arange(len(x)), x, basefmt=" ")
    sx.markerline.set_color(BLUE); sx.stemlines.set_color(BLUE)
    axs[0].set_ylim(-1.2, 1.2); axs[0].set_ylabel("x[k]")
    axs[0].set_title("entrada (azul) e h[n−k] invertida e deslocada (laranja)", fontsize=9, fontweight="normal")
    hl, = axs[0].plot([], [], "o-", color=ORANGE, ms=4, lw=1.5)
    prod_bars = axs[1].bar(np.arange(-10, N), np.zeros(N + 10), color=GREEN, width=0.7)
    axs[1].set_ylim(-1.2, 1.2); axs[1].set_ylabel("x[k]·h[n−k]")
    axs[1].set_title("produto ponto a ponto, que será somado", fontsize=9, fontweight="normal")
    ly, = axs[2].plot([], [], "o-", color=INK, ms=4, lw=1.2)
    cur, = axs[2].plot([], [], "o", color=GREEN, ms=9)
    axs[2].set_ylim(np.min(y) * 1.3, np.max(y) * 1.3); axs[2].set_ylabel("y[n]")
    axs[2].set_xlabel("n")
    vline = [ax.axvline(0, color=GREEN, lw=1, ls=":") for ax in axs]
    fig.tight_layout()

    def update(k):
        n = min(k, N - 1)
        kk = n - np.arange(len(h))                   # posições de h[n-k]
        hl.set_data(kk, h)
        xp = np.zeros(N + 10)
        for j, kpos in enumerate(kk):
            if 0 <= kpos < len(x):
                xp[kpos + 10] = x[kpos] * h[j]
        for b, v in zip(prod_bars, xp):
            b.set_height(v)
        ly.set_data(nn[:n + 1], y[:n + 1]); cur.set_data([n], [y[n]])
        for v in vline:
            v.set_xdata([n, n])
        return hl, ly, cur

    save(FuncAnimation(fig, update, frames=N + 8, blit=False), "convolution", fps=5)


# ---------------------------------------------------------------- 6. inarmonicidade
def gif_inharmonicity():
    """Parciais saindo de n·f0 conforme a rigidez da corda (B) aumenta (EX03)."""
    f0, nmax = 110.0, 20
    n = np.arange(1, nmax + 1)
    Bs = np.concatenate([np.zeros(6), np.linspace(0, 4e-4, 50), np.full(10, 4e-4)])

    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 5), gridspec_kw={"height_ratios": [1, 1.1]})
    fig.suptitle("Inarmonicidade: corda rígida estica os parciais agudos", fontweight="bold")
    for k in n:
        a1.axvline(k * f0, color=LIGHT, lw=1.2, zorder=0)
    a1.text(0.99, 0.95, "cinza: série ideal n·f0   vermelho: deslocamento", transform=a1.transAxes, fontsize=8, color=GRAY, ha="right")
    yy = 1 - 0.85 * (n - 1) / nmax          # altura só para separar visualmente
    sc = a1.scatter(n * f0, yy, s=40, color=BLUE, zorder=3)
    shifts = [a1.plot([], [], color=RED, lw=2.5, solid_capstyle="butt")[0] for _ in n]
    a1.set_xlim(0, (nmax + 1.5) * f0); a1.set_ylim(0, 1.1); a1.set_yticks([])
    a1.set_xlabel("frequência (Hz)")
    nn = np.linspace(1, nmax, 200)
    lm, = a2.plot([], [], color=RED, lw=2)
    pts, = a2.plot([], [], "o", color=BLUE, ms=5)
    a2.axhline(50, color=GRAY, ls=":", lw=1)
    a2.text(1.2, 52, "50 cents = meio semitom", fontsize=8, color=GRAY)
    a2.set_xlim(0.5, nmax + 0.5); a2.set_ylim(-3, 120)
    a2.set_xlabel("harmônico n"); a2.set_ylabel("desvio (cents)")
    title = a2.set_title("", fontsize=10)
    fig.tight_layout(h_pad=2.5)

    def update(k):
        B = Bs[k]
        fn = n * f0 * np.sqrt(1 + B * n**2)
        sc.set_offsets(np.c_[fn, yy])
        for ln, k, f, y in zip(shifts, n, fn, yy):
            ln.set_data([k * f0, f], [y, y])
        lm.set_data(nn, 1200 * np.log2(np.sqrt(1 + B * nn**2)))
        pts.set_data(n, 1200 * np.log2(fn / (n * f0)))
        title.set_text(f"f_n = n·f0·√(1 + B·n²)      B = {B:.1e}")
        return sc, lm, pts

    save(FuncAnimation(fig, update, frames=len(Bs), blit=False), "inharmonicity", fps=12)


ALL = {"stft": gif_stft, "pluck": gif_pluck, "ks": gif_karplus_strong,
       "aliasing": gif_aliasing, "convolution": gif_convolution, "inharmonicity": gif_inharmonicity}

if __name__ == "__main__":
    which = sys.argv[1:] or list(ALL)
    for name in which:
        print(f"[{name}]")
        ALL[name]()
