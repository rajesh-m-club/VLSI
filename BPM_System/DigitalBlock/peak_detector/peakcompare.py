import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import find_peaks

# Load CSV: index, ppg_in, peakpulse
df = pd.read_csv("peak_output.csv", header=None, names=["Index", "PPG", "PeakPulse"])

# Python peak detection
THRESH = 50
REF_PERIOD = 8
peaks, _ = find_peaks(df["PPG"], height=THRESH, distance=REF_PERIOD)

# Verilog detected peaks
verilog_peaks = df["Index"][df["PeakPulse"] == 1]

# Plot
plt.figure(figsize=(12, 6))
plt.plot(df["Index"], df["PPG"], label="PPG Signal", color='blue')
plt.plot(verilog_peaks, df["PPG"].iloc[verilog_peaks], 'ro', label="Verilog Peaks")
plt.plot(df["Index"].iloc[peaks], df["PPG"].iloc[peaks], 'gx', label="Python Peaks")
plt.title("PPG Peak Detection Comparison")
plt.xlabel("Sample Index")
plt.ylabel("PPG Amplitude")
plt.grid(True)
plt.legend()
plt.show()
