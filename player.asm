; --- Player Constants ---

PLAYER_DIRECTION = %10000000   ; 0 = right, 1 = left
PLAYER_ON_GROUND = %01000000   ; 0 = falling, 1 = on ground


; --- Player Variables ---

.ENUM $0010
  playerStatus        .DSB 1
  playerHeliAnimation .DSB 1
  playerWalkAnimation .DSB 1
  playerPositionX     .DSB 1
  playerPositionY     .DSB 1
.ENDE


; --- Player Routines ---

playerMoveRight:
  ; Move tiles
  ; <rotate value> + <sprite width> - <offset from origin>
  ; Blade left
  LDA playerPositionX
  ;CLC
  ;ADC #$00
  STA $0203

  ; Blade right
  ;LDA playerPositionX
  CLC
  ADC #$08
  STA $0207

  ; Head
  LDA playerPositionX
  CLC
  ADC #$09
  STA $020B

  ; Backpack
  LDA playerPositionX
  CLC
  ADC #$01
  STA $020F

  ; Body
  LDA playerPositionX
  CLC
  ADC #$09
  STA $0213

  ; Check if already facing right
  LDA playerStatus
  AND #PLAYER_DIRECTION
  BEQ +skip

  ; Flip the sprites
  ; Blade left
  LDA #$00
  STA $0202

  ; Blade right
  LDA #$40
  STA $0206

  ; Head
  LDA #$01
  STA $020A

  ; Backpack
  LDA #$01
  STA $020E

  ; Body
  LDA #$01
  STA $0212

  ; Clear the PLAYER_DIRECTION bit
  LDA playerStatus
  AND #!PLAYER_DIRECTION
  STA playerStatus

  ; Set the OAM DMA flag to update the graphics
  .setOAM_DMA
+skip
  RTS
;playerMoveRight


playerMoveLeft:
  ; Move tiles
  ; Blade left
  LDA playerPositionX
  CLC
  ADC #$0C
  STA $0203

  ; Blade right
  LDA playerPositionX
  CLC
  ADC #$04
  STA $0207

  ; Head
  LDA playerPositionX
  CLC
  ADC #$03
  STA $020B

  ; Backpack
  LDA playerPositionX
  CLC
  ADC #$0B
  STA $020F

  ; Body
  LDA playerPositionX
  CLC
  ADC #$03
  STA $0213

  ; Check if already facing left
  LDA playerStatus
  AND #PLAYER_DIRECTION
  BNE +skip

  ; Flip the sprites
  ; Blade left
  LDA #$40
  STA $0202

  ; Blade right
  LDA #$00
  STA $0206

  ; Head
  LDA #$41
  STA $020A

  ; Backpack
  LDA #$41
  STA $020E

  ; Body
  LDA #$41
  STA $0212

  ; Set the PLAYER_DIRECTION bit
  LDA playerStatus
  ORA #PLAYER_DIRECTION
  STA playerStatus

  ; Set the OAM DMA flag to update the graphics
  .setOAM_DMA
+skip
  RTS
;playerMoveLeft



; --- Walk Animation Dev ---


; Subroutines for walking animation frames
playerWalkFrame0:
  ; Legs top
  LDA playerPositionY
  CLC
  ADC #$11
  STA $0214
  LDA #$10
  STA $0215
  LDA #$01
  STA $0216
  LDA playerPositionX
  CLC
  ADC #$09
  STA $0217
  RTS
;playerWalkFrame0

playerWalkFrame1:
  ; Legs left
  LDA playerPositionY
  CLC
  ADC #$11
  STA $0214
  LDA #$12
  STA $0215
  LDA #$01
  STA $0216
  LDA playerPositionX
  CLC
  ADC #$04
  STA $0217

  ; Legs right
  LDA playerPositionY
  CLC
  ADC #$10
  STA $0218
  LDA #$13
  STA $0219
  LDA #$01
  STA $021A
  LDA playerPositionX
  CLC
  ADC #$09
  STA $021B
  RTS
;playerWalkFrame1

playerWalkFrame2:
  ; Legs left
  LDA playerPositionY
  CLC
  ADC #$10
  STA $0214
  LDA #$14
  STA $0215
  LDA #$01
  STA $0216
  LDA playerPositionX
  CLC
  ADC #$03
  STA $0217

  ; Legs right
  LDA playerPositionY
  CLC
  ADC #$10
  STA $0218
  LDA #$15
  STA $0219
  LDA #$01
  STA $021A
  LDA playerPositionX
  CLC
  ADC #$0B
  STA $021B
  RTS
