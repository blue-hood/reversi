  .inesprg 1
  .ineschr 1
  .inesmir 0
  .inesmap 0

cellBlack         .equ $40
cellBlank         .equ $00
cellWhite         .equ $80
cellBlackToWhite  .equ cellWhite + 8*4
cellSetBlack      .equ cellBlack + 8
cellSetWhite      .equ cellWhite + 8
cellWhiteToBlack  .equ cellBlack + 8*4

controllerA       .equ $80
controllerB       .equ $40
controllerDown    .equ $04
controllerLeft    .equ $02
controllerRight   .equ $01
controllerSelect  .equ $20
controllerStart   .equ $10
controllerUp      .equ $08

  .rsset $00
bgBufferIndex               .rs $01
controller1                 .rs $01
controller1Prev             .rs $01
controller1RisingEdge       .rs $01
cursorX                     .rs $01
cursorY                     .rs $01
frameProceeded              .rs $01
gameMode                    .rs $01
ppuAddress                  .rs $02
ppuControl1                 .rs $01
ppuControl2                 .rs $01
soundCh1Address             .rs $02
soundCh1Timer               .rs $01
soundCh2Address             .rs $02
soundCh2Timer               .rs $01
spriteIndex                 .rs $01
stoneX                      .rs $01
stoneY                      .rs $01
stoneChar                   .rs $01
titleAddress                .rs $02
turnStonesCell              .rs $01
turnStonesCount             .rs $01
turnStonesEndIndex          .rs $01
turnStonesPrevIndex         .rs $01
turnStonesPrevIndexPartial  .rs $01
turnStonesStartIndex        .rs $01
turnStonesWriteAnimation    .rs $01

  .rsset $0200
sprite  .rs $ff

  .rsset $0300
bgBuffer .rs $80
board    .rs 8*8

  .bank 0
  .org $c000
Start:
  sei
  cld
  lda #$40
  sta $4017
  ldx #$ff
  txs
  lda #$00
  sta $2000
  sta $2001
  sta $4010

  bit $2002
initializeVBlank1Loop:
  bit $2002
  bpl initializeVBlank1Loop

  lda #$00
  tax
initializeMemoryLoop:
  sta $00,x
  sta $0100,x
  sta $0200,x
  sta $0300,x
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  inx
  bne initializeMemoryLoop

initializeVBlank2Loop:
  bit $2002
  bpl initializeVBlank2Loop

  lda #%10000000
  sta $2000
  sta ppuControl1
  lda #%00011000
  sta $2001
  sta ppuControl2

  ldx #$00
  lda #$3f
  sta bgBuffer,x
  inx
  lda #$00
  sta bgBuffer,x
  inx
  lda #$20
  sta bgBuffer,x
  inx
  ldy #$00
LoadPaletteLoop:
  lda Palette,y
  iny
  sta bgBuffer,x
  inx
  cpy #$20
  bne LoadPaletteLoop
  stx bgBufferIndex

  lda #$00
  sta ppuAddress
  lda #$20
  sta ppuAddress + 1
  lda #low(Title)
  sta titleAddress
  lda #high(Title)
  sta titleAddress + 1
LoadTitleLoop:
  jsr WaitFrameProceeded
  ldx #$00
  lda ppuAddress + 1
  sta bgBuffer,x
  inx
  lda ppuAddress
  sta bgBuffer,x
  inx
  lda #$20
  sta bgBuffer,x
  inx
  ldy #$00
LoadTitleWriteLoop:
  lda [titleAddress],y
  iny
  sta bgBuffer,x
  inx
  cpy #$20
  bne LoadTitleWriteLoop
  tya
  clc
  adc ppuAddress
  sta ppuAddress
  lda ppuAddress + 1
  adc #$00
  sta ppuAddress + 1
  tya
  clc
  adc titleAddress
  sta titleAddress
  lda titleAddress + 1
  adc #$00
  sta titleAddress + 1
  stx bgBufferIndex
  lda titleAddress
  cmp #low(Title + $0400)
  bne LoadTitleLoop
  lda titleAddress + 1
  cmp #high(Title + $0400)
  bne LoadTitleLoop

  lda PineappleRagCh1
  sta soundCh1Timer
  lda #low(PineappleRagCh1 + 1)
  sta soundCh1Address
  lda #high(PineappleRagCh1 + 1)
  sta soundCh1Address + 1
  lda PineappleRagCh2
  sta soundCh2Timer
  lda #low(PineappleRagCh2 + 1)
  sta soundCh2Address
  lda #high(PineappleRagCh2 + 1)
  sta soundCh2Address + 1

  lda #%00011111
  sta $4015

