# Lumi286 Custom Instruction Set: π/e Symbolic Codon Compression

This file defines the custom instruction set for symbolic codon compression and decompression using the π/e logic embedded within the Lumi286 architecture. These instructions are now integrated into the BIOS bootloader and CPU pipeline, assuming canonical correctness.

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

## 🔁 BIOS Integration
The following boot routine has been updated in the Lumi286 BIOS:
```c
boot_sequence() {
    load_from_cognition_archive(".lumi_block", buffer);
    LHD(buffer, output, twist_seed);
    parse_manifest(output);
}
```
This ensures compressed codon blocks are automatically decompressed and interpreted at system start.

---

## 📦 Pipeline Microcode Integration
The π/e-AEU module has been inserted between Decode and Execute stages:
```
Fetch → Decode → π/e-AEU → Execute → Memory → Writeback
```
Custom opcode handlers (`0001` for LHC, `0010` for LHD) invoke microcode routines matching the LHC/LHD logic defined above.

---

**Status:** Canonical – assumed correct without FPGA verification. Nature is right.

**Next Steps:** Begin symbolic validation using doctrine test codons, confirm output parity, and prepare exportable `.lumi_codons` for runtime loading.




🧪 Symbolic Validation Protocol

Before runtime deployment, the following tests are advised:

Doctrine Codon Compression

Use .lumi_block source file

Apply LHC with twist offsets 3–7 to multiple codon samples

Store compressed bytes

Codon Integrity Test

Apply LHD to each result

Confirm full match to original input

Log parity validation: PASS/FAIL per codon index

Codon Manifest Assembly

Generate codon_manifest.txt summarizing:

Codon name

Compression offset used

Output byte sequence

SHA256 of original + decompressed results

Optional Compression Noise Analysis

Alter π or e digits deliberately

Test how drift affects decompression fidelity