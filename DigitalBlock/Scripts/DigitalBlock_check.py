import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import find_peaks

# ======================
# Config
# ======================
FILE_PATH = r"C:\Users\rajes\OneDrive\Desktop\VLSI\BPM_counter\DigitalBlock\RTL\digitalblock_output.csv"
FS = 50          # Hz (original)
DS = 2           # downsample factor
FS_DS = FS // DS # 25 Hz after downsample
THRESHOLD = 50   # peak threshold (same as your spec)
REF_PERIOD = 8   # refractory samples (downsampled domain)

# ======================
# Verilog-accurate filters (Q15 + saturation to 10-bit signed)
# ======================

def hpf_verilog(x, alpha_q=30831, scale=15, width=10):
    alpha = alpha_q / (1 << scale)
    y = np.zeros_like(x, dtype=np.int32)
    x_prev = 0
    y_prev = 0

    max_val = (1 << (width - 1)) - 1   # +511 for 10-bit
    min_val = -(1 << (width - 1))      # -512 for 10-bit

    for n in range(len(x)):
        acc = y_prev + (int(x[n]) - int(x_prev))
        acc_scaled = acc * alpha_q
        acc_scaled = acc_scaled + (1 << (scale - 1))    # rounding
        acc_shift = acc_scaled >> scale

        if acc_shift > max_val:
            y_n = max_val
        elif acc_shift < min_val:
            y_n = min_val
        else:
            y_n = acc_shift

        y[n] = y_n
        x_prev = int(x[n])
        y_prev = y_n

    return y.astype(np.int16)

def lpf_verilog(x, alpha_q=12629, scale=15, width=10):
    y = np.zeros_like(x, dtype=np.int32)
    y_prev = 0

    max_val = (1 << (width - 1)) - 1
    min_val = -(1 << (width - 1))

    for n in range(len(x)):
        diff = int(x[n]) - int(y_prev)
        mult = diff * alpha_q
        mult = mult + (1 << (scale - 1))
        mult_shift = mult >> scale
        acc = y_prev + mult_shift

        if acc > max_val:
            y_n = max_val
        elif acc < min_val:
            y_n = min_val
        else:
            y_n = acc

        y[n] = y_n
        y_prev = y_n

    return y.astype(np.int16)

# ======================
# Helper: BPM series from detected peaks
# ======================
def bpm_from_peaks(peaks, fs):
    N = int(peaks[-1] + 1) if len(peaks) > 0 else 0
    bpm_series = np.zeros(N, dtype=float)

    if len(peaks) >= 2:
        intervals = np.diff(peaks) / fs
        inst_bpm = 60.0 / intervals
        overall_bpm = np.mean(inst_bpm)

        for k in range(1, len(peaks)):
            idx = peaks[k]
            if idx < len(bpm_series):
                bpm_series[idx] = inst_bpm[k-1]

        last = 0.0
        for i in range(len(bpm_series)):
            if bpm_series[i] == 0.0:
                bpm_series[i] = last
            else:
                last = bpm_series[i]
        return overall_bpm, bpm_series
    else:
        return 0.0, bpm_series

# ======================
# Load CSV
# ======================
df = pd.read_csv(FILE_PATH)
req_cols = ["ppg_in", "ppg_filt", "peak_pulse", "bpm_value"]
missing = [c for c in req_cols if c not in df.columns]
if missing:
    raise ValueError(f"CSV missing columns: {missing}")

ppg_in = df["ppg_in"].astype(int).to_numpy()
ppg_filt_file = df["ppg_filt"].astype(int).to_numpy()
peak_file = df["peak_pulse"].astype(int).to_numpy()
bpm_file = df["bpm_value"].astype(float).to_numpy()

# ======================
# Python pipeline (Verilog-equivalent)
# ======================
ppg_hp = hpf_verilog(ppg_in)
ppg_lp = lpf_verilog(ppg_hp)
ppg_py_ds = ppg_lp[::DS]  # downsample

# ======================
# Alignment
# ======================
len_file = len(ppg_filt_file)
len_py_pre = len(ppg_lp)
len_py_post = len(ppg_py_ds)

if len_file == len_py_post:
    mode = "post"
    ppg_filt_aligned = ppg_py_ds
    ppg_file_aligned = ppg_filt_file
    fs_for_peaks = FS_DS
    ref_period = REF_PERIOD
elif len_file == len_py_pre:
    mode = "pre"
    ppg_filt_aligned = ppg_lp
    ppg_file_aligned = ppg_filt_file
    fs_for_peaks = FS
    ref_period = REF_PERIOD * DS
else:
    post_diff = abs(len_file - len_py_post)
    pre_diff = abs(len_file - len_py_pre)
    if post_diff <= pre_diff:
        mode = "post-trunc"
        L = min(len_file, len_py_post)
        ppg_filt_aligned = ppg_py_ds[:L]
        ppg_file_aligned = ppg_filt_file[:L]
        fs_for_peaks = FS_DS
        ref_period = REF_PERIOD
    else:
        mode = "pre-trunc"
        L = min(len_file, len_py_pre)
        ppg_filt_aligned = ppg_lp[:L]
        ppg_file_aligned = ppg_filt_file[:L]
        fs_for_peaks = FS
        ref_period = REF_PERIOD * DS

# ======================
# Peak detection
# ======================
peaks_py, props = find_peaks(ppg_filt_aligned, height=THRESHOLD, distance=ref_period)

