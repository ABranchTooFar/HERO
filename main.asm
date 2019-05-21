
; --- Constants ---

; TODO: Move these to a separate file (and separate engine specific consts from game speccific consts)

PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

JOYPAD_ADDR_1 = $4016
JOYPAD_ADDR_2 = $4017

OAM_DMA = %10000000   ; 1 = need to do an OAM DMA, 0 = Don't need to


;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

.ENUM $0000

  gameStatus   .DSB 1
  joypad1      .DSB 1
  secondsTimer .DSB 1

  ;NOTE: declare variables using the DSB and DSW directives, like this:
  ;MyVariable0 .DSB 1

.ENDE


;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

.MACRO setOAM_DMA
  LDA gameStatus
  ORA #%10000000
  STA gameStatus
.ENDM


;----------------------------------------------------------------
; iNES header
;----------------------------------------------------------------

  .DB "NES", $1a ;identification of the iNES header
  .DB PRG_COUNT ;number of 16KB PRG-ROM pages
  .DB $01 ;number of 8KB CHR-ROM pages
  .DB $00|MIRRORING ;mapper 0 and mirroring
  .DSB 9, $00 ;clear the remaining bytes

;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

  .BASE $10000-(PRG_COUNT*$4000)

  ; Functions and macros for the player object
  .INCLUDE "player.asm"

Reset:
  ; Initialization goes here:

  ; --------------------------------------------------------------------
  ; TODO: Need to enable sprites and wait for the NES to be ready etc...
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem

vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2
  ; --------------------------------------------------------------------

  ; Latches the PPU status register and sets the PPU address for
  ; loading the palettes
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006
  LDX #$00

  ; Loads the palette values into the PPU
  LDA #$0C
  STA $2007
  LDA #$22
  STA $2007
  LDA #$20
  STA $2007
  LDA #$2D
  STA $2007

  ; Loads the palette values into the PPU
  LDA #$0C
  STA $2007
  LDA #$24
  STA $2007
  LDA #$38
  STA $2007
  LDA #$2D
  STA $2007

  ; Loads the palette values into the PPU
  LDA #$0C
  STA $2007
  LDA #$22
  STA $2007
  LDA #$20
  STA $2007
  LDA #$2D
  STA $2007

  ; Loads the palette values into the PPU
  LDA #$0C
  STA $2007
  LDA #$22
  STA $2007
  LDA #$20
  STA $2007
  LDA #$2D
  STA $2007

  ; Loads the palette values into the PPU
  ; Sprite palette 0
  LDA #$0C
  STA $2007
  LDA #$25
  STA $2007
  LDA #$38
  STA $2007
  LDA #$22
  STA $2007

  ; Loads the palette values into the PPU
  ; Sprite palette 1
  LDA #$0C
  STA $2007
  LDA #$25
  STA $2007
  LDA #$22
  STA $2007
  LDA #$20
  STA $2007

  ; Loads the palette values into the PPU
  ; Sprite palette 2
  LDA #$0C
  STA $2007
  LDA #$0C
  STA $2007
  LDA #$0C
  STA $2007
  LDA #$0C
  STA $2007

  ; Loads the palette values into the PPU
  ; Sprite palette 3
  LDA #$0C
  STA $2007
  LDA #$0C
  STA $2007
  LDA #$0C
  STA $2007
  LDA #$0C
  STA $2007

  ; Load the player tiles
  .loadPlayerTopSprite 10,10,0
  .loadPlayerMiddleSprite 10,10,0
  ;.loadPlayerBottomSprite 10,10,0

  ; Initialize the OAM data in the PPU with a DMA
  ; Set the OAM DMA flag to update the graphics
  .setOAM_DMA

  ; TODO: This is for debugging
  ; Set the playerPositionX and playerPositionY
  LDA #$10
  STA playerPositionX
  STA playerPositionY

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00010000   ; no intensify (black background), enable sprites
  STA $2001

Forever:
  JMP Forever

NMI:

  ; V-Blank code goes here:
  LDA secondsTimer
  CLC
  ADC #$01
  CMP #$84
  BPL +
  LDA playerHeliAnimation
  CLC
  ADC #$01
  STA playerHeliAnimation
  ; Set the OAM DMA flag to update the graphics
  .setOAM_DMA
  ; Reset the secondsTimer
  LDA #$00
+
  STA secondsTimer


  ; TODO: Make this more general (move to engine!)
  ; Simple code to check for joypad input
readjoy:
  LDA #$01
  ; While the strobe bit is set, buttons will be continuously reloaded.
  ; This means that reading from JOYPAD_ADDR_1 will only return the state of the
  ; first button: button A.
  STA JOYPAD_ADDR_1
  STA joypad1
  LSR a        ; now A is 0
  ; By storing 0 into JOYPAD_ADDR_1, the strobe bit is cleared and the reloading stops.
  ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD_ADDR_1.
  STA JOYPAD_ADDR_1
loop:
  LDA JOYPAD_ADDR_1
  LSR a	       ; bit 0 -> Carry
  ROL joypad1  ; Carry -> bit 0; bit 7 -> Carry
  BCC loop
  ;RTS


  ; TODO: Ensure both directions aren't being pressed at the same time?
  ; Press the left direction
  LDA #%00000010
  BIT joypad1
  BEQ +
  ; Button pressed; change sprite
  ; Move the player
  LDA playerPositionX
  SEC
  SBC #$01
  STA playerPositionX
  JSR playerMoveLeft
  JMP ++
+
  ; Press the right direction
  LDA #%00000001
  BIT joypad1
  BEQ +
  ; Button pressed; change sprite
  ; Move the player
  LDA playerPositionX
  CLC
  ADC #$01
  STA playerPositionX
  JSR playerMoveRight
+

  ; TODO: Debugging walk animation!
  LDA playerHeliAnimation
  AND #%00000111
+
  SEC
  SBC #$01
  BNE +
  JSR playerWalkFrame1
  JMP +end
+
  SEC
  SBC #$01
  BNE +
  JSR playerWalkFrame2
  JMP +end
+
  SEC
  SBC #$01
  BNE +
  JSR playerWalkFrame3
  JMP +end
+
  SEC
  SBC #$01
  BNE +
  JSR playerWalkFrame4
  JMP +end
+
  JSR playerWalkFrame5
+end

  JSR playerAnimate

  ; Check if OAM DMA is required
  LDA gameStatus
  AND #OAM_DMA
  BEQ +skipDMA
  ; Reset the OAM DMA flag
  LDA gameStatus
  AND #%01111111
  STA gameStatus
  ; Starts the OAM DMA
  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer
+skipDMA
  RTI

IRQ:

  ;NOTE: IRQ code goes here

;----------------------------------------------------------------
; interrupt vectors
;----------------------------------------------------------------

  .org $fffa

  .dw NMI
  .dw Reset
  .dw IRQ

;----------------------------------------------------------------
; CHR-ROM bank
;----------------------------------------------------------------

  .incbin "tiles.chr"
