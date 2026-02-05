import numpy as np
import matplotlib.pyplot as plt
import os

def format_time_ns(ns: int, width: int = 10) -> str:
    abs_ns = abs(ns)
    if abs_ns < 1_000:
        value, unit = ns, "ns"
    elif abs_ns < 1_000_000:
        value, unit = ns / 1_000, "µs"
    elif abs_ns < 1_000_000_000:
        value, unit = ns / 1_000_000, "ms"
    elif abs_ns < 60_000_000_000:
        value, unit = ns / 1_000_000_000, "s"
    else:
        value, unit = ns / 60_000_000_000, "min"

    return f"{value:>{width}.3f} {unit}"

def generate_plots(path: str, processing_times_ns: np.ndarray):
    processing_times_ms = processing_times_ns / 1_000_000.0
    
    plt.figure(figsize=(12, 10))
    
    plt.subplot(2, 1, 1)
    plt.plot(processing_times_ms, color='#1f77b4', linewidth=0.5)
    plt.title("Latency Timeline", fontsize=14, fontweight='bold')
    plt.ylabel("Latency (ms)")
    plt.xlabel("Sample Index")
    plt.grid(True, alpha=0.3)

    plt.subplot(2, 1, 2)
    plt.hist(processing_times_ms, bins=100, color='#d62728', edgecolor='black', log=True)
    plt.title("Latency Distribution (Log Scale)", fontsize=14, fontweight='bold')
    plt.ylabel("Frequency (Count)")
    plt.xlabel("Latency (ms)")
    plt.grid(True, alpha=0.3)

    plt.tight_layout()
    output_path = os.path.splitext(path)[0] + ".png"
    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"Visualization saved to: {output_path}")

def generate_benchmark_report(path: str) -> str:
    try:
        data = np.fromfile(path, dtype='<i8')
    except FileNotFoundError:
        return f"Error: File {path} not found."
    
    if len(data) == 0:
        return f"{path} file is empty!"
    
    if len(data) % 2 != 0:
        raise ValueError("File size must be a multiple of 16 bytes!")

    data = data.reshape(-1, 2)
    
    processing_times = data[:, 1] - data[:, 0]
    total_duration_ns = data[-1, 1] - data[0, 0]
    
    num_samples = processing_times.size
    p0_5, p50, p99_5 = np.percentile(processing_times, [0.5, 50, 99.5])
    
    min_val = processing_times.min()
    max_val = processing_times.max()
    mean_val = processing_times.mean()
    totalsamples = processing_times.size

    generate_plots(path, processing_times)

    report = (
        f"\nBenchmark Report\n"
        f"{'-'*50}\n"
        f"File Path     : {path}\n"
        f"Samples       : {num_samples:,}\n"
        f"Total Runtime :{format_time_ns(int(total_duration_ns))}\n" 
        f"p50 (Median)  :{format_time_ns(int(p50))}\n"
        f"p0.5         :{format_time_ns(int(p0_5))}\n"
        f"p99.5        :{format_time_ns(int(p99_5))}\n"
        f"Min           :{format_time_ns(int(min_val))}\n"
        f"Max           :{format_time_ns(int(max_val))}\n"
        f"Mean          :{format_time_ns(int(mean_val))}\n"
        f"Index of Max  : {np.argmax(processing_times)}\n"
        f"Total Samples : {totalsamples:,}\n"
        f"{'-'*50}\n"
    )
    return report
 
if __name__ == "__main__":
    if not os.path.exists("./recordings"):
        os.makedirs("./recordings")

    path = "./recordings/i5_4c_86mins.bin"
    # path = "./recordings/i9_8c_74mins.bin"
    
    if os.path.exists(path):
        report = generate_benchmark_report(path)
        print(report)
    else:
        print(f"Waiting for recording file at: {path}")
