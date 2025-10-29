# RISCV_SoC_CNN_Accelerator_On_FPGA
Official Source code of "An FPGA-Based Secure and Privacy-Aware RISC-V SoC with a CNN Accelerator for Edge AI", published in VLSID 2026

👉 Overview

This project presents a secure and privacy-aware RISC-V-based System-on-Chip (SoC) that integrates a quantized Convolutional Neural Network (CNN) accelerator, on-chip buffers, and dedicated security and privacy modules.The SoC enables low-latency, energy-efficient, and privacy-preserving AI inference on FPGA platforms. It is optimized for edge deployments on datasets like MNIST and CIFAR-10, where both computational efficiency and data confidentiality are critical.


👉 System Architecture

The proposed architecture integrates the following modules:

🧠 RV32IMC RISC-V CPU – A 5-stage pipelined processor with forwarding, hazard detection, and support for custom CNN instructions.

⚙️ CNN Accelerator – Handles quantized inference for MNIST and CIFAR-10 with convolution, normalization, pooling, and fully connected operations.

💾 On-Chip Memory Buffers – BRAM-based storage for weights, biases, and intermediate feature maps to minimize latency and off-chip traffic.

🛡️ Security and Privacy Module – Performs authentication and optional differential noise injection for privacy-preserving inference.

🔗 Wishbone–to–AXI-Lite Interconnect – Connects CPU, CNN engine, and memory in a modular and scalable fashion.

The CPU executes normal RISC-V instructions and one custom CNN instruction that triggers the accelerator through a secure interface. This instruction embeds an image pointer and authentication data, ensuring inference begins only after successful verification.


👉 CNN Accelerator Architecture

A. Processing Elements (PEs)

Two specialized hardware blocks form the computational backbone of the accelerator:

MAC PE (Multiply–Accumulate) → Performs signed 8-bit operations for convolution, batch normalization (scale & shift), and dense layers.

MP PE (Max Pooling) → Performs 2×2 max pooling via lightweight combinational logic.

The pipeline stages are balanced to avoid stalls, and DSP48E1 slices handle multiplications efficiently on FPGA fabric.

B. Dataset-Specific Architectures

🖤 MNIST

8-layer CNN for 28×28 grayscale images.

Layers: Conv → ReLU → MaxPool × 2 → Dense (1600→128→10) → Argmax.

Accuracy: 99.98% on hardware.

🎨 CIFAR-10

Deeper CNN for 32×32 RGB images.

Includes Conv–BN–ReLU6 blocks with same-padding and interleaved pooling.

Accuracy: 99.18% on hardware.

Both networks use Quantization-Aware Training (QAT) to precompute 8-bit weights, biases, and normalization parameters without significant accuracy loss.

C. ⏱️ Pipelined Execution

The accelerator supports both:

Intra-layer parallelism → PEs compute multiple convolution blocks simultaneously.

Inter-layer pipelining → The next layer begins computation as soon as partial outputs are available, reducing overall latency.

Example:
Once a 3×3 output region for all 128 channels is ready, it’s stored in BRAM, triggering the next layer immediately — enabling continuous execution without data dependency violations.

D. 🧮 FSM-Controlled Flow

A centralized Finite State Machine (FSM) orchestrates CNN execution:

Idle – Waits for cnn_start_cmd from CPU.

Input Load – Loads image into local BRAM buffers.

Layer Computation – Sequentially executes convolution, normalization, activation, and pooling.

Flattening & Fully Connected Layers – Converts feature maps to 1D and performs classification.

Output Registering – Applies argmax and signals cnn_done to CPU.

E. 💾 Memory Hierarchy

The CNN accelerator employs a three-tier memory system:

Input Buffers – Store incoming images.

Intermediate Buffers – Hold layer outputs (feature maps).

Weight & Bias Buffers – Store quantized parameters preloaded during initialization.

All operations are performed on-chip using BRAM, avoiding repeated main memory accesses and ensuring minimal latency.

👉 RISC-V Core & Custom Instructions

🧩 Custom CNN Instruction Format

| Field  | Bits | Description                                          |
| :----- | :--- | :--------------------------------------------------- |
| Opcode | 7    | Identifies CNN instruction                           |
| rd     | 5    | Destination register                                 |
| rs1    | 5    | Source register (image pointer)                      |
| funct3 | 3    | Privacy mode + CNN variant flags                     |
| imm12  | 12   | Authentication payload (key + challenge + signature) |

When MSB of funct3 = 1, privacy mode is enabled.

imm12 carries a 4-bit key, a 4-bit runtime challenge, and a 4-bit precomputed signature.

On execution:
Decoder extracts operands and metadata.

Signature verification logic validates authentication.

If verified ✅, CNN accelerator starts via AXI-Lite command.

👉 Security & Privacy Mechanisms

A. Instruction-Level Authentication

Hardware signature verification prevents unauthorized CNN invocations.

FSM operates in three states: IDLE → VERIFY → UNLOCKED/ERROR.

Invalid or tampered instructions are rejected without system crash.

💡 Overhead: ~30 LUTs, 20 FFs (<1% of total resources).

B. Differential Output Privacy

Optional LFSR-based noise injector applies random XOR mask on CNN output.

final_output = predicted_class ⊕ lfsr_noise (when privacy mode enabled).

Mitigates membership inference, model inversion, and side-channel attacks.

💡 Overhead: ~40 LUTs, <1 cycle latency.

⚡ Performance Evaluation

🧾 Inference Latency & Speedup

Speedup achieved through:

PE-level parallelism

Inter-layer pipelining

Early max-pooling execution

🧰 Resource Utilization

DSPs and LUTs scale with PE count → Compute-limited design.
BRAM usage fixed → Efficient memory reuse.

⚡ Power Analysis

BRAM dominates power for MNIST (frequent accesses), while DSPs dominate for CIFAR-10 due to deeper convolutional layers.

🛠️ Implementation Details

FPGA Platform: Xilinx Zynq-7000 (ZedBoard)

HDL: Verilog, SystemVerilog

Toolchain: Xilinx Vivado

Bus Architecture: Wishbone–to–AXI-Lite

CPU Core: Custom RV32IMC with CNN opcode extension

Quantization: 8-bit Quantization-Aware Training (QAT)

Datasets: MNIST & CIFAR-10

Target Applications: Secure Edge AI, Federated Inference, Privacy-Preserving Computing

🧾 Key Highlights

✅ Tight integration of RISC-V CPU, CNN accelerator, and security logic.

🚀 Achieves 10× speedup using hierarchical PE parallelism and pipelining.

🔒 Implements instruction-level authentication and output-level privacy.

💡 Delivers FP32-equivalent accuracy with 8-bit quantization.

🌐 Scalable, energy-efficient SoC for real-time edge AI.

🧪 Results Summary

The proposed SoC demonstrates a secure, high-performance, and privacy-preserving AI architecture built entirely in hardware.

It achieves:
10.68× speedup (MNIST)

10.22× speedup (CIFAR-10)

<2% area overhead for security

<1 cycle latency overhead

⚙️ Ideal for secure, on-device edge inference in real-world applications.
