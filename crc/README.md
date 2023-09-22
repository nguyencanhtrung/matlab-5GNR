## Algorithm

### `crcgenerator` - MATLAB Toolbox CRC Generator

Each LUT (Look-Up Table) is a matrix of dimensions 256x24bits (CRC24A, CRC24B, CRC24C) or 256x16bits (CRC16). Each LUT stores 256 checksums (results) of CRC computation for 256 different inputs.

#### Inputs for LUTs

- **LUT1**: Inputs range from `[0 .. 255]`
- **LUT2**: Inputs range from `[0 .. 255] << 8`
- **LUT3**: Inputs range from `[0 .. 255] << 16`
- ...
- **LUT16**: Inputs range from `[0 .. 255] << 120`

The higher the index `i` of `LUT(:,:,i)`, the higher the order of the polynomial used for CRC.

---

### Explanation

#### Input Stream

Consider an input stream \( A \) which is a 128-bit vector:  
\[ A = a_0.a_1.a_2...a_{127} \]  
where \( a_0 \) is the first bit.

This can be considered as a Polynomial \( P \):  
\[ P = a_0 \times x^{127} + a_1 \times x^{126} + \ldots + a_{127} \]

#### Compute CRC

The CRC of \( A \) is the CRC of \( P \):  
\[ \text{CRC}(A) = \text{CRC}(P) \]

And,  
\[ \text{CRC}(P) = \text{CRC}(a_0 \times x^{127} + \ldots + a_7 \times x^{120}) + \ldots + \text{CRC}(a_{120} \times x^7 + \ldots + a_{127}) \]

Where:  
- \(\text{CRC}(a_{120} \times x^7 + \ldots + a_{127}) = \text{LUT1}(a_{120}..a_{127})\)
- ...
- \(\text{CRC}(a_0 \times x^{127} + \ldots + a_7 \times x^{120}) = \text{LUT16}(a_0..a_7)\)

Therefore,  
\[ \text{CRC}(P) = \text{LUT16}(a_0..a_7) + \text{LUT15}(a_8..a_{15}) + \ldots + \text{LUT1}(a_{120}..a_{127}) \]

---

### Codeword and LUT Index

| Codeword (input) | LUT index |
|------------------|-----------|
| \( << 15 \times 8 \) | 16 |
| \( << 15 \times 8 \) | 15 |
| ... | ... |
| \( << 0 \) | 1 |

#### Notes

- **Bit Order of Input for LUT**: The first bit is the MSbit.
  - **LUT16**: \( a_0..a_7 \) (where \( a_0 \) is the first bit)
  - **LUT15**: \( a_8..a_{15} \) (where \( a_8 \) is the first bit)
  - ...
  - **LUT1**: \( a_{120}..a_{127} \) (where \( a_{120} \) is the first bit)

- **Bit Order of Output (Checksum/Result) of CRC Computation**: The first bit is the MSbit.
  - \( \text{res} = \text{crcgenerator}(a_0..a_7) = c_0..c_{24} \) (where \( c_0 \) is the first bit)