;playerWalkFrame2

playerWalkFrame3:
  ; Legs left
  LDA playerPositionY
  CLC
  ADC #$10
  STA $0214
  LDA #$16
  STA $0215
  LDA #$01
  STA $0216
  LDA playerPositionX
  CLC
  ADC #$03
  STA $0217

  ; Legs right
  LDA playerPositionY
  CLC
  ADC #$10
  STA $0218
  LDA #$17
  STA $0219
  LDA #$01
  STA $021A
  LDA playerPositionX
  CLC
  ADC #$0B
  STA $021B
  RTS
;playerWalkFrame3

playerWalkFrame4:
  ; Legs left
  LDA playerPositionY
  CLC
  ADC #$11
  STA $0214
  LDA #$18
  STA $0215
  LDA #$01
  STA $0216
  LDA playerPositionX
  CLC
  ADC #$05
  STA $0217

  ; Legs right
  LDA playerPositionY
  CLC
  ADC #$11
  STA $0218
  LDA #$19
  STA $0219
  LDA #$01
  STA $021A
  LDA playerPositionX
  CLC
  ADC #$0D
  STA $021B
  RTS
;playerWalkFrame4

playerWalkFrame5:
  ; Legs left
  LDA playerPositionY
  CLC
  ADC #$11
  STA $0214
  LDA #$1A
  STA $0215
  LDA #$01
  STA $0216
  LDA playerPositionX
  CLC
  ADC #$07
  STA $0217

  ; Legs right
  LDA playerPositionY
  CLC
  ADC #$10
  STA $0218
  LDA #$1B
  STA $0219
  LDA #$01
  STA $021A
  LDA playerPositionX
  CLC
  ADC #$09
  STA $021B
  RTS
;playerWalkFrame5


; --- NOT GREAT CODE AHEAD ---

playerAnimate:
heliAnimate:
  ; Check if the player is moving
  LDA joypad1
  AND #%00001011
  BEQ stopHeli
  ; Make sure the animation timer is between 0 - 2
  LDA playerHeliAnimation
  AND #%00000011
  CMP #$03
  BNE +
  LDA #$01
+
  ; Blade Left
  STA $0201
  ; Blade Right
  STA $0205
  ;RTS
  JMP armAnimate
stopHeli:
  LDA #$01
  ; Set the amination to the first frame
  STA playerHeliAnimation
  ; Blade Left
  STA $0201
  ; Blade Right
  STA $0205
  ;RTS
;heliAnimate


armAnimate:
  ; Check if the player is moving
  LDA joypad1
  AND #%00000011
  BEQ stopArm
  ; Make sure the animation timer is between 0 - 2
  LDA playerHeliAnimation
  AND #%00001000
  LSR
  LSR
  LSR
  CLC
  ADC #$05
  ; Body
  STA $0211
  RTS
stopArm:
  ; Body
  LDA #$05
  STA $0211
  RTS
;armAnimate


.MACRO loadPlayerTopSprite x,y,frame
  ; Left Blade: (x), (y)
  ; Right Blade: (x + 8), (y)
  ; Head: (x + 9), (y + 1)

  ; Blade Left
  LDA #$y
  STA $0200
  LDA #$00 + frame
  STA $0201
  LDA #$00
  STA $0202
  LDA #$x
  STA $0203

  ; Blade Right
  LDA #$y
  STA $0204
  LDA #$00 + frame
  STA $0205
  LDA #$40
  STA $0206
  LDA #$x + 8
  STA $0207

.ENDM


.MACRO loadPlayerMiddleSprite x,y,frame
  ; Backpack: (x), (y + 8)

  ; Head
  LDA #$y + 1
  STA $0208
  LDA #$03
  STA $0209
  LDA #$01
  STA $020A
  LDA #$x + 9
  STA $020B

  ; Backpack
  LDA #$y + 8
  STA $020C
  LDA #$04
  STA $020D
  LDA #$01
  STA $020E
  LDA #$x + 1
  STA $020F

  ; Body
  LDA #$y + 9
  STA $0210
  LDA #$05 + frame
  STA $0211
  LDA #$01
  STA $0212
  LDA #$x + 9
  STA $0213

.ENDM


.MACRO loadPlayerBottomSprite x,y,frame

  ; Legs top
  LDA #$y + 17
  STA $0214
  LDA #$10
  STA $0215
  LDA #$01
  STA $0216
  LDA #$x + 9
  STA $0217

.ENDM
