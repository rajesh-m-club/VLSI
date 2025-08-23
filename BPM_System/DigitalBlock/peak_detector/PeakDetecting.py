import pandas as pd
import matplotlib.pyplot as plt

# File path
peak_file = r"C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/peak_detector/peak_output.csv"

# Read CSV
df = pd.read_csv(peak_file, names=["Index", "PPG_in", "Peak_Pulse"])

# Create subplots
fig, axs = plt.subplots(2, 1, figsize=(12, 6), sharex=True)

# Top plot: PPG waveform
axs[0].plot(df["Index"], df["PPG_in"], color='blue')
axs[0].set_ylabel("PPG Amplitude")
axs[0].set_title("PPG Input Signal")
axs[0].grid(True)

# Bottom plot: Peak Pulse square wave
axs[1].step(df["Index"], df["Peak_Pulse"], where='post', color='red')
axs[1].set_xlabel("Sample Index")
axs[1].set_ylabel("Peak Pulse")
axs[1].set_title("Detected Peaks (1 = Peak)")
axs[1].set_ylim(-0.2, 1.2)
axs[1].grid(True)

plt.tight_layout()
plt.show()
