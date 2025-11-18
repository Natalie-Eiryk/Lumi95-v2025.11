# Lumi286 Custom Instruction Set: π/e Symbolic Codon Compression

This file defines the custom instruction set for symbolic codon compression and decompression using the π/e logic embedded within the Lumi286 architecture.

---

## 🧬 Instruction Set Overview

| Mnemonic | Full Name             | Purpose                                 |
|----------|-----------------------|-----------------------------------------|
| `LHC`    | L-Helix Compress      | Compress symbolic byte using π/e model |
| `LHD`    | L-Helix Decompress    | Decompress byte using π/e and offset   |

---

## 🧾 Syntax Definitions

### **LHC — Compress**
```assembly
LHC R_dest, [Mem_src], TwistOffset
```
| Field         | Description                              |
|---------------|------------------------------------------|
| `R_dest`      | Target register to store compressed byte |
| `[Mem_src]`   | Memory address of the byte to compress   |
| `TwistOffset` | Integer offset for e-digit twist         |

### **LHD — Decompress**
```assembly
LHD [Mem_dest], R_src, TwistOffset
```
| Field         | Description                               |
|---------------|-------------------------------------------|
| `[Mem_dest]`  | Where to write the decompressed byte      |
| `R_src`       | Register holding compressed byte          |
| `TwistOffset` | Same offset used in compression           |

---

## 🧱 16-bit Instruction Format

| Bits    | Field        | Description                       |
|---------|--------------|-----------------------------------|
| 15–12   | Opcode       | `0001` = LHC, `0010` = LHD         |
| 11–8    | R_dest/src   | 4-bit register address             |
| 7–4     | Mem_reg      | 4-bit memory index (indirect)     |
| 3–0     | TwistOffset  | 4-bit twist value (0–15 allowed)  |

---

## 💡 Microcoded Logic

### **LHC Cycle**
1. Fetch Bᵢ from `[Mem_src]`
2. Fetch πᵢ and eᵢ₊ₒ from π-ROM and e-ROM
3. Compute `Cᵢ = (Bᵢ + πᵢ + eᵢ₊ₒ) mod 256`
4. Store `Cᵢ → R_dest`

### **LHD Cycle**
1. Load `Cᵢ` from `R_src`
2. Fetch πᵢ and eᵢ₊ₒ from π-ROM and e-ROM
3. Compute `Bᵢ = (Cᵢ - πᵢ - eᵢ₊ₒ) mod 256`
4. Write `Bᵢ → [Mem_dest]`

---

## 🔐 Example Usage
```assembly
LHC R2, [0x3F], 3    ; Compress byte at memory 0x3F with offset 3 → R2
LHD [0x41], R2, 3    ; Decompress R2 with same offset → memory 0x41
```

---

## Notes
- All π and e digits are read from embedded ROM arrays (1024 digits each).
- `TwistOffset` must be consistent between compression and decompression.
- Compression is reversible as long as ROM digits remain aligned.

---

**Status:** Canonical – assumed correct without FPGA verification. Nature is right.

**Next Steps:** Integrate into BIOS and pipeline microcode.