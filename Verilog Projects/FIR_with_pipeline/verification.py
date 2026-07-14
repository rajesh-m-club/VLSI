import numpy as np
import matplotlib.pyplot as plt

# ================= PARAMETERS =================
WL = 41
FL = 28
fs = 10000

# Per-design latency (initial guess, auto-refined)
LATENCY_DICT = {
    "Direct_Pipelined": 6,
    "Genvar_Pipelined": 8,
    "Optimised_Pipelined": 7
}

matlab_file = "lpf_output_Q13_28_41bit.mem"

rtl_files = {
    "Direct_Pipelined": [
        "output_pipelined_1.mem",
        "output_pipelined_2.mem",
        "output_pipelined_3.mem"
    ],
    "Genvar_Pipelined": [
        "output_genvar_pipe_1.mem",
        "output_genvar_pipe_2.mem",
        "output_genvar_pipe_3.mem"
    ],
    "Optimised_Pipelined": [
        "output_opt_pipe_1.mem",
        "output_opt_pipe_2.mem",
        "output_opt_pipe_3.mem"
    ]
}

# ================= SAFE CONVERSION =================
def bin_to_float(bin_str):
    bin_str = bin_str.strip()

    if ('x' in bin_str.lower()) or ('z' in bin_str.lower()):
        return None

    if len(bin_str) != WL:
        return None

    try:
        val = int(bin_str, 2)
    except:
        return None

    if val >= 2**(WL - 1):
        val -= 2**WL

    return val / (2**FL)

# ================= FILE READ =================
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

def read_rtl_file(filename):
    data = []

    with open(filename, "r") as f:
        for line in f:
            val = bin_to_float(line)
            if val is not None:
                data.append(val)

    return np.array(data)

# ================= AUTO LATENCY =================
def find_best_latency(golden, rtl, max_search=30):
    """
    Finds best latency using cross-correlation
    """
    best_latency = 0
    best_corr = -1

    ref_golden = golden[:,0]   # use first signal

    for shift in range(max_search):
        if len(rtl) <= shift:
            break

        aligned = rtl[shift:shift+len(ref_golden)]
        ref = ref_golden[:len(aligned)]

        if len(aligned) < 100:
            continue

        corr = np.corrcoef(ref, aligned[:,0])[0,1]

        if corr > best_corr:
            best_corr = corr
            best_latency = shift

    return best_latency

# ================= LOAD GOLDEN =================
print("Reading MATLAB golden file...")
golden = read_matlab_file(matlab_file)

if golden.size == 0:
    print("ERROR: MATLAB file failed.")
    exit()

N = golden.shape[0]
t = np.arange(N) / fs

print("Golden samples:", N)

# ================= MAIN LOOP =================
for design_name, files in rtl_files.items():

    print(f"\nProcessing {design_name}...")

    rtl_1 = read_rtl_file(files[0])
    rtl_2 = read_rtl_file(files[1])
    rtl_3 = read_rtl_file(files[2])

    min_len_rtl = min(len(rtl_1), len(rtl_2), len(rtl_3))

    rtl = np.column_stack((
        rtl_1[:min_len_rtl],
        rtl_2[:min_len_rtl],
        rtl_3[:min_len_rtl]
    ))

    # 🔥 Step 1: initial latency guess
    init_latency = LATENCY_DICT[design_name]

    # 🔥 Step 2: refine using auto-correlation
    best_latency = find_best_latency(golden, rtl)

    print(f"Initial latency: {init_latency}")
    print(f"Auto-detected latency: {best_latency}")

    LAT = best_latency

    # ================= ALIGN FULL WAVEFORM =================
    rtl_aligned = rtl[LAT:]
    golden_aligned = golden[:len(rtl_aligned)]

    min_len = min(len(golden_aligned), len(rtl_aligned))

    golden_trim = golden_aligned[:min_len]
    rtl_trim    = rtl_aligned[:min_len]
    t_trim      = t[:min_len]

    # ================= ERROR =================
    error = np.abs(golden_trim - rtl_trim)
    max_error = np.max(error)

    print(f"Max error: {max_error}")

    # ================= PLOT FULL SIGNAL =================
    plt.figure(figsize=(14,8))
    plt.suptitle(f"{design_name} RTL vs MATLAB (FULL WAVEFORM)")

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