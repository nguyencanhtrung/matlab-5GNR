# Matlab model for LUT-based CRC computation

## Hierarchy

--------------------------------------------------------------------------------------
| STT  | Files              | Description                                             |
--------------------------------------------------------------------------------------
|   1  | compute_crc.m      | LUT-based implementation. Compute CRC(A+B) = CRC(A) + CRC(B)  |
--------------------------------------------------------------------------------------
|   2  | compute_crc_fpga.m | LUT-based implementation. Compute CRC(A+B), by first compute A+B = C, then compute CRC(C)   |
--------------------------------------------------------------------------------------
|   3  | get_lut.m          | Compute pre-defined LUTs  |
--------------------------------------------------------------------------------------
|   4  | gen_table.m        | Writing pre-defined LUTs to file for FPGA implementation   |
--------------------------------------------------------------------------------------
|   5  | gen_hdl_in.m       | Generate simple golden I/O to test the FPGA core  |
--------------------------------------------------------------------------------------
|   6  | main.m             | Main program  |
--------------------------------------------------------------------------------------

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

