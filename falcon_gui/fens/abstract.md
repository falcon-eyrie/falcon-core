**Title:** Falcon Core 3.0: A Modular Platform for Real-Time Closed-Loop Neuroscience Experiments

**Authors:** TODO

**Abstract Category:** Scientific Research Abstract

**Abstract Topic:** Methods and Tools for Neuroscience Research, Neural Circuits and Systems

**Body:**  

We present Falcon Core 3.0, an updated modular framework for real-time closed-loop neuroscience experiments. Falcon uses a processing graph architecture, where each node (“processor”) performs tasks such as reading digital signals from neural acquisition hardware, filtering signals, extracting features, implementing control algorithms, and delivering outputs to stimulation devices or external systems. Processors communicate via typed ports, and slow-changing variables can be shared through a refined state mechanism, supporting complex closed-loop paradigms. Major updates in version 3.0 include a new graphical user interface (Falcon Workbench) for designing, configuring, and monitoring processing graphs through an intuitive drag-and-drop interface, facilitating rapid prototyping without extensive programming expertise. Processors are now fully modular, allowing independent addition, removal, or updating of components, enabling laboratories to tailor the system to specific experimental needs and share modules across projects. A redesigned data model ensures consistent interpretation of neural signals, derived features, and control outputs, while high-performance data encoding using FlexBuffers supports low-latency real-time streaming. The state-sharing system has been refined to improve feedback-driven control, and experimenter-oriented documentation provides detailed descriptions of available processors, configuration options, and example workflows. Additional improvements include enhanced error handling, performance optimization, and expanded hardware compatibility. Falcon Core 3.0 thus provides a flexible, extensible platform for neuroscience experiments requiring precise, low-latency closed-loop control, enabling reproducible and scalable experimental designs across diverse research paradigms.
