struc MIPS
    GPRs: resd 32
    pc: resd 1
    nextInstruction: resd 1 ; used to simulate branch delay slots
endstruc