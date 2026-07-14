import numpy as np
import pandas as pd

# Sampling parameters
Fs = 50  # Hz (your preprocessing rate)
T = 10   # seconds
t = np.arange(0, T, 1/Fs)

# Generate synthetic PPG signal
heart_rate_hz = 1.2  # ~72 BPM
ppg_clean = 0.6 * np.sin(2 * np.pi * heart_rate_hz * t)**3  # mimic PPG peaks
baseline_wander = 0.2 * np.sin(2 * np.pi * 0.1 * t)         # slow drift
noise = 0.05 * np.random.randn(len(t))                      # measurement noise
ppg_signal = ppg_clean + baseline_wander + noise

# Quantize to signed 10-bit integer
ppg_signal_scaled = np.round(ppg_signal * (2**9 - 1))  # scale to ~512 amplitude
ppg_signal_scaled = np.clip(ppg_signal_scaled, -512, 511).astype(int)

# Save to CSV
df = pd.DataFrame(ppg_signal_scaled, columns=["PPG"])
output_path = r"C:\Users\rajes\OneDrive\Desktop\VLSI\BPM_counter\pre_processing_filter\ppg_input.csv"
df.to_csv(output_path, index=False)

print(f"PPG input saved to {output_path}")