TitleLoop:
  jsr WaitFrameProceeded
  jsr ReadController1

  lda controller1RisingEdge
  and #controllerStart
  bne TitleBreak

  lda controller1RisingEdge
  and #controllerSelect
  beq selectGameSkip
  inc gameMode
  lda gameMode
  and #$03
  sta gameMode
selectGameSkip:

  ldx spriteIndex
  lda gameMode
  asl a
  asl a
  asl a
  asl a
  clc
  adc #$75
  sta sprite,x
  inx
  lda #$2a
  sta sprite,x
  inx
  lda #%00000010
  sta sprite,x
  inx
  lda #$44
  sta sprite,x
  inx
  stx spriteIndex

  jsr FinalizeSprite
  jmp TitleLoop
TitleBreak:

  lda StartSE
  sta soundCh1Timer
  lda #low(StartSE + 1)
  sta soundCh1Address
  lda #high(StartSE + 1)
  sta soundCh1Address + 1
  lda NoSound
  sta soundCh2Timer
  lda #low(NoSound + 1)
  sta soundCh2Address
  lda #high(NoSound + 1)
  sta soundCh2Address + 1
  ldx #90
  jsr Sleep

  jsr FinalizeSprite

  lda #$00
  sta ppuAddress
  lda #$20
  sta ppuAddress + 1
ClearTitleLoop:
  jsr WaitFrameProceeded
  ldx #$00
  lda ppuAddress + 1
  sta bgBuffer,x
  inx
  lda ppuAddress
  sta bgBuffer,x
  inx
  lda #$20
  sta bgBuffer,x
  inx
  lda #$00
ClearTitleWriteLoop:
  sta bgBuffer,x
  inx
  cpx #$20 + 3
  bne ClearTitleWriteLoop
  stx bgBufferIndex
  lda ppuAddress
  clc
  adc #$20
  sta ppuAddress
  lda ppuAddress + 1
  adc #$00
  sta ppuAddress + 1
  cmp #$24
  bne ClearTitleLoop

  lda #$00
  sta stoneY
  lda #$a0
  sta stoneChar
LoadGameWriteBoardYLoop:
  lda #$00
  sta stoneX
LoadGameWriteBoardXLoop:
  lda stoneX
  and #%00000011
  jsr WriteStone
  inc stoneX
  lda stoneX
  cmp #8
  bne LoadGameWriteBoardXLoop
  inc stoneY
  lda stoneY
  cmp #8
  bne LoadGameWriteBoardYLoop

  jsr WaitFrameProceeded
  ldx #$00
  lda #$20
  sta bgBuffer,x
  inx
  lda #$41
  sta bgBuffer,x
  inx
  lda #25
  sta bgBuffer,x
  inx
  lda #$a9
  sta bgBuffer,x
  inx
  lda #$aa
LoadGameWriteTopBorderLoop:
  sta bgBuffer,x
  inx
  cpx #25 + 3
  bne LoadGameWriteTopBorderLoop
  lda #$23
  sta bgBuffer,x
  inx
  lda #$61
  sta bgBuffer,x
  inx
  lda #25
  sta bgBuffer,x
  inx
  lda #$ba
LoadGameWriteBottomBorderLoop:
  sta bgBuffer,x
  inx
  cpx #25 + 3 + 25 + 3
  bne LoadGameWriteBottomBorderLoop
  stx bgBufferIndex

  jsr WaitFrameProceeded
  ldx #$00
  lda #$20
  sta bgBuffer,x
  inx
  lda #$61
  sta bgBuffer,x
  inx
  lda #24 + %10000000
  sta bgBuffer,x
  inx
  lda #$b9
LoadGameWriteLeftBorderLoop:
  sta bgBuffer,x
  inx
  cpx #24 + 3
  bne LoadGameWriteLeftBorderLoop
  lda #$20
  sta bgBuffer,x
  inx
  lda #$5a
  sta bgBuffer,x
  inx
  lda #26 + %10000000
  sta bgBuffer,x
  inx
  lda #$ba
