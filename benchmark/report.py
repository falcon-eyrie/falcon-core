import numpy as np

def format_time_ns(ns: int, width: int = 10) -> str:
    """Format ns to human-readable string with numeric alignment."""
    if ns < 1_000:
        value = ns
        unit = "ns"
    elif ns < 1_000_000:
        value = ns / 1_000
        unit = "µs"
    elif ns < 1_000_000_000:
        value = ns / 1_000_000
        unit = "ms"
    elif ns < 60_000_000_000:
        value = ns / 1_000_000_000
        unit = "s"
    else:
        value = ns / 60_000_000_000
        unit = "min"

    # Pad the numeric part, then append unit
    return f"{value:>{width}.3f} {unit}"

def generate_benchmark_report(path: str) -> str:
    data = np.fromfile(path, dtype='<i8')  # signed 64-bit little-endian
    
    if(len(data) == 0):
        return f"{path} file is empty!"
    
    if len(data) % 2 != 0:
        raise ValueError("File size is not a multiple of 16 bytes!")


    data = data.reshape(-1, 2)
    enter_times = data[:, 0].astype(np.int64)
    exit_times = data[:, 1].astype(np.int64)

    # Convert absolute timestamps to deltas
    processing_times = exit_times - enter_times

    total_time = data[-1, 1] - data[0, 0]
    num_samples = processing_times.size
    percentiles = np.percentile(processing_times, [50, 90, 99.9])
    p50, p90, p99_9 = percentiles
    min = processing_times.min()
    max = processing_times.max()
    mean = processing_times.mean()
    

    report = (
        f"Benchmark Report\n"
        f"{'-'*50}\n"
        f"Benchmarked samples: {num_samples:,}\n"
        f"Time  :{format_time_ns(int(total_time))}\n" 
        f"p50   :{format_time_ns(int(p50))}\n"
        f"p90   :{format_time_ns(int(p90))}\n"
        f"p99.9 :{format_time_ns(int(p99_9))}\n"
        f"Min   :{format_time_ns(int(min))}\n"
        f"Max   :{format_time_ns(int(max))}\n"
        f"Mean  :{format_time_ns(int(mean))}\n"
        f"{'-'*50}\n"
    )
    return report


if __name__ == "__main__":
    # path = input("Enter the path to the benchmark binary file: ").strip()
    path = "/home/device/dev/falcon-core/build/debug/falcon_env/_last_run/bench/latency_benchmark_data.bin"
    report = generate_benchmark_report(path)
    print(report)
