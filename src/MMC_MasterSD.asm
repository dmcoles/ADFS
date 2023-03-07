
mmc%=&fc80
mmcstat%=&fc81
acccon%=&fe34

.setIFJ
    PHA
    LDA        acccon%
    STA        &90
    ORA        #&20
    STA        acccon%
    PLA
    RTS

.restoreIFJ
    PHP
    PHA
    LDA        &0090
    STA        acccon%
    PLA
    PLP
    RTS

.MMC_GetByte
.UP_ReadByteX
    JSR        setIFJ
    LDA        #0
    STA        mmcstat%
    LDA        #&ff
    STA        mmc%
    JSR        wait
    LDA        mmc%
    JSR        restoreIFJ
    RTS

.wait
    LDA        mmcstat%
    CMP        #0
    BNE        wait
    RTS

.sendbyte
    JSR        setIFJ
    STA        mmc%
    JSR        wait
    JSR        restoreIFJ
    LDA        #0
    RTS

.sendbyte2

    STA        mmc%
    JSR        wait
    LDA        #0
    RTS

.MMC_DEVICE_RESET
    RTS

.MMC_16Clocks
    LDY        #2
.MMC_SlowClocks
.MMC_Clocks
    JSR        MMC_GetByte
    DEY
    BNE        MMC_Clocks
    RTS

.MMC_DoCommand

    JSR        setIFJ
    LDX        #0
    LDY        #8
.dcmd1
    LDA        cmdseq%,X
    STA        mmc%
    JSR        wait
    NOP
    NOP
    INX
    DEY
    BNE        dcmd1
    LDA        #&ff
.wR1mm
    STA        mmc%
    JSR        wait
    LDA        mmc%
    BPL        dcmdex
    DEY
    BNE        wR1mm
    CMP        #0
.dcmdex
    JSR        restoreIFJ
    RTS

.MMC_WaitForData
    JSR        setIFJ
    LDX        #&ff
.wl1
    STX        mmc%
    JSR        wait
    LDA        mmc%
    CMP        #&fe
    BNE        wl1
    JSR        restoreIFJ
    RTS

    
.MMC_Read256
    LDX        #0

.MMC_ReadX
    LDY        #0
    BIT        &CD
    BVS        readtube
    JSR        setIFJ
    LDA        #1
    STA        mmcstat%
.readloop
    LDA        #&ff
    STA        mmc%
    JSR        wait
    NOP
    LDA        mmc%
    STA        (datptr%),Y

    ;skip alternate byte
    LDA        #&ff
    STA        mmc%
    JSR        wait
    NOP

    INY
    DEX
    BNE        readloop
    LDA        #0
    STA        mmcstat%
    JSR        restoreIFJ
    RTS
.readtube

.tubeloop
    TXA
    PHA
    JSR        MMC_GetByte
    STA        TUBE_R3_DATA
    JSR        MMC_GetByte
    PLA
    TAX
    INY
    DEX
    BNE        tubeloop
    RTS

.MMC_SendingData
    LDY        #2
    JSR        MMC_Clocks
    LDA        #&fe
    JMP        sendbyte

.MMC_EndWrite
    JSR        MMC_16Clocks
.LAB_a6ce
    JSR        MMC_GetByte
    TAY
    AND        #&1f
    CMP        #&1f
    BEQ        LAB_a6ce
    CMP        #5
    BNE        error
.LAB_a6dc
    JSR        MMC_GetByte
    CMP        #&ff
    BNE        LAB_a6dc
    RTS
.error
    JMP errWrite

.MMC_Write256
    JSR        setIFJ
    LDY        #0    
    LDA        #1
    STA        mmcstat%
    BIT        &CD
    BVS        writetube

.writeloop
    LDA        (datptr%),Y
    JSR        sendbyte2

    LDA #0
    JSR        sendbyte2

    INY
    BNE        writeloop
    JSR        restoreIFJ
    RTS
.writetube
    LDA        TUBE_R3_DATA
    JSR        sendbyte2

    LDA        #0
    JSR        sendbyte2

    INY
    BNE        writetube
    LDA        #0
    STA        mmcstat%
    JSR        restoreIFJ
    RTS

.MMC_Read512
    LDX        #0

    LDY        #0
    JSR        setIFJ
    LDA        #1
    STA        mmcstat%
.LAB_a687_1
    LDA        #&ff
    STA        mmc%
    JSR        wait
    NOP
    LDA        mmc%
    STA        (datptr%),Y
    
    INY
    DEX
    BNE        LAB_a687_1

    INC datptr%+1

    LDA        #1
    STA        mmcstat%
.LAB_a687_2
    LDA        #&ff
    STA        mmc%
    JSR        wait
    NOP
    LDA        mmc%
    STA        (datptr%),Y

    INY
    DEX
    BNE        LAB_a687_2

    LDA        #0
    STA        mmcstat%
    JSR        restoreIFJ
    RTS