LoadGameWriteRightBorderLoop:
  sta bgBuffer,x
  inx
  cpx #24 + 3 + 26 + 3
  bne LoadGameWriteRightBorderLoop
  stx bgBufferIndex

  lda #$a3
  sta stoneChar
  lda #3
  sta stoneX
  lda #4
  sta stoneY
  jsr WriteStone
  lda SetBlackSE
  sta soundCh1Timer
  lda #low(SetBlackSE + 1)
  sta soundCh1Address
  lda #high(SetBlackSE + 1)
  sta soundCh1Address + 1
  ldx #30
  jsr Sleep
  inc stoneX
  dec stoneY
  jsr WriteStone
  lda SetBlackSE
  sta soundCh1Timer
  lda #low(SetBlackSE + 1)
  sta soundCh1Address
  lda #high(SetBlackSE + 1)
  sta soundCh1Address + 1
  ldx #30
  jsr Sleep
  lda #$a6
  sta stoneChar
  dec stoneX
  jsr WriteStone
  lda SetWhiteSE
  sta soundCh2Timer
  lda #low(SetWhiteSE + 1)
  sta soundCh2Address
  lda #high(SetWhiteSE + 1)
  sta soundCh2Address + 1
  ldx #30
  jsr Sleep
  inc stoneX
  inc stoneY
  jsr WriteStone
  lda SetWhiteSE
  sta soundCh2Timer
  lda #low(SetWhiteSE + 1)
  sta soundCh2Address
  lda #high(SetWhiteSE + 1)
  sta soundCh2Address + 1
  ldx #30
  jsr Sleep

  ldx #0
  lda cellBlank
InitializeBoardLoop:
  sta board,x
  inx
  cpx #8*8
  bne InitializeBoardLoop
  lda #cellWhite
  sta board + 3 + 3*8
  sta board + 4 + 4*8
  lda #cellBlack
  sta board + 4 + 3*8
  sta board + 3 + 4*8

  lda #3
  sta cursorX
  sta cursorY

GameLoop:
  jsr WaitFrameProceeded

  jsr ReadController1
  ;execPlayerCell
  ;execPlayercontrollerRisingEdge
  ;execPlayerSetSE
  ;execPlayerPalette
  ;execPlayerCursorX
  ;execPlayerCursorY
  ;execPlayerSoundTimer
  ;execPlayerSoundAddress
  jsr ExecPlayer

  jsr ReadController1
  jsr ExecPlayer

  ldx #0
TurnStoneLoop:
  lda board,x
  and #%00111111
  beq TurnStoneSkip
  and #%00000111
  bne TurnStoneWriteSkip
  lda board,x
  lsr a
  lsr a
  lsr a
  tay
  lda StoneChars,y
  sta stoneChar
  txa
  and #7
  sta stoneX
  txa
  pha
  lsr a
  lsr a
  lsr a
  sta stoneY
  jsr WriteStone
  pla
  tax
TurnStoneWriteSkip:
  dec board,x
TurnStoneSkip:
  inx
  cpx #8*8
  bne TurnStoneLoop

  jsr FinalizeSprite
  jmp GameLoop

Abs:
  cmp #$00
  bpl AbsInvertSkip
  eor #$ff
  clc
  adc #$01
AbsInvertSkip:
  rts

ExecPlayer:
  lda controller1RisingEdge
  and #controllerLeft
  beq MoveCursorLeftSkip
  dec cursorX
MoveCursorLeftSkip:
  lda controller1RisingEdge
  and #controllerRight
  beq MoveCursorRightSkip
  inc cursorX
MoveCursorRightSkip:
  lda cursorX
  and #7
  sta cursorX
  lda controller1RisingEdge
  and #controllerUp
  beq MoveCursorUpSkip
  dec cursorY
MoveCursorUpSkip:
  lda controller1RisingEdge
  and #controllerDown
  beq MoveCursorDownSkip
  inc cursorY
MoveCursorDownSkip:
  lda cursorY
  and #7
  sta cursorY

  lda cursorY
  asl a
  asl a
  asl a
  clc
  adc cursorX
  tax
  lda controller1RisingEdge
  and #controllerA
  beq SetStoneSkip
  lda board,x
  cmp #cellBlank
  bne SetStoneError
  lda #cellSetWhite
  sta board,x
  txa
  pha
  jsr TurnStones
  pla
  tax
  lda turnStonesCount
  beq SetStoneRestore
  lda SetWhiteSE
  sta soundCh2Timer
  lda #low(SetWhiteSE + 1)
  sta soundCh2Address
  lda #high(SetWhiteSE + 1)
  sta soundCh2Address + 1
  jmp SetStoneSkip
