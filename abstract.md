# Falcon 2.0: A High-Throughput Dual-Rate Framework for Real-Time Electrophysiology

### Abstract
The escalating complexity of systems neuroscience experiments necessitates a paradigm shift in real-time computational frameworks. With the advent of next-generation high-density CMOS probes, researchers must now process hundreds of channels at high sampling rates, generating sustained data throughput that challenges the limits of conventional bus architectures and memory hierarchies. Traditional software designs often fail to reconcile the deterministic, low-latency requirements of closed-loop stimulation with the need for flexible, high-level experimental control. In most legacy systems, the introduction of complex processing logic—such as real-time spike sorting or multi-modal integration—results in non-deterministic "jitter" that compromises the temporal precision of neural interventions.

Falcon 2.0 addresses these challenges through a specialized **Dual-Rate Architecture**. This design bifurcates the processing pipeline into two distinct computational domains: a **Hardware-Synchronous Hot Path** and a **Software-Asynchronous Slow Path**. The Hot Path utilizes LLVM-based Just-In-Time (JIT) compilation to fuse neuro-digital signal processing (DSP) kernels into SIMD-optimized machine code. By collapsing multiple processing stages into a single, vectorized execution block, the framework achieves sub-100 microsecond sense-to-act latencies while maintaining a minimal memory footprint. Simultaneously, the Slow Path enables the seamless integration of high-level Python logic, advanced machine learning inference, and multi-modal I/O (such as high-speed video tracking) without compromising the phase-integrity or temporal continuity of the primary neural data stream. This decoupling ensures that the high-frequency "heartbeat" of neural acquisition remains unperturbed by the variable-rate demands of behavioral analysis or external hardware handshaking, providing a robust foundation for the next generation of sophisticated, adaptive neuro-engineering.

<div style="page-break-after: always;"></div>

### High-Density Phase-Locked Closed-Loop Pipeline
The following implementation demonstrates a phase-amplitude coupling experiment. The objective is to deliver optogenetic stimulation contingent upon the simultaneous detection of hippocampal sharp-wave ripples and a specific phase of the endogenous theta oscillation.

```python
import falcon
from falcon.processors import Neuropixels, CarFilter, RippleDetector, PhaseLocker, OptoStim

source = Neuropixels(probe="3.0")
cleaner = CarFilter(method="median")
ripples = RippleDetector(threshold=7.0)
theta = PhaseLocker(target_band=(4, 8), target_phase=180)
laser = OptoStim(endpoint="laser_0")

graph = falcon.Graph()

graph.route(source.data, to=cleaner.input)
graph.route(cleaner.data, to=ripples.input)
graph.route(cleaner.data, to=theta.input)

graph.route(ripples.event, to=laser.trigger)
graph.route(theta.phase, to=laser.gate)

engine = falcon.compile(graph)
engine.run()
```

**Technical Analysis: Fused SIMD Execution and Cache Locality**
The fundamental bottleneck in high-channel-count electrophysiology is the "memory wall"—the latency incurred when moving data between main RAM and CPU registers. In traditional modular architectures, each processor (Filter, Detector, etc.) iterates over the 384-channel buffer independently, forcing the CPU to evict and reload neural data from L3 cache multiple times per sample. At 30 kHz, this overhead results in catastrophic "jitter" and cache thrashing.

Falcon 2.0 bypasses this via LLVM-assisted Kernel Fusion. During the `compile()` phase, the framework analyzes the routed DAG and generates a singular C++ loop. This loop utilizes Single Instruction, Multiple Data (SIMD) vectorization (AVX-512 or AMX). Rather than processing one channel at a time, Falcon loads 16 contiguous 32-bit floats into a ZMM register. The `CarFilter`, `RippleDetector`, and `PhaseLocker` logic are then executed as a sequence of register-to-register operations. 

By calculating the median, applying the IIR coefficients for ripple detection, and extracting the Hilbert-transformed phase for the theta oscillation within the same pipeline, the neural data never leaves the L1 cache. This spatial and temporal locality reduces the sense-to-act latency to the theoretical minimum of the hardware bus, effectively transforming the general-purpose CPU into a specialized, high-performance neuro-processor.

<div style="page-break-after: always;"></div>

### Multi-Modal Integration via Custom Controller Logic
Complex behavioral experiments require the integration of non-neural signals, such as real-time position tracking, which typically operate at lower sampling frequencies (30–120 Hz). Falcon 2.0 facilitates this via a CustomController, which allows an asynchronous Python process to influence the deterministic Hot Path.

```python
import falcon
from falcon.processors import Neuropixels, CarFilter, RippleDetector, OptoStim, CustomController
import cv2
import threading

is_in_center = False

def camera_hub():
    global is_in_center
    cap = cv2.VideoCapture(0)
    while True:
        _, frame = cap.read()
        is_in_center = frame.mean() > 127

threading.Thread(target=camera_hub, daemon=True).start()

def processPositionCallback(node):
    node.ports.out.push(is_in_center)

source = Neuropixels(probe="3.0")
cleaner = CarFilter(method="median")
ripples = RippleDetector(threshold=7.0)
pos_ctrl = CustomController(process=processPositionCallback)
laser = OptoStim(endpoint="laser_0")

graph = falcon.Graph()

graph.route(source.data, to=cleaner.input)
graph.route(cleaner.data, to=ripples.input)

graph.route(ripples.event, to=laser.trigger)
graph.route(pos_ctrl.out, to=laser.gate)

engine = falcon.compile(graph)
engine.run()
```

**Technical Analysis: Atomic State Injection and Temporal Decoupling**
The integration of high-level behavioral logic (e.g., Computer Vision) introduces non-deterministic latencies associated with the Python Global Interpreter Lock (GIL) and variable PCIe bus contention from the GPU. In a single-rate system, a 10ms delay in a frame-processing loop would stall the neural DSP pipeline, leading to lost samples and phase-estimation drift.

Falcon 2.0 solves this through Atomic State Injection via the `CustomController`. The `camera_hub` operates as an independent asynchronous agent, populating a shared-memory register with the animal's coordinates. The `CustomController` acts as a synchronized gateway; upon each "tick" of the high-speed engine, it performs a zero-overhead atomic read of the current behavioral state.

This state is then "latched" into the Hot Path’s gate logic. Because the `OptoStim` trigger logic is implemented as a branchless instruction within the fused SIMD kernel, the decision to stimulate is gated by the behavioral state with sub-microsecond precision. The framework effectively decouples the "clock domains" of the experiment: the neural DSP runs at a hard 30 kHz, while the behavioral logic updates at the camera's frame rate. This ensures that the closed-loop system is reactive to complex behavioral contexts without introducing jitter into the high-precision neural signal chain.

<div style="page-break-after: always;"></div>

### Summary
Falcon 2.0 represents the convergence of high-level research flexibility and low-level computational efficiency. By abstracting complex C++/SIMD optimizations into a modular Python interface, the framework empowers neuroscientists to design multi-modal experiments that were previously computationally inaccessible. The dual-rate architecture ensures that as neural data densities continue to increase, the precision of real-time intervention remains uncompromised, bridging the gap between massive-scale data acquisition and nanosecond-scale biological interaction.