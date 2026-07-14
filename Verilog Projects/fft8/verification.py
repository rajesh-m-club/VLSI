import numpy as np
import matplotlib.pyplot as plt

# ============================
# Read RTL output
# ============================
rtl_real = []
rtl_imag = []

with open("fft8_output_ordered.mem", "r") as f:
    for line in f:
        r, i = map(int, line.strip().split())
        rtl_real.append(r)
        rtl_imag.append(i)

rtl_real = np.array(rtl_real)
rtl_imag = np.array(rtl_imag)
rtl_fft = rtl_real + 1j * rtl_imag


# ============================
# Read Python output
# ============================
py_real = np.loadtxt("output_real.mem")
py_imag = np.loadtxt("output_imag.mem")
py_fft = py_real + 1j * py_imag


# ============================
# Normalize
# ============================
rtl_fft = rtl_fft / np.max(np.abs(rtl_fft))
py_fft  = py_fft  / np.max(np.abs(py_fft))


# ============================
# X-axis
# ============================
k = np.arange(8)


# ============================
# Magnitude (STEM PLOT)
# ============================
plt.figure()
plt.title("FFT Magnitude (Spike Plot)")

plt.stem(k, np.abs(py_fft), linefmt='b-', markerfmt='bo', basefmt=" ", label="Python")
plt.stem(k, np.abs(rtl_fft), linefmt='r--', markerfmt='rs', basefmt=" ", label="RTL")

plt.xlabel("Frequency Bin (k)")
plt.ylabel("Magnitude")
plt.legend()
plt.grid()

plt.show()


# ============================
# Real Part (STEM)
# ============================
plt.figure()
plt.title("Real Part (Spike Plot)")

plt.stem(k, py_real, linefmt='b-', markerfmt='bo', basefmt=" ", label="Python")
plt.stem(k, rtl_real, linefmt='r--', markerfmt='rs', basefmt=" ", label="RTL")

plt.legend()
plt.grid()
plt.show()


# ============================
# Imag Part (STEM)
# ============================
plt.figure()
plt.title("Imag Part (Spike Plot)")

plt.stem(k, py_imag, linefmt='b-', markerfmt='bo', basefmt=" ", label="Python")
plt.stem(k, rtl_imag, linefmt='r--', markerfmt='rs', basefmt=" ", label="RTL")

plt.legend()
plt.grid()
plt.show()