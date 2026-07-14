import pandas as pd
import matplotlib.pyplot as plt

# --- File paths ---
output_file = r"C:\Users\rajes\OneDrive\Desktop\VLSI\BPM_counter\DigitalBlock\pre_processing_filter\PreProcessing\ppg_output.csv"

# --- Read CSV ---
df_out = pd.read_csv(output_file)

# --- Extract values ---
input_data = df_out["Input"].values
verilog_output = df_out["Output"].values

# --- Ensure equal length ---
min_len = min(len(input_data), len(verilog_output))
input_data = input_data[:min_len]
verilog_output = verilog_output[:min_len]

# --- Plot ---
plt.figure(figsize=(10, 5))
plt.plot(input_data, label="Original PPG Input", alpha=0.7)
plt.plot(verilog_output, label="Verilog Processed Output", linestyle='--', linewidth=1.2)

plt.xlabel("Sample Index")
plt.ylabel("Amplitude (10-bit signed)")
plt.title("PPG Filter: Input vs Verilog Output")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
