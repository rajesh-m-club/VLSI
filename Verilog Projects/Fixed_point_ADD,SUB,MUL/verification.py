import numpy as np
import matplotlib.pyplot as plt


# PARAMETERS
Fs = 48000            # Sampling frequency
f  = 1000             # Sine frequency
A  = 2.0              # Sine amplitude
N  = 479              # 10 cycles at 48 kHz
Q512_SCALE = 2**12    # Q5.12 scaling


# LOAD RTL RESULTS

add_data = np.loadtxt("results_add.csv", delimiter=",", skiprows=1)
sub_data = np.loadtxt("results_sub.csv", delimiter=",", skiprows=1)
mul_data = np.loadtxt("results_mul.csv", delimiter=",", skiprows=1)


# FIXED → FLOAT

q314 = add_data[:, 0] / Q512_SCALE
q512 = add_data[:, 1] / Q512_SCALE

add_out = add_data[:, 2] / Q512_SCALE
sub_out = sub_data[:, 2] / Q512_SCALE
mul_out = mul_data[:, 2] / Q512_SCALE


# GOLDEN ANALYTICAL MODEL

t = np.arange(N) / Fs
x = A * np.sin(2 * np.pi * f * t)

add_ref = 2 * x               # 4 sin(1000t)
sub_ref = np.zeros_like(x)    # 0
mul_ref = x * x               # 4 sin^2(1000t)


# -------- ADD --------
plt.figure()
plt.plot(t, add_ref, label="ADD (golden)", linewidth=2)
plt.plot(t, add_out, "--", label="ADD (RTL)", linewidth=1)
plt.title("ADD: 4 sin(1000t)")
plt.xlabel("Time (s)")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)

# -------- SUB --------
plt.figure()
plt.plot(t, sub_ref, label="SUB (golden)", linewidth=2)
plt.plot(t, sub_out, "--", label="SUB (RTL)", linewidth=1)
plt.title("SUB: Zero Output")
plt.xlabel("Time (s)")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)

# -------- MUL --------
plt.figure()
plt.plot(t, mul_ref, label="MUL (golden)", linewidth=2)
plt.plot(t, mul_out, "--", label="MUL (RTL)", linewidth=1)
plt.title("MUL: 4 sin²(1000t)")
plt.xlabel("Time (s)")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)



plt.show()