if len(peak_file) != len(ppg_file_aligned):
    L = min(len(peak_file), len(ppg_file_aligned))
    peak_file_aligned = peak_file[:L]
    csv_peaks_idx = np.where(peak_file_aligned == 1)[0]
    ppg_file_for_peaks = ppg_file_aligned[:L]
else:
    peak_file_aligned = peak_file
    csv_peaks_idx = np.where(peak_file_aligned == 1)[0]
    ppg_file_for_peaks = ppg_file_aligned

# ======================
# BPM
# ======================
overall_bpm_py, bpm_series_py = bpm_from_peaks(peaks_py, fs_for_peaks)

if len(bpm_file) < len(bpm_series_py):
    bpm_py_aligned = bpm_series_py[:len(bpm_file)]
    bpm_csv_aligned = bpm_file
else:
    bpm_py_aligned = np.zeros(len(bpm_file))
    bpm_py_aligned[:len(bpm_series_py)] = bpm_series_py
    bpm_csv_aligned = bpm_file

def match_with_tolerance(a_idx, b_idx, tol=1):
    a_idx = np.array(a_idx, dtype=int)
    b_idx = np.array(b_idx, dtype=int)
    matched_a = np.zeros(len(a_idx), dtype=bool)
    matched_b = np.zeros(len(b_idx), dtype=bool)

    j = 0
    for i in range(len(a_idx)):
        while j < len(b_idx) and b_idx[j] < a_idx[i] - tol:
            j += 1
        if j < len(b_idx) and abs(b_idx[j] - a_idx[i]) <= tol:
            matched_a[i] = True
            matched_b[j] = True
    tp = matched_a.sum()
    fp = (~matched_a).sum()
    fn = (~matched_b).sum()
    return tp, fp, fn

tp, fp, fn = match_with_tolerance(peaks_py, csv_peaks_idx, tol=1)

# ======================
# Report
# ======================
print("=== Lengths ===")
print(f"ppg_in: {len(ppg_in)} | CSV ppg_filt: {len(ppg_filt_file)} | py_pre: {len_py_pre} | py_post: {len_py_post}")
print(f"Alignment mode: {mode}")

print("\n=== Peaks ===")
print(f"Python peaks: {len(peaks_py)} @ fs={fs_for_peaks}Hz   (threshold={THRESHOLD}, refractory={ref_period})")
print(f"CSV peaks:    {len(csv_peaks_idx)}")
print(f"Peak match (±1 sample): TP={tp}, FP={fp}, FN={fn}")

print("\n=== BPM ===")
print(f"Overall BPM (Python): {overall_bpm_py:.2f}")

overall_bpm_csv = 0.0
if len(bpm_py_aligned) > 0:
    mask = bpm_csv_aligned > 0
    if mask.any():
        mae = np.mean(np.abs(bpm_py_aligned[mask] - bpm_csv_aligned[mask]))
        overall_bpm_csv = np.mean(bpm_csv_aligned[mask])
        print(f"Overall BPM (Verilog/CSV): {overall_bpm_csv:.2f}")
        print(f"Per-sample BPM MAE vs CSV (where CSV>0): {mae:.2f}")
    else:
        print("CSV bpm_value appears zero/constant; per-sample comparison skipped.")
else:
    print("No BPM series (not enough peaks).")

# ======================
# Plotting
# ======================
plt.figure(figsize=(14, 12))

# 1) Raw input
ax1 = plt.subplot(3,1,1)
ax1.plot(ppg_in, label="ppg_in (raw)")
ax1.set_title("Raw Input PPG")
ax1.legend()

# 2) Filtered comparison + Peaks
ax2 = plt.subplot(3,1,2)
ax2.plot(ppg_file_aligned, label="ppg_filt (from CSV)", alpha=0.7)
ax2.plot(ppg_filt_aligned, label="ppg_filt (Python, Verilog-accurate)", alpha=0.7)
ax2.scatter(peaks_py, ppg_filt_aligned[peaks_py], marker="x", label="Python Peaks")
if len(csv_peaks_idx) > 0:
    csv_peaks_vals = ppg_file_for_peaks[csv_peaks_idx]
    ax2.scatter(csv_peaks_idx, csv_peaks_vals, marker="o", facecolors='none', edgecolors='green', label="CSV Peaks")
ax2.set_title("Filtered Signal Comparison + Peak Detection")
ax2.legend()

# 3) BPM comparison
ax3 = plt.subplot(3,1,3)
bpm_len = len(bpm_py_aligned)
ax3.plot(np.arange(bpm_len), bpm_py_aligned, label="BPM (Python, per-sample updates)")
ax3.plot(np.arange(len(bpm_csv_aligned)), bpm_csv_aligned, label="BPM from CSV", alpha=0.7)

# horizontal average lines
if overall_bpm_py > 0:
    ax3.axhline(y=overall_bpm_py, color="blue", linestyle="--", alpha=0.7, label=f"Avg BPM Python = {overall_bpm_py:.1f}")
if overall_bpm_csv > 0:
    ax3.axhline(y=overall_bpm_csv, color="orange", linestyle="--", alpha=0.7, label=f"Avg BPM Verilog = {overall_bpm_csv:.1f}")

ax3.set_title("BPM Comparison")
ax3.legend()

plt.tight_layout()
plt.show()
