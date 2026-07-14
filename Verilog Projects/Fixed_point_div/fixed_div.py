import numpy as np

FRAC = 30
SCALE = 1 << FRAC

def float_to_fixed(x):
    return int(round(x * SCALE))

def fixed_to_float(x):
    return x / SCALE

def fixed_mul(a, b):
    return (a * b) >> FRAC

def reciprocal_newton(D_float, iterations=5):
    # Normalize D to [0.5,1)
    shift = 0
    d = D_float
    while d >= 1.0:
        d /= 2
        shift += 1
    while d < 0.5:
        d *= 2
        shift -= 1

    # Smart initial guess
    x0 = (48/17) - (32/17) * d

    x = float_to_fixed(x0)
    d_fixed = float_to_fixed(d)

    TWO = float_to_fixed(2.0)

    for _ in range(iterations):
        temp = fixed_mul(d_fixed, x)
        x = fixed_mul(x, (TWO - temp))

    # Adjust scaling
    if shift > 0:
        x >>= shift
    else:
        x <<= (-shift)

    return x

def fixed_divide(A, D):
    recip = reciprocal_newton(D)
    return fixed_mul(float_to_fixed(A), recip)


# Test Array (Prime denominators)

fractions = [(15,23),(10,79),(7,97),(25,53),(9,71)]

print("Python Reference Results:\n")

for A,D in fractions:
    result_fixed = fixed_divide(A, D)
    result_float = fixed_to_float(result_fixed)

    print(f"{A}/{D}")
    print("Fixed  :", result_float)
    print("True   :", A/D)
    print("Error  :", abs(result_float - A/D))
    print()