SetStoneRestore:
  lda #cellBlank
  sta board,x
SetStoneError:
  lda ErrorSE
  sta soundCh2Timer
  lda #low(ErrorSE + 1)
  sta soundCh2Address
  lda #high(ErrorSE + 1)
  sta soundCh2Address + 1
SetStoneSkip:

  lda cursorX
  asl a
  asl a
  asl a
  sta stoneX
  asl a
  clc
  adc stoneX
  sta stoneX
  lda cursorY
  asl a
  asl a
  asl a
  sta stoneY
  asl a
  clc
  adc stoneY
  sta stoneY
  ldx spriteIndex
  lda stoneY
  clc
  adc #23
  sta sprite,x
  inx
  lda #$c9
  sta sprite,x
  inx
  lda #%00000010
  sta sprite,x
  inx
  lda stoneX
  clc
  adc #16
  sta sprite,x
  inx
  lda stoneY
  clc
  adc #23
  sta sprite,x
  inx
  lda #$c9
  sta sprite,x
  inx
  lda #%01000010
  sta sprite,x
  inx
  lda stoneX
  clc
  adc #31
  sta sprite,x
  inx
  lda stoneY
  clc
  adc #38
  sta sprite,x
  inx
  lda #$c9
  sta sprite,x
  inx
  lda #%10000010
  sta sprite,x
  inx
  lda stoneX
  clc
  adc #16
  sta sprite,x
  inx
  lda stoneY
  clc
  adc #38
  sta sprite,x
  inx
  lda #$c9
  sta sprite,x
  inx
  lda #%11000010
  sta sprite,x
  inx
  lda stoneX
  clc
  adc #31
  sta sprite,x
  inx
  stx spriteIndex
  rts

FinalizeSprite:
  ldx spriteIndex
  lda #$f8
FinalizeSpriteLoop:
  cpx #$00
  beq FinalizeSpriteBreak
  sta sprite,x
  inx
  inx
  inx
  inx
  jmp FinalizeSpriteLoop
FinalizeSpriteBreak:
  stx spriteIndex
  rts

ReadController1:
  lda controller1
  sta controller1Prev
  lda #$01
  sta $4016
  lsr a
  sta $4016
  lda $4016
  lsr a
  rol controller1
  lda $4016
  lsr a
  rol controller1
  lda $4016
  lsr a
  rol controller1
  lda $4016
  lsr a
  rol controller1
  lda $4016
  lsr a
  rol controller1
  lda $4016
  lsr a
  rol controller1
  lda $4016
  lsr a
  rol controller1
  lda $4016
  lsr a
  rol controller1
  lda controller1Prev
  eor #$ff
  and controller1
  sta controller1RisingEdge
  rts

Sleep:
  jsr WaitFrameProceeded
  dex
  bne Sleep
  rts

TurnStones:
  lda board,x
  and #%11000000
  sta turnStonesCell
  stx turnStonesStartIndex
  ldy #0
  sty turnStonesCount
TurnStonesDirectionLoop:
  ldx turnStonesStartIndex
TurnStonesCheckLoop:
  stx turnStonesPrevIndex
  txa
  clc
  adc TurnStonesDirection,y
  tax

  lda turnStonesPrevIndex
  and #%00000111
  sta turnStonesPrevIndexPartial
  txa
  and #%00000111
  sec
  sbc turnStonesPrevIndexPartial
  jsr Abs
  cmp #%00000111
  beq TurnStonesCheckSkip
  lda turnStonesPrevIndex
  and #%00111000
  sta turnStonesPrevIndexPartial
  txa
  and #%00111000
  sec
  sbc turnStonesPrevIndexPartial
  jsr Abs
  cmp #%00111000
  beq TurnStonesCheckSkip

  lda board,x
  and #%11000000
  cmp #cellBlank
  beq TurnStonesCheckSkip

  lda board,x
  and #%11000000
  cmp turnStonesCell
  bne TurnStonesCellSkip
  lda #cellWhiteToBlack - cellBlack + 1
  sta turnStonesWriteAnimation
  stx turnStonesEndIndex
  ldx turnStonesStartIndex
TurnStonesWriteLoop:
  txa
  clc
  adc TurnStonesDirection,y
  tax
  cpx turnStonesEndIndex
  beq TurnStonesCheckSkip
  lda turnStonesCell
  clc
  adc turnStonesWriteAnimation
  sta board,x
  inc turnStonesCount
  inc turnStonesWriteAnimation
  jmp TurnStonesWriteLoop
TurnStonesCellSkip:

  jmp TurnStonesCheckLoop
TurnStonesCheckSkip:
  iny
  cpy #8
  bne TurnStonesDirectionLoop
  rts

WaitFrameProceeded:
  lda #$01
  sta frameProceeded
WaitFrameProceededLoop:
  lda frameProceeded
  bne WaitFrameProceededLoop
  rts

WriteStone:
  lda stoneX
  asl a
  clc
  adc stoneX
  clc
  adc #$62
  sta ppuAddress
  lda #$20
  sta ppuAddress + 1
  ldy stoneY
WriteStoneSetYLoop:
  cpy #$00
  beq WriteStoneSetYBreak
  lda ppuAddress
  clc
  adc #$60
  sta ppuAddress
  lda ppuAddress + 1
  adc #$00
  sta ppuAddress + 1
  dey
  jmp WriteStoneSetYLoop
WriteStoneSetYBreak:
  ldx bgBufferIndex
  cpx #$40
  bmi WriteStoneWaitSkip
  jsr WaitFrameProceeded
  ldx bgBufferIndex
WriteStoneWaitSkip:
  ldy #$00
WriteStoneLoop:
  lda ppuAddress + 1
  sta bgBuffer,x
  inx
  tya
  clc
  adc ppuAddress
  sta bgBuffer,x
  inx
  lda #3 + %10000000
  sta bgBuffer,x
  inx
  tya
  clc
  adc stoneChar
  sta bgBuffer,x
  inx
  clc
  adc #$10
  sta bgBuffer,x
  inx
  clc
  adc #$10
  sta bgBuffer,x
  inx
  iny
  cpy #3
  bne WriteStoneLoop
  stx bgBufferIndex
  rts

VBlank:
  pha
  txa
  pha
  tya
  pha

  lda frameProceeded
  bne VBlankFrameProcess
  jmp VBlankFrameProcessSkip
VBlankFrameProcess:

  lda #high(sprite)
  sta $4014

  ldx #$00
WritePpuLoop:
  cpx bgBufferIndex
  beq WritePpuBreak
  lda bgBuffer,x
  inx
  sta $2006
  lda bgBuffer,x
  inx
  sta $2006
  lda bgBuffer,x
  bpl WritePpuHorizontal
  lda ppuControl1
  ora #%00000100
  jmp WritePpuDirection
WritePpuHorizontal:
  lda ppuControl1
  and #%11111011
WritePpuDirection:
  sta $2000
  sta ppuControl1
  lda bgBuffer,x
  and #%01111111
  tay
  inx
WritePpuDataLoop:
  cpy #$00
  beq WritePpuDataBreak
  lda bgBuffer,x
  inx
  sta $2007
  dey
  jmp WritePpuDataLoop
WritePpuDataBreak:
  jmp WritePpuLoop
WritePpuBreak:
  lda #$00
  sta bgBufferIndex
  sta $2005
  sta $2005

  lda #$04
  sta spriteIndex
VBlankFrameProcessSkip:

PlaySoundCh1Loop:
  lda soundCh1Timer
  bne PlaySoundCh1Break
  ldy #$00
  lda [soundCh1Address],y
  iny
  asl a
  beq PlaySoundCh1Break
  tax
  lda #%10000110
  sta $4000
  lda #%00000000
  sta $4001
  lda Notes,x
  sta $4002
  lda Notes + 1,x
  ora #%00001000
  sta $4003
  lda [soundCh1Address],y
  iny
  sta soundCh1Timer
  tya
  clc
  adc soundCh1Address
  sta soundCh1Address
  lda soundCh1Address + 1
  adc #$00
  sta soundCh1Address + 1
  jmp PlaySoundCh1Loop
PlaySoundCh1Break:
  dec soundCh1Timer

PlaySoundCh2Loop:
  lda soundCh2Timer
  bne PlaySoundCh2Break
  ldy #$00
  lda [soundCh2Address],y
  iny
  asl a
  beq PlaySoundCh2Break
  tax
  lda #%10000110
  sta $4004
  lda #%00000000
  sta $4005
  lda Notes,x
  sta $4006
  lda Notes + 1,x
  ora #%00001000
  sta $4007
  lda [soundCh2Address],y
  iny
  sta soundCh2Timer
  tya
  clc
  adc soundCh2Address
  sta soundCh2Address
  lda soundCh2Address + 1
  adc #$00
  sta soundCh2Address + 1
  jmp PlaySoundCh2Loop
PlaySoundCh2Break:
  dec soundCh2Timer

  lda #$00
  sta frameProceeded
  pla
  tay
  pla
  tax
  pla
  rti

TurnStonesDirection:
  .db $01, $09, $08, $07, $ff, $f7, $f8, $f9

Palette:  .incbin "palette.dat"
StoneChars:
  .db $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0
  .db $a3, $a3, $d3, $dc, $d6, $a6, $a6, $a6
  .db $a6, $a6, $d9, $dc, $d0, $a3, $a3, $a3
Title:  .incbin "title.nam"

Notes:
  .dw 6821, 6429, 6079, 5766, 5430, 5131, 4821, 4584, 4302, 4052, 3830, 3631, 3410, 3232, 3039, 2882
  .dw 2714, 2565, 2421, 2282, 2150, 2033, 1921, 1809, 1710, 1616, 1523, 1437, 1357, 1279, 1210, 1141
  .dw 1077, 1016, 0958, 0906, 0854, 0806, 0761, 0718, 0678, 0640, 0604, 0570, 0538, 0508, 0479, 0452
  .dw 0427, 0403, 0380, 0358, 0338, 0319, 0301, 0284, 0268, 0253, 0239, 0226, 0213, 0201, 0189, 0179
  .dw 0169, 0159, 0150, 0142, 0134, 0126, 0119, 0112, 0106, 0100, 0094, 0089, 0084, 0079, 0075, 0070
  .dw 0066, 0063, 0059, 0056, 0052, 0049, 0047, 0044, 0041, 0039, 0037, 0035, 0033, 0031, 0029, 0027
  .dw 0026, 0024, 0023, 0021, 0020, 0019, 0018, 0017, 0016, 0015, 0014, 0013, 0012, 0012, 0011, 0010
  .dw 0010, 0009, 0008, 0008, 0007, 0007, 0006, 0006, 0006, 0005, 0005, 0005, 0004, 0004, 0004, 0003
NoSound:
  .db 0, 0
PineappleRagCh1:
  .db 0, 67
  .db 10, 65
  .db 19, 63
  .db 9, 62
  .db 10, 61
  .db 10, 62
  .db 9, 60
  .db 10, 58
  .db 9, 60
  .db 10, 62
  .db 10, 65
  .db 48, 67
  .db 9, 67
  .db 19, 66
  .db 10, 67
  .db 10, 69
  .db 9, 70
  .db 19, 72
  .db 20, 65
  .db 38, 65
  .db 19, 70
  .db 10, 77
  .db 19, 75
  .db 10, 74
  .db 9, 73
  .db 10, 74
  .db 9, 72
  .db 10, 70
  .db 10, 72
  .db 9, 74
  .db 10, 77
  .db 19, 82
  .db 10, 86
  .db 19, 79
  .db 9, 77
  .db 20, 75
  .db 9, 74
  .db 10, 73
  .db 9, 74
  .db 10, 75
  .db 10, 70
  .db 19, 77
  .db 9, 74
  .db 10, 77
  .db 10, 74
  .db 9, 70
  .db 0, 0
PineappleRagCh2:
  .db 255, 255
  .db 33, 255
  .db 19, 46
  .db 19, 62
  .db 20, 41
  .db 19, 53
  .db 19, 46
  .db 19, 62
  .db 19, 41
  .db 20, 62
  .db 19, 46
  .db 19, 62
  .db 19, 41
  .db 19, 53
  .db 20, 46
  .db 0, 0
ErrorSE:
  .db 0, 40
  .db 5, $7f
  .db 10, 40
  .db 15, $7f
  .db 0, 0
SetBlackSE:
  .db 0, 67 - 6
  .db 4, 71 - 6
  .db 12, $7f
  .db 0, 0
SetWhiteSE:
  .db 0, 71 - 6
  .db 4, 67 - 6
  .db 12, $7f
  .db 0, 0
StartSE:
  .db 0, $7f
  .db 15, 45 + 24
  .db 7, 42 + 24
  .db 7, 38 + 24
  .db 7, 42 + 24
  .db 7, 45 + 24
  .db 0, 0

  .bank 1
  .org $fffa
  ; VBlank 割り込み
  .dw VBlank
  ; リセット割り込み
  .dw Start
  ; IRQ 割り込み
  .dw Start

  .bank 2
  .org $0000
  .incbin "reversi.chr"
