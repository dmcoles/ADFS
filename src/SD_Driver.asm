;; ADFS MMC Card Driver
;; (C) 2015 David Banks
;; Based on code from JGH's IDE Patch

       LDY #5           ;; Get command, CC=Read, CS=Write
       LDA (&B0),Y
       CMP #&09
       AND #&FD         ;; Jump if Read (&08) or Write (&0A)
       EOR #&08
       BEQ CommandOk
       LDA #&27         ;; Return 'unsupported command' otherwise
       BRA CommandExit

.CommandOk

       BIT &CD
       BVC CommandStart ;; Accessing I/O memory
       PHP
       PHX
       LDX #&27         ;; Point to address block
       LDY #&C2
       LDA #0           ;; Set Tube action
       ROL A
       EOR #1
       JSR L8213
       PLX
       PLP

.CommandStart

       PHP
       JSR MMC_BEGIN    ;; Initialize the card, if not already initialized
       PLP
       PHP              ;; Stack the carry flag: C=0 for read, C=1 for write
       BCC SectorRead
       JSR MMC_SetupRW
       JSR setCommandAddress
        
       LDY #9
       LDA (&B0), Y     ;; Read the number of sectors to be transferred
       STA sectorcount%      

.SectorLoop
       JSR DoLEDS

.SectorWrite
       JSR MMC_StartWrite
       JSR MMC_Write256
       JSR MMC_EndWrite

       JSR incCommandAddress


       INC &B3          ;; Increment the MSB of the dataptr

       INC &C228        ;; Increment Tube address
       BNE TubeAddr
       INC &C229
       BNE TubeAddr
       INC &C22A
.TubeAddr

       DEC sectorcount%
       BNE SectorLoop   ;; Loop for all sectors
       PLP

.CommandDone

       JSR ResetLEDS

       ;; TODO add error handling
       LDA #0

.CommandExit
       PHA              ;; Release Tube
       JSR L803A
       PLA
       LDX &B0          ;; Restore registers, set EQ flag
       LDY &B1
       AND #&7F
       RTS


.SectorRead
       LDY #9
       LDA (&B0), Y     ;; Read the number of sectors to be transferred
       STA sectorcount%      

       LDA #read_multiple_block
       JSR MMC_SetCommand
     
       JSR setCommandAddress      
       JSR MMC_DoCommand

.SectorLoop2

       JSR DoLEDS

       JSR MMC_WaitForData

       JSR MMC_Read256
       JSR MMC_16Clocks	;; ignore CRC
       
.notlast
       JSR incCommandAddress

       INC &B3          ;; Increment the MSB of the dataptr

       INC &C228        ;; Increment Tube address
       BNE TubeAddr2
       INC &C229
       BNE TubeAddr2
       INC &C22A
.TubeAddr2

       DEC sectorcount%
       BNE SectorLoop2   ;; Loop for all sectors
    
       LDA #end_read
       JSR MMC_SetCommand
       JSR MMC_DoCommand

       PLP
       BRA CommandDone
	
  ; Flash Caps Lock & Shift Lock
.DoLEDS
  LDX #14
  LDA sectorcount%
  AND #1
  BEQ off
.SetLEDS
  LDX #6
.off
	STX &FE40
	INX
	STX &FE40
	RTS

	\ Reset LEDs
.ResetLEDS
	LDA #&76
	JSR &FFF4
  RTS

