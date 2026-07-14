import numpy as np
import matplotlib.pyplot as plt


# FIXED POINT PARAMETERS
WL = 41
FL = 28
fs = 10000


# FILE NAMES
matlab_file = "lpf_output_Q13_28_41bit.mem"

rtl_files = {
    "Direct": [
        "output_direct_1.mem",
        "output_direct_2.mem",
        "output_direct_3.mem"
    ],
    "Genvar": [
        "output_genvar_1.mem",
        "output_genvar_2.mem",
        "output_genvar_3.mem"
    ],
    "Optimised": [
        "output_optimised_1.mem",
        "output_optimised_2.mem",
        "output_optimised_3.mem"
    ]
}


# SAFE BINARY TO FLOAT CONVERSION
def bin_to_float(bin_str):

    bin_str = bin_str.strip()

    # Ignore invalid values
    if ('x' in bin_str.lower()) or ('z' in bin_str.lower()):
        return None

    if len(bin_str) != WL:
        return None

    try:
        val = int(bin_str, 2)
    except:
        return None

    # Two's complement conversion
    if val >= 2**(WL - 1):
        val -= 2**WL

    return val / (2**FL)

# READ MATLAB FILE
def read_matlab_file(filename):
    data = []

    with open(filename, "r") as f:
        for line in f:
            parts = line.strip().split()

            if len(parts) != 3:
                continue

            row = []
            valid = True

            for p in parts:
                val = bin_to_float(p)
                if val is None:
                    valid = False
                    break
                row.append(val)

            if valid:
                data.append(row)

    return np.array(data)

# READ RTL FILE
def read_rtl_file(filename):
    data = []

    with open(filename, "r") as f:
        for line in f:
            val = bin_to_float(line)
            if val is not None:
                data.append(val)

    return np.array(data)

# LOAD MATLAB GOLDEN
print("Reading MATLAB golden file...")
golden = read_matlab_file(matlab_file)

if golden.size == 0:
    print("ERROR: MATLAB file not read correctly.")
    exit()

N = golden.shape[0]
t = np.arange(N) / fs

print("Golden samples:", N)

# PROCESS EACH RTL DESIGN
for design_name, files in rtl_files.items():

    print(f"\nProcessing {design_name}...")

    rtl_1 = read_rtl_file(files[0])
    rtl_2 = read_rtl_file(files[1])
    rtl_3 = read_rtl_file(files[2])

    # Make sure all 3 exist
    min_len_rtl = min(len(rtl_1), len(rtl_2), len(rtl_3))

    rtl = np.column_stack((
        rtl_1[:min_len_rtl],
        rtl_2[:min_len_rtl],
        rtl_3[:min_len_rtl]
    ))

    # Align with golden
    min_len = min(len(golden), len(rtl))

    golden_trim = golden[:min_len]
    rtl_trim = rtl[:min_len]
    t_trim = t[:min_len]

    # PLOTS
    plt.figure(figsize=(12,8))
    plt.suptitle(f"{design_name} RTL vs MATLAB Golden")

    freq_titles = ["900 Hz", "1100 Hz", "2000 Hz"]

    for i in range(3):

        plt.subplot(3,1,i+1)

        plt.plot(t_trim, golden_trim[:,i], label="MATLAB Golden", linewidth=2)
        plt.plot(t_trim, rtl_trim[:,i], '--', label="RTL Output")

        plt.title(freq_titles[i])
        plt.xlabel("Time (s)")
        plt.ylabel("Amplitude")
        plt.legend()
        plt.grid(True)

    plt.tight_layout()
    plt.show()

print("\nVerification completed.")