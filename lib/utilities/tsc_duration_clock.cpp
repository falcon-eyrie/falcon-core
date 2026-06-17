#include <chrono>
#include <cstdint>
#include <fstream>
#include <string>

class TscDurationClock {
   public:
    TscDurationClock() = delete;

    static inline uint64_t tsc() noexcept { return tsc_fn_ptr(); }

    static inline std::chrono::nanoseconds duration_since_tsc(uint64_t start) noexcept {
        return duration_fn_ptr(start);
    }

    static void init() noexcept {
        if (!check_cpu_flag("constant_tsc") || !check_cpu_flag("nonstop_tsc") ||
            !check_cpu_flag("rdtscp")) {
            return;
        }

        using namespace std::chrono;
        auto start_time = steady_clock::now();
        uint64_t start_tsc = hardware_tsc();
        while (duration_cast<milliseconds>(steady_clock::now() - start_time).count() < 100) {
        }
        auto end_time = steady_clock::now();
        uint64_t end_tsc = hardware_bench_end();

        duration<double> elapsed_seconds = end_time - start_time;
        tsc_frequency = static_cast<double>(end_tsc - start_tsc) / elapsed_seconds.count();

        tsc_fn_ptr = &hardware_clock_tsc;
        duration_fn_ptr = &hardware_duration;
    }

   private:
    static inline uint64_t hardware_tsc() noexcept {
        uint32_t lo, hi;
        asm volatile(
            "lfence\n\t"
            "rdtsc"
            : "=a"(lo), "=d"(hi)::"memory");
        return (static_cast<uint64_t>(hi) << 32) | lo;
    }

    static inline uint64_t hardware_bench_end() noexcept {
        uint32_t lo, hi;
        asm volatile(
            "rdtscp\n\t"
            "lfence"
            : "=a"(lo), "=d"(hi)::"rcx", "memory");
        return (static_cast<uint64_t>(hi) << 32) | lo;
    }

    static uint64_t hardware_clock_tsc() noexcept { return hardware_tsc(); }

    static std::chrono::nanoseconds hardware_duration(uint64_t start) noexcept {
        uint64_t end = hardware_bench_end();
        if (end <= start) return std::chrono::nanoseconds(0);
        return std::chrono::nanoseconds{
            static_cast<uint64_t>(((end - start) / tsc_frequency) * 1e9)};
    }

    static uint64_t wall_clock_tsc() noexcept {
        return std::chrono::steady_clock::now().time_since_epoch().count();
    }

    static std::chrono::nanoseconds wall_clock_duration(uint64_t start) noexcept {
        auto end = std::chrono::steady_clock::now().time_since_epoch().count();
        if (end <= static_cast<int64_t>(start)) return std::chrono::nanoseconds(0);
        return std::chrono::nanoseconds{end - static_cast<int64_t>(start)};
    }

    static bool check_cpu_flag(const std::string& flag) noexcept {
        std::ifstream file("/proc/cpuinfo");
        std::string line;
        while (std::getline(file, line)) {
            if (line.rfind("flags", 0) == 0 && line.find(flag) != std::string::npos) return true;
        }
        return false;
    }

    typedef uint64_t (*TscFn)();
    typedef std::chrono::nanoseconds (*DurationFn)(uint64_t);

    static inline TscFn tsc_fn_ptr = &wall_clock_tsc;
    static inline DurationFn duration_fn_ptr = &wall_clock_duration;
    static inline double tsc_frequency = 1.0;
};
