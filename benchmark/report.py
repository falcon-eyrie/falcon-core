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
    else:
        value = ns / 1_000_000_000
        unit = "s"

    # Pad the numeric part, then append unit
    return f"{value:>{width}.3f} {unit}"

def generate_benchmark_report(path: str) -> str:
    data = np.fromfile(path, dtype='<i8')  # signed 64-bit little-endian
    if len(data) % 2 != 0:
        raise ValueError("File size is not a multiple of 16 bytes!")

    data = data.reshape(-1, 2)
    enter_times = data[:, 0].astype(np.int64)
    exit_times = data[:, 1].astype(np.int64)

    # Convert absolute timestamps to deltas
    processing_times = exit_times - enter_times

    total_time = data[-1, 1] - data[0, 0]
    num_samples = processing_times.size
    average_time = np.mean(processing_times)
    min_time = np.min(processing_times)
    max_time = np.max(processing_times)
    std_dev = np.std(processing_times, dtype=np.float64)

    report = (
        f"Benchmark Report\n"
        f"{'-'*50}\n"
        f"Total Samples Processed : {num_samples:,}\n"
        f"Total Processing Time   : {format_time_ns(int(total_time))}\n"
        f"Average Latency         : {format_time_ns(int(average_time))}\n"
        f"Minimum Latency         : {format_time_ns(int(min_time))}\n"
        f"Maximum Latency         : {format_time_ns(int(max_time))}\n"
        f"Standard Deviation      : {format_time_ns(int(std_dev))}\n"
        f"{'-'*50}\n"
    )
    return report


if __name__ == "__main__":
    # path = input("Enter the path to the benchmark binary file: ").strip()
    path = "/home/device/dev/falcon-core/build/debug/_last_run/bench/latency_benchmark_data.bin"
    report = generate_benchmark_report(path)
    print(report)
