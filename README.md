![Falcon version](https://img.shields.io/badge/Falcon-v2.0.0--rc1-green) ![License](https://img.shields.io/badge/License-GPLv3-blue)
# Falcon

Falcon is a modular and extensible software framework for soft real-time signal processing, originally designed for short-latency closed-loop neural applications.

# ⚡ Quick installation

To install Falcon on Linux, simply run the following command in your terminal:

```bash
wget -qO- https://raw.githubusercontent.com/falcon-eyrie/falcon-core/refs/heads/develop/install.sh | bash
```

# Advanced development and debugging

The Falcon backend is developed in C++. New processors and data types can be added as modular extensions. To compile the codebase locally, follow the build steps defined in the automated CI pipeline located at `.github/workflows/build_backend.yml`.
The build process is based on CMake and supports both Clang and GCC compilers. For development environments, LLVM tools are required to support linting and formatting. By default, project contains settings and launch configurations for VSCode, but you can easily adapt it to other IDEs.

# Core architecture and extensions

Falcon operates on a graph-based architecture where users compose processors into a directed graph to accomplish specific signal processing tasks.
While the core framework manages execution, the processors themselves are maintained in separate repositories as extensions. By default, the build process includes the `falcon-fklab-extensions`, as specified in the extensions.txt configuration. You can customize Falcon by integrating your own specialized extensions to suit your specific research or engineering needs.

# Use cases

Falcon is engineered for high-performance neural data processing where timing is critical. Current applications include:

*   **Ripple Detection:** Real-time identification of hippocampal ripple oscillations.
*   **Neural Decoding:** Online detection and decoding of hippocampal replay patterns.
*   **Closed-Loop Experiments:** Low-latency feedback loops for electrophysiology.

For comprehensive guides and API references, please visit the [Official Documentation](https://falcon-core.readthedocs.io). 

> We are currently working on expanding the documentation to include more detailed examples and tutorials.


# Contributing

If you encounter installation issues or runtime bugs, please open an issue in the repository. When reporting a bug, it is highly recommended to include:
A clear description of the problem or requested feature.
The specific graph definition used.
Relevant configuration files.

# Developing new extensions
To develop a new extension, you may open an issue here for architectural guidance. Generally, maintainers recommend hosting your extension in a standalone repository and then submitting a Pull Request to Falcon to include your documentation link in the main project registry.
