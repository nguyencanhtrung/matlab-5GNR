# CRC LUT-based algorithm

## Overview

Cyclic Redundancy Check(CRC) is an error-detection mechanism widely used in communication systems. The CRC algorithm behaves like a hash function, specifically, it calculates an unique identifier(checksum) for original data, and then uses this identifier to determine whether the data has changed after transmission. For a specific system, CRC can be implemented either through software codes or hardware circuit.

There are many implementations of the same algorithm including [BSV](https://github.com/datenlord/blue-crc/tree/main), [Verilog](https://bitbucket.org/spandeygit/crc32_verilog). This repo provides a bit-accurate Matlab model of CRC implementation which can then translate to FPGA with traditional RTL or HLS design flow. The RTL and HLS implementation belong to a closed source project and are not presented here.

## Algorithm Theory

The idea of our parallel and high-performance CRC implementation comes from the [paper](https://ieeexplore.ieee.org/abstract/document/5501903). And main contributions of this repo compared to the existing work include:

- Refine the logic implementation to improve the working frequency.
- Support arbitrary length of input data

The calculation of CRC is basically a division operation on two polynomials based on modulo-2 arithmetic and the remainder of this division is just the checksum we wanted. Consider a m-bit original data $b_{m-1}b_{m-2}b_{m-3}...b_{1}b_{0}$ can be represented as the polynomial $M(x)$:

$$
M(x)=b_{m-1}x^{m-1}+b_{m-2}x^{m-2}+...+b_{1}x+b_{0}
$$

And a predetermined (n+1)-bit generator polynomial can be represented as $G(x)$:

$$
G(x)=b_{n}x^{n}+b_{n-1}x^{n-1}+...+b_{1}x^{1}+b_{0}
$$

And the CRC is derived following the equation below:

$$
CRC[M(x)]=remainder(\frac{M(x)x^{n}}{G(x)})
$$

More detailed introduction of CRC can be accessed via this [link](https://en.wikipedia.org/wiki/Cyclic_redundancy_check). Based on the characteristics of modulo-2 arithmetic, CRC calculation can be easily implemented using a LFSR register. This circuit is one of the most classic hardware implementations of CRC algorithm, which only needs few hardware resources and can reach high working frequency. However, the LFSR implementation takes in only 1-bit per cycle, which provides a poor throughput. In order to get a parallel and high-performance CRC design, the serial implementation demonstrated above should be rearranged into a parallel architecture. The following two theorems is used to achieve parallelism in CRC computation.

- Theorem 1:

$$
CRC[A(x)]=CRC(\sum_{i=1}^{n}A_{i})=\sum_{i=1}^{n}CRC(A_{i})
$$

- Theorem 2:

$$
CRC[A(x)x^k] = CRC[CRC[A(x)]x^k]
$$

Theorem 1 indicates that original data of any length can be split into multiple pieces and CRC checksum of each piece can be calculated in parallel and then add up to get the CRC result of complete data. In our designed, the length of one piece is 8-bit and it’s assumed that the length of original data is multiples of bytes. For example, a N-bit original data, represented as polynomial $A(x)$, can be divided into n bytes, i.e. $N=8\times n$, each byte of original data is represented as the polynomial $A_{i}(x)$, and $A(x)$ can be expressed as:

$$
A(x)=\sum_{i=0}^{n-1}A_i(x)\ x^{8i}
$$

And the CRC of A(x) is derived as below:

$$
CRC(A(x))=CRC[A_{n-1}(x)x^{8(n-1)}]+CRC[A_{n-2}(x)x^{8(n-2)}]+... +CRC[A_{1}(x)x^8]+ CRC[A_{0}(x)]
$$

To calculate the CRC of each 8-bit piece, we don't have to implement real circuit instead it' more efficient to precompute the CRC results of all possible values of 8-bit data and store them in hardware lookup table. When we need to compute CRC, we can just search the precomputed table using the input data as index.

However, the parallel scheme proposed above is still impractical for hardware implementation. For real circuit design, the width of input data bus is usually fixed and original data is split into multiple frames and sent into the component serially. So the hardware needs to compute the CRC result in an accumulative manner. In each cycle, the circuit calculates CRC checksum of input frame based on Theorem 1, and then adds it to the intermediate CRC result of former frames. 

The addition of CRC result of current input frame and the intermediate CRC result is based on Theorem 2. Assume that original data is transmitted in big-endian byte order, the width of the input bus is 256-bit, $A(x)$ represents data received in this cycle and $A'(x)$ represents data received in former cycles. And we need to add $CRC[A(x)]$ to the intermediate result $CRC[A'(x)]$ to get $CRC[A'(x)x^{256} + A(x)]$. Based on Theorem 2, we can derive the equation below:
$$CRC[A'(x)x^{256}+A(x)]=CRC[A'(x)x^{256}]+CRC[A(x)]=CRC[CRC[A'(x)]\times x^{256}]+CRC[A(x)]$$
The equation shows that we need to shift the intermediate CRC result left, perform CRC calculation on it again and then add it with the CRC result of current frame. And the CRC calculation of the intermediate checksum can also be implemented using hardware lookup tables. For accumulation, there's one more case to consider, that is, the width of raw data may not just be multiples of 256-bit, so you cannot directly use the above formula for accumulation when processing the last input frame. Instead we need to dynamically calculate the width of valid data in the last frame of original data. Assume that the valid width of the last frame data is m, the accumulation is done following the equation below:
$$CRC[A'(x)x^m+A(x)]=CRC[CRC[A'(x)]\times x^m]+CRC[A(x)]$$


## Look-Up-Table generation `get_lut.m`

This section uses `crcgenerator` which is MATLAB toolbox CRC generator to compute CRC checksum of `256 inputs` (codeword) in range `[0, 255]`. The 256 results are stored in one LUT.

There are 16 LUTs (LUT1, LUT2, ... LUT16).

### Inputs for LUTs

- **LUT1**: Inputs range from `[0 .. 255]`
- **LUT2**: Inputs range from `[0 .. 255] << 8`
- **LUT3**: Inputs range from `[0 .. 255] << 16`
- ...
- **LUT16**: Inputs range from `[0 .. 255] << 120`

> **Question**: Why do we need to compute CRC of such input format?

---

### Detailed Explanation

#### Input Stream

Consider an input stream `A` as a 128-bit vector:  
`A = a0.a1.a2...a127`  
where `a0` is the first bit.

This can be represented as a Polynomial `P`:  
`P = a0 * x^127 + a1 * x^126 + ... + a127`

#### CRC Computation

The CRC of `A` is the CRC of `P`:  
`CRC(A) = CRC(P)`

And,

`CRC(P) = CRC(a0 * x^127 + ... + a7 * x^120 + ... + a120 * x^7 + ... + a127)`

`CRC(P) = CRC(a0 * x^127 + ... + a7 * x^120) + ... + CRC(a120 * x^7 + ... + a127)`

Where:  
- `CRC(a120 * x^7 + ... + a127) = CRC( a120..a127 ) =LUT1(a120..a127)`
- ...
- `CRC(a0 * x^127 + ... + a7 * x^120) = CRC( a0..a7 << 120 ) = LUT16(a0..a7)`

Therefore,  
`CRC(P) = LUT16(a0..a7) + LUT15(a8..a15) + ... + LUT1(a120..a127)`

---

### Codeword and LUT Index

| Codeword (input) | LUT index |
|------------------|-----------|
| `[0..255]<< (15 * 8)`    | 16        |
| `[0..255]<< (14 * 8)`    | 15        |
| ...                      | ...       |
| `[0..255]<< 0`           | 1         |

#### Notes

- **Bit Order of Input for LUT**: The first bit is the MSbit.
  - **LUT16**: `a0..a7` (where `a0` is the first bit)
  - **LUT15**: `a8..a15` (where `a8` is the first bit)
  - ...
  - **LUT1**: `a120..a127` (where `a120` is the first bit)

- **Bit Order of Output (Checksum/Result) of CRC Computation**: The first bit is the MSbit.
  - `res = crcgenerator(a0..a7) = c0..c24` (where `c0` is the first bit)

## User guide

| STT  | Files              | Description                                             |
|:---  | :---               | :---                                                   |
|   1  | compute_crc.m      | LUT-based implementation. Compute CRC(A+B) = CRC(A) + CRC(B)  |
|   2  | compute_crc_fpga.m | LUT-based implementation. Compute CRC(A+B), by first compute A+B = C, then compute CRC(C)   |
|   3  | get_lut.m          | Compute pre-defined LUTs  |
|   4  | gen_table.m        | Writing pre-defined LUTs to file for FPGA implementation   |
|   5  | gen_hdl_in.m       | Generate simple golden I/O to test the FPGA core  |
|   6  | main.m             | Main program  |