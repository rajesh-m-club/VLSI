import numpy as np

# ============================
# PARAMETERS
# ============================
Fs = 32
N = 8
FRAC_BITS = 4
SCALE = 2**FRAC_BITS

f1 = 12
f2 = 4

# ============================
# GENERATE SIGNAL (NO NORMALIZATION)
# ============================
n = np.arange(N)
t = n / Fs

x = np.sin(2*np.pi*f1*t) + np.sin(2*np.pi*f2*t)

# ============================
# FIXED POINT CONVERSION
# ============================
def float_to_q34(val):
    q = int(round(val * SCALE))
    if q > 127:
        q = 127
    if q < -128:
        q = -128
    return q

# ============================
# WRITE INPUT FILES (SEPARATE)
# ============================
with open("input_real.mem", "w") as fr, open("input_imag.mem", "w") as fi:
    for i in range(N):
        xr = float_to_q34(x[i])
        xi = 0

        fr.write(f"{xr}\n")
        fi.write(f"{xi}\n")

print("input_real.mem and input_imag.mem generated")

# ============================
# COMPUTE FFT
# ============================
X = np.fft.fft(x)

# ============================
# WRITE OUTPUT FILES
# ============================
with open("output_real.mem", "w") as fr, open("output_imag.mem", "w") as fi:
    for k in range(N):
        xr = float_to_q34(np.real(X[k]))
        xi = float_to_q34(np.imag(X[k]))

        fr.write(f"{xr}\n")
        fi.write(f"{xi}\n")

print("output_real.mem and output_imag.mem generated")

# ============================
# DEBUG
# ============================
print("\n🔹 Input (float):")
for i in range(N):
    print(f"x[{i}] = {x[i]:.4f}")

print("\n🔹 Input (Q3.4 integer):")
for i in range(N):
    print(f"x[{i}] = {float_to_q34(x[i])}")