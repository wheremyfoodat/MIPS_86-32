$ra: equ 31 * 4 ; alias for return address register (r31)

struc cop0_t
    pad1: resd 3
    bpc: resd 1
    pad2: resd 1
    bda: resd 1
    jumpdest: resd 1
    dcic: resd 1
    badVaddr: resd 1
    bdam: resd 1
    pad3: resd 1
    bpcm: resd 1
    sr: resd 1
    cause: resd 1
    epc: resd 1
    prid: resd 1
    pad4: resd 48
endstruc

struc MIPS
    GPRs: resd 32
    pc: resd 1
    nextInstruction: resd 1 ; used to simulate branch delay slots
    cop0: resb cop0_t_size
endstruc
