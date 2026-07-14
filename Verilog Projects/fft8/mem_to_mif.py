import os

# Output directory
out_dir = r"C:\Users\rajes\VLSI\fpga_lab\quartus_projects\fft8_wrapper"

def mem_to_mif(mem_file, mif_file, width=8):
    # Read data
    with open(mem_file, 'r') as f:
        lines = f.readlines()

    data = []
    for line in lines:
        line = line.strip()
        if line == "":
            continue
        val = int(line)

        # Convert negative to 2's complement
        if val < 0:
            val = (1 << width) + val

        data.append(val)

    depth = len(data)

    # Full output path
    mif_path = os.path.join(out_dir, mif_file)

    with open(mif_path, 'w') as f:
        f.write(f"WIDTH={width};\n")
        f.write(f"DEPTH={depth};\n\n")
        f.write("ADDRESS_RADIX=UNS;\n")
        f.write("DATA_RADIX=UNS;\n\n")
        f.write("CONTENT BEGIN\n")

        for addr, val in enumerate(data):
            f.write(f"{addr} : {val};\n")

        f.write("END;\n")

    print(f"Generated: {mif_path}")


# Input files (adjust path if needed)
mem_to_mif("input_real.mem", "xr.mif", width=8)
mem_to_mif("input_imag.mem", "xi.mif", width=8)