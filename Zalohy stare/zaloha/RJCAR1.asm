
 LIST	   P=16F874A, R=DEC
 INCLUDE  <P16F874.INC>

                  ;deklarace registru
r1      equ 20h
r2      equ 21h
r3      equ 22h
r4      equ 23h
r5		equ 24h
r6		equ 25h



w_temp  equ 2Bh
s_temp  equ 2Ch

num     equ 30h

pri0    equ 31h
pri1    equ 32h
pri2    equ 33h
pri3    equ 34h
pri4    equ 35h
pri5    equ 36h
pri6    equ 37h
pri7    equ 38h
cil     equ 39h


        ;registry stavu

o_a     equ 40h
o_b     equ 41h
o_c     equ 42h
o_d     equ 43h
o_e     equ 44h
o_f     equ 45h
o_g     equ 46h
o_h     equ 47h
o_i     equ 48h
o_j     equ 77h
o_k     equ 78h
o_l     equ 79h

ir_x    equ 49h
ir_49   equ 50h
ir_50   equ 51h
ir_51   equ 52h
ir_52   equ 53h
ir_53   equ 54h
ir_54   equ 55h
ir_55   equ 56h
ir_56   equ 57h
ir_57   equ 58h
ir_58   equ 59h
ir_59   equ 5Ah
ir_60   equ 5Bh
ir_61   equ 5Ch
ir_62   equ 5Dh
ir_80   equ 5Eh
ir_84   equ 5Fh
ir_85   equ 60h
ir_86   equ 61h
ir_87   equ 62h
ir_88   equ 63h
ir_89   equ 64h
ir_90   equ 65h
ir_91   equ 66h
ir_92   equ 67h
ir_93   equ 68h
ir_127  equ 69h
ir_128  equ 6Ah


locked  equ 70h
port    equ 71h
prc     equ 72h
nastart equ 73h
tl1     equ 74h
tl2     equ 75h
tl3     equ 76h
timsir	equ 7Ah
cassir	equ 7Bh
conf	equ 7Ch
casov	equ 7Dh
timvar	equ 7Eh
timrtu	equ 7Fh
timlza	equ 6Bh

o1tmp	equ 26h
o2tmp	equ 27h
o3tmp	equ 28h
o4tmp	equ 29h
o1tar	equ 2Ah
o2tar	equ 2Dh
o3tar	equ 2Eh
o4tar	equ 2Fh

timwtu	equ 3Ah
spinac	equ 3Bh
timspi	equ 3Ch
timods	equ 3Dh


;KONSTANTY
;conf constant
T0OF	equ .0
;casov constant
VAROV	equ .0
REDTUN	equ .1
LEDZAM	equ .2
WHITUN	equ .3
ODSKOK	equ .4


        org 000h        ;vektor zacatku
        goto init

        org 004h        ;vektor preruseni
        goto inter


init    movlw .1    ;oznaceni tohoto procesoru 1 Hlavn� procesor
        movwf num

        clrf PORTA      ;Init PORTS
        clrf PORTB
        clrf PORTC
        clrf PORTD
        clrf PORTE
        

        bsf STATUS, RP0  ;Bank 1

        movlw b'00001001' ;0 left justifed, FOSC/2 na rychlost prevodu 0, 00, nastaveni analogov�ch vstupu a hodnotu k porovn�n� 0000
        movwf ADCON1

        movlw	b'00101111'; 1 znamen� vstup, 0 v�stup
        movwf	TRISA
        movlw	b'00000001'
        movwf	TRISB
        movlw b'00000000'
        movwf TRISC
        movlw b'00000000'
        movwf TRISD
        movlw b'00000001'
        movwf TRISE
        
        movlw b'11000111'
        movwf OPTION_REG

        bcf STATUS, RP0 ;Bank 0

        call inton
        
        ;po startu zamkne a zapne alarm
        call t1_00
        ;prozatim vypnuto ptze nefonguje odemknuti cili bych nemohl testovat
        
        bcf PCLATH,4
		bsf PCLATH,3 ;Select page 1
		goto start      ;zacni na startu
        

inter   call intoff
        movwf w_temp ;copy w to temp register
        swapf STATUS, W ;swap status to be saved into w
        clrf STATUS ;bank 0, regardless of current bank, clears irp,rp1,rp0
        movwf s_temp ;save status to bank zero status_temp register

        btfsc INTCON, INTF      ;preruseni od RX B0 prijem radio signalu
        call radio
        btfsc INTCON, T0IF
        bsf conf, T0OF

        swapf s_temp, W ;swap status_temp register into w
        movwf STATUS ;move w into status register;(sets bank to original state)
        swapf w_temp, F ;swap w_temp
        swapf w_temp, W ;
        call inton
        return

;p�i zachyceni signalu na radiovem p�ij�ma�i        
radio   nop
        return
;p�i p�ete�en� timeru 0, a� po f�zi synchronizace procesor�    
timer0	btfsc cassir, 0
		call sirbeep
		btfsc casov, VAROV
		call varoff
		btfsc casov, REDTUN
		call rtuoff
		btfsc casov, LEDZAM
		call lzabli
		btfsc casov, WHITUN
		call wtuoff
		btfsc casov, ODSKOK
		call odsoff
        btfsc spinac, 2
		call spioff

		bcf conf, T0OF
		return
;houkani sireny v intervalech cca 240ms        
sirbeep decf timsir, F
		btfss STATUS, Z
		return
		bcf STATUS, C
		rrf cassir, F ;otaci az v 0 bude 1, pak timer sireny nevnima
		bcf PCLATH,4
		bsf PCLATH,3 ;Select page 1
		call sirena ;neguje houkani sireny
		bcf PCLATH,4
		bcf PCLATH,3 ;Select page 0
		movlw .8 ;nasavy na dalsich 240ms
		movwf timsir
		return
;vypnuti varovek
varoff	decf timvar, F
		btfss STATUS, Z
		return
		bcf o_e, 4 ;vypne levy i pravy blinkr
        bcf PORTD, 6
        bcf o_e, 5
        bcf PORTD, 7
        bcf casov, VAROV ;timer varovek nebude vniman
		return
;vypnuti red tuning
rtuoff	decf timrtu, F
		btfss STATUS, Z
		return
		bcf o_c, 2 ;vypne red tunning
        movlw b'10110' ;port C6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call clrout ;smaz port v prc
		bcf casov, REDTUN ;timer red tunningu nebude vniman
		return
;blikani led zamknuto		
lzabli	decf timlza, F
		btfss STATUS, Z
		return
		bcf PCLATH,4
		bsf PCLATH,3 ;Select page 1
		call ledzam ;neguje led zamknuto
		bcf PCLATH,4
		bcf PCLATH,3 ;Select page 0
		movlw .15 ;nasavy na dalsich 240ms
		movwf timlza
		return
;vypnuti white tuning
wtuoff	decf timwtu, F
		btfss STATUS, Z
		return
		bcf o_c, 3 ;vypne red tunning
        movlw b'10111' ;port C7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call clrout ;smaz port v prc
		bcf casov, WHITUN ;timer red tunningu nebude vniman
		return
;vypnuti polohy 3 spinacky
spioff	decf timspi, F
		btfss STATUS, Z
		return
		call t1_03
		return
;vypnuti odskok�
odsoff	decf timods, F
		btfss STATUS, Z
		return
		bcf o_b, 4
		bcf PORTA, 4
		bcf o_b, 5
		bcf PORTC, 7
		bcf o_b, 6
		bcf PORTB, 2
		bcf o_b, 7
		bcf PORTB, 3
		bcf o_b, 3
		bcf PORTB, 4
		bcf o_e, 0
		bcf PORTB, 5
		bcf o_c, 0
		bcf PORTB, 6
		
		bcf o_e, 7
		movlw b'11110' ;port D6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call clrout ;nastav port v prc
		bcf o_e, 6
		movlw b'11100' ;port D4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call clrout ;nastav port v prc
		bcf o_f, 5
		movlw b'11101' ;port D5
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call clrout ;nastav port v prc
		bcf o_f, 0
		movlw b'11111' ;port D7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call clrout ;nastav port v prc
		
        bcf casov, ODSKOK ;timer red tunningu nebude vniman
		return




inton   bcf INTCON, INTF	; nastaven� p�eru�en� od RB0        
        bsf INTCON, INTE
        bcf INTCON, T0IF ;nastaven� p�eru�en� od Timer0
        bsf INTCON, T0IE
        bsf INTCON, GIE
        return
        
intoff  bcf INTCON, INTE
		bcf INTCON, T0IE
        return
        


        
        
dotaz   bsf PORTB, 1  ;start bity XX - 10
        call w100c
        bcf PORTB, 1
        call w100c
        
        movf cil, W   ;vysila oznaceni cilov�ho procesoru XXXX
        movwf r1
        movlw .4
        movwf r2
        btfsc r1, 3
        bsf PORTB, 1
        btfss r1, 3
        bcf PORTB, 1
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        movlw b'00000000'   ;vysila nuly aby dostal odpoved XXXXXXX - 0000000
        movwf r1
        movlw .7
        movwf r2
        btfsc r1, 6
        bsf PORTB, 1
        btfss r1, 6
        bcf PORTB, 1
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 1  ;STOP bity XXX - 111
        call w100c
        call w100c
        call w100c
        bcf PORTB, 1
        
        
        bsf STATUS, RP0  ;Bank 1
        bsf TRISB, 1  ;nastavim sbernici na vstup do procesoru
        bcf STATUS, RP0  ;Bank 0
        
        btfss PORTB, 1  ;ceka az zacne vysilat signal
        goto $-1
        btfsc PORTB, 1  ;ceka az skonci prvni start bit X - 1
        goto $-1
        
        call w40c   ;posune do prostred signalu X - 0
        call w100c
        
        clrf pri0        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri0, F
        btfsc PORTB, 1
        bsf pri0, 0
        btfss PORTB, 1
        bcf pri0, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
        goto $-1
        call w40c
        call w100c
        
        
        clrf pri1        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri1, F
        btfsc PORTB, 1
        bsf pri1, 0
        btfss PORTB, 1
        bcf pri1, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
        goto $-1
        call w40c
        call w100c
        
        
        clrf pri2        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri2, F
        btfsc PORTB, 1
        bsf pri2, 0
        btfss PORTB, 1
        bcf pri2, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
        goto $-1
        call w40c
        call w100c
        
        
        clrf pri3        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri3, F
        btfsc PORTB, 1
        bsf pri3, 0
        btfss PORTB, 1
        bcf pri3, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
        goto $-1
        call w40c
        call w100c
        
        
        clrf pri4        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri4, F
        btfsc PORTB, 1
        bsf pri4, 0
        btfss PORTB, 1
        bcf pri4, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
        goto $-1
        call w40c
        call w100c
        
        
        clrf pri5        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri5, F
        btfsc PORTB, 1
        bsf pri5, 0
        btfss PORTB, 1
        bcf pri5, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
        goto $-1
        call w40c
        call w100c
        
        
        clrf pri6        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri6, F
        btfsc PORTB, 1
        bsf pri6, 0
        btfss PORTB, 1
        bcf pri6, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
        goto $-1
        call w40c
        call w100c
        
        
        clrf pri7        ; ulozi priijate do pri XXXX XXXX
        movlw .8
        movwf r2
        rlf pri7, F
        btfsc PORTB, 1
        bsf pri7, 0
        btfss PORTB, 1
        bcf pri7, 0
        call w100c
        decfsz r2, F
        goto $-7
        
        btfsc PORTB, 1  ;ceka az skonci STOP bity XXX - 111
        goto $-1
        
        
        bsf STATUS, RP0  ;Bank 1
        bcf TRISB, 1  ;nastavim sbernici na vystup z procesoru
        bcf STATUS, RP0  ;Bank 0
        call w20i
        return
        
        
setout  bsf PORTB, 1  ;start bity XX - 10
        call w100c
        bcf PORTB, 1
        call w100c
        
        movf prc, W   ;vysila oznaceni cilov�ho procesoru XXXX
        movwf r1
        movlw .4
        movwf r2
        btfsc r1, 3
        bsf PORTB, 1
        btfss r1, 3
        bcf PORTB, 1
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 1    ;vysle 1 jako ze vysila pozadavek na zmenu portu
        call w100c
        
        movf port, W   ;vysila port ke zmene XXXXX
        movwf r1
        movlw .5
        movwf r2
        btfsc r1, 4
        bsf PORTB, 1
        btfss r1, 4
        bcf PORTB, 1
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 1  ;vysle hodnotu 1
        call w100c
        
        bsf PORTB, 1  ;STOP bity XXX - 111
        call w100c
        call w100c
        call w100c
        bcf PORTB, 1
        call w20i
        return

clrout  bsf PORTB, 1  ;start bity XX - 10
        call w100c
        bcf PORTB, 1
        call w100c
        
        movf prc, W   ;vysila oznaceni cilov�ho procesoru XXXX
        movwf r1
        movlw .4
        movwf r2
        btfsc r1, 3
        bsf PORTB, 1
        btfss r1, 3
        bcf PORTB, 1
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 1    ;vysle 1 jako ze vysila pozadavek na zmenu portu
        call w100c
        
        movf port, W   ;vysila port ke zmene XXXXX
        movwf r1
        movlw .5
        movwf r2
        btfsc r1, 4
        bsf PORTB, 1
        btfss r1, 4
        bcf PORTB, 1
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bcf PORTB, 1  ;vysle hodnotu 0
        call w100c
        
        bsf PORTB, 1  ;STOP bity XXX - 111
        call w100c
        call w100c
        call w100c
        bcf PORTB, 1
        call w20i
        return
        
        
        ;podprogrami
             ;Tla�itka funkci 1
if_58   btfsc o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
        return
        bcf STATUS, C
        rrf ir_58, W
        movwf r1
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, F
        movlw b'11100000'
        iorwf r1, F
        
        movf r1, W    ;zkontroluje jestli nebylo uz minule
        movwf r4
        movf tl1, W
        xorwf r4, F
        btfsc STATUS, Z
        return
        movf r1, W    ;ulozi aktualni tlacitko
        movwf tl1
        
        incf r1, F
        btfsc STATUS, Z
        call t1_06
        incf r1, F
        btfsc STATUS, Z
        call t1_02
        incf r1, F
        btfsc STATUS, Z
        call t1_03
        incf r1, F
        btfsc STATUS, Z
        call t1_05
        incf r1, F
        btfsc STATUS, Z
        call t1_43
        incf r1, F
        btfsc STATUS, Z
        call t1_42
        incf r1, F
        btfsc STATUS, Z
        call t1_07
        incf r1, F
        btfsc STATUS, Z
        call t1_08
        incf r1, F
        btfsc STATUS, Z
        call t1_14
        incf r1, F
        btfsc STATUS, Z
        call t1_15
        incf r1, F
        btfsc STATUS, Z
        call t1_37
        incf r1, F
        btfsc STATUS, Z
        call t1_10
        incf r1, F
        btfsc STATUS, Z
        call t1_12
        incf r1, F
        btfsc STATUS, Z
        call t1_30
        incf r1, F
        btfsc STATUS, Z
        call t1_34
        incf r1, F
        btfsc STATUS, Z
        call t1_32
        incf r1, F
        btfsc STATUS, Z
        call t1_36
        ;pokud je tlacitko prave pusteno
        bcf STATUS, C
        rrf ir_58, W
        movwf r1
        movf r1, W
        btfsc STATUS, Z
        call t1_stop
        return
             ;Tla�itka funkci 2
if_62   btfsc o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
        return
        bcf STATUS, C
        rrf ir_62, W
        movwf r1
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, F
        movlw b'11100000'
        iorwf r1, F
        
        movf r1, W    ;zkontroluje jestli nebylo uz minule
        movwf r4
        movf tl2, W
        xorwf r4, F
        btfsc STATUS, Z
        return
        movf r1, W    ;ulozi aktualni tlacitko
        movwf tl2

        incf r1, F
        btfsc STATUS, Z
        call t1_04
        incf r1, F
        btfsc STATUS, Z
        call t1_56
        incf r1, F
        btfsc STATUS, Z
        call t1_16
        incf r1, F
        btfsc STATUS, Z
        call t1_26
        incf r1, F
        btfsc STATUS, Z
        call t1_44
        incf r1, F
        btfsc STATUS, Z
        call t1_11
        incf r1, F
        btfsc STATUS, Z
        call t1_13
        incf r1, F
        btfsc STATUS, Z
        call t1_54
        incf r1, F
        btfsc STATUS, Z
        call t1_41
        incf r1, F
        btfsc STATUS, Z
        call t1_62
        incf r1, F
        btfsc STATUS, Z
        call t1_40
        incf r1, F
        btfsc STATUS, Z
        call t1_61
        incf r1, F
        btfsc STATUS, Z
        call t1_31
        incf r1, F
        btfsc STATUS, Z
        call t1_35
        incf r1, F
        btfsc STATUS, Z
        call t1_53
        incf r1, F
        btfsc STATUS, Z
        call t1_33
        incf r1, F
        btfsc STATUS, Z
        call t1_60
        ;pokud je tlacitko prave pusteno
        bcf STATUS, C
        rrf ir_62, W
        movwf r1
        movf r1, W
        btfsc STATUS, Z
        call t2_stop
        return
             ;Tla�itka imobilizeru
if_50   nop
        return
             ;pasy
if_59   nop
        return
             ;rychlost
if_60   nop
        return
             ;ot��ky
if_61   nop
        return
             ;teplota in set
if_49   nop
        return
             ;alarm senzory
if_80   nop
        return
             ;baterie
if_51   nop
        return
             ;teplota in
if_52   nop
        return
             ;teplota eng
if_53   nop
        return
             ;palivo
if_54   nop
        return
             ;dve�e 1
if_55   nop
        return
             ;ru�n� brzda
if_56   nop
        return
             ;kvalt
if_57   nop
        return
             ;dve�e 2
if_84   nop
        return
             ;dve�e 3
if_85   nop
        return
             ;dve�e 4
if_86   nop
        return
             ;kapota
if_87   nop
        return
             ;kufr
if_88   nop
        return
             ;nadrz
if_89   nop
        return
             ;okno 1
if_90   nop
        return
             ;okno 2
if_91   nop
        return
             ;okno 3
if_92   nop
        return
             ;okno 4
if_93   nop
        return
             ;teplota OUT
if_127  nop
        return
             ;Tla��tka funkc� 3
if_128  btfsc o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
        nop;return ;po dokonceni vyvoje vratit return z duvodu bezpecnosti
        bcf STATUS, C
        rrf ir_128, W
        movwf r1
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, F
        movlw b'11100000'
        iorwf r1, F
        
        movf r1, W    ;zkontroluje jestli nebylo uz minule
        movwf r4
        movf tl3, W
        xorwf r4, F
        btfsc STATUS, Z
        return
        movf r1, W    ;ulozi aktualni tlacitko
        movwf tl3

        incf r1, F
        btfsc STATUS, Z
        call t1_47
        incf r1, F
        btfsc STATUS, Z
        call t1_00 ;prozatimne, je nutno odstranit po konci vyvoje
        incf r1, F
        btfsc STATUS, Z
        call t1_01 ;prozatimne, je nutno odstranit po konci vyvoje
        incf r1, F
        btfsc STATUS, Z
        call t1_20
        incf r1, F
        btfsc STATUS, Z
        call t1_21
        incf r1, F
        btfsc STATUS, Z
        call t1_22
        incf r1, F
        btfsc STATUS, Z
        call t1_23
        incf r1, F
        btfsc STATUS, Z
        call t1_24
        incf r1, F
        btfsc STATUS, Z
        call t1_25
        incf r1, F
        btfsc STATUS, Z
        call t1_45
        incf r1, F
        btfsc STATUS, Z
        call t1_46
        incf r1, F
        btfsc STATUS, Z
        call t1_50
        incf r1, F
        btfsc STATUS, Z
        call t1_51
        incf r1, F
        btfsc STATUS, Z
        call t1_52
        incf r1, F
        btfsc STATUS, Z
        call t1_53
        incf r1, F
        btfsc STATUS, Z
        call t1_55
        incf r1, F
        btfsc STATUS, Z
        call t1_x
        ;pokud je tlacitko prave pusteno
        bcf STATUS, C
        rrf ir_128, W
        movwf r1
        movf r1, W
        btfsc STATUS, Z
        call t3_stop
        return

;p�edp�ipraven� pro roz���en� procesoru 5 a vice
if_x    nop        
        return

;vypina holdovaci vystupy
t1_stop	nop
		return		
t2_stop	nop
		return		
t3_stop	nop
		call tx_stop	;odstranit po uspesnem naprogramovani DO
		return
tx_stop	movlw b'10000' ;port C0
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        btfsc o_d, 1
        call clrout ;nastav port v prc
		bcf o_d, 1
		movlw b'10001' ;port C1
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        btfsc o_d, 2
        call clrout ;nastav port v prc
		bcf o_d, 2
		movlw b'10010' ;port C2
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        btfsc o_d, 3
        call clrout ;nastav port v prc
		bcf o_d, 3
		movlw b'10011' ;port C3
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        btfsc o_d, 4
        call clrout ;nastav port v prc
		bcf o_d, 4
		movlw b'10100' ;port C4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        btfsc o_d, 5
        call clrout ;nastav port v prc
		bcf o_d, 5
		movlw b'10101' ;port C5
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        btfsc o_d, 6
        call clrout ;nastav port v prc
        bcf o_d, 6
			;blinkry
		bcf o_e, 4
		bcf PORTD, 6
		bcf o_e, 5
		bcf PORTD, 7
		
		movlw b'11001' ;port D1
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        btfsc o_c, 4
        call clrout ;nastav port v prc
        bcf o_c, 4
        
        bcf o_c, 7
        bcf PORTD, 3
        bcf o_c, 6
        bcf PORTD, 2
        
        movlw b'11000' ;port D0
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        btfsc o_e, 1
        call clrout ;nastav port v prc
        bcf o_e, 1
        
        bcf o_d, 0
        bcf PORTD, 4
        
        
        
		return
        
        
;zamknuti alarm on
t1_00   btfsc cassir, 0 ;pokud nyni pulsne houka sirena tak nelze provadet operaci
		return
		movf ir_55, W ;zkontroluje dvere, pokud jsou otevrene promluvy a 3x rychle zahraje sirenu
		iorwf ir_84, W
		iorwf ir_85, W
		iorwf ir_86, W
		iorwf ir_87, W
		iorwf ir_88, W
		iorwf ir_89, W
		movwf r6
		btfsc r6, 7
		nop ;MLUV "zkontrolujte vstupy do auta"
		btfsc r6, 7
		call sirena ;zapne sirenu
		btfsc r6, 7
		movlw b'00011111' ;nastavi do timeru ze houkne 3x po 200ms
		btfsc r6, 7
		movwf cassir
		btfsc r6, 7
		movlw .8
		btfsc r6, 7
		movwf timsir
		btfsc r6, 7
		return
		
		call t1_06 ;vypne vse
		bsf o_d, 7 ;zapne alarm cidla
		bsf PORTB, 7
			;zapne probliknuti nejakych svetel a sirenu a po urcitem case vypne, 
			;zatahne okna a pamatuje si polohu, zacne problikavat LED zamceno, promluvi ze je zamceno
		bsf o_e, 4 ;zapne levy i pravy blinkr a ty vypne po 2 sekundach - realizovano timerem
        bsf PORTD, 6
        bsf o_e, 5
        bsf PORTD, 7
        bsf casov, VAROV
		movlw .80
        movwf timvar
        bsf o_c, 2 ;problikne red tunning na 1 sekundu
        movlw b'10110' ;port C6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc 
        call setout ;set port v prc
        bsf casov, REDTUN ;do timeru ze po 1s vypne
		movlw .30
        movwf timrtu
        call sirena ;zahraje sirenou na 200ms
		movlw b'00000001' ;nastavi do timeru ze houkne 1x po 200ms
		movwf cassir
		movlw .8
		movwf timsir
		bcf o_f, 7 ;sklopi zrcatka neboli vypne
        bcf PORTE, 1
        nop ;MLUV "auto zam�eno"
		call t1_07 ;zamkne
		bsf casov, LEDZAM ;zapne problikavani LED zamceno po 500ms
		movlw .15
        movwf timlza
		
			;zatahnuti okenek
		movf ir_90, W ;ulozi si aktualni polohy okenek pro stazeni pri odemknuti
		movwf o1tmp
		movf ir_91, W
		movwf o2tmp
		movf ir_92, W
		movwf o3tmp
		movf ir_93, W
		movwf o4tmp
		movlw b'00000000' ;nastavy vyslednou polohu vsech okenek na same nuly (vytazene)
		movwf o1tar
		movwf o2tar
		movwf o3tar
		movwf o4tar
		 
        return
;odemknuti alarm off
t1_01   btfsc cassir, 0 ;pokud nyni pulsne houka sirena tak nelze provadet operaci
		return
		
		bcf o_d, 7 ;vypne alarm cidla
		bcf PORTB, 7
			;zapne probliknuti nejakych svetel a sirenu a po urcitem case vypne, STOP alarm
			;stahne okna do pamatovane polohy, prestane problikavat LED zamceno, promluvi ze je odemceno
		call t1_04
		bsf o_e, 4 ;zapne levy i pravy blinkr a ty vypne po 2 sekundach - realizovano timerem
        bsf PORTD, 6
        bsf o_e, 5
        bsf PORTD, 7
        bsf casov, VAROV
		movlw .80
        movwf timvar
        bsf o_c, 3 ;problikne white tunning na 1 sekundu
        movlw b'10111' ;port C7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc 
        call setout ;set port v prc
        bsf casov, WHITUN ;do timeru ze po 1s vypne
		movlw .30
        movwf timwtu
        call sirena ;zahraje sirenou na 200ms
		movlw b'00000111' ;nastavi do timeru ze houkne 2x po 200ms
		movwf cassir
		movlw .8
		movwf timsir
		bsf o_f, 7 ;odklopi zrcatka neboli zapne
        bsf PORTE, 1
        nop ;MLUV "auto odem�eno"
		bcf casov, LEDZAM ;zapne problikavani LED zamceno po 500ms
		call t1_08 ;odemkne
			
			;stahnuti okenek
		movf o1tmp, W
		movwf o1tar
		movf o2tmp, W
		movwf o2tar
		movf o3tmp, W
		movwf o3tar
		movf o4tmp, W
		movwf o4tar
		 
        return
;spinacka poloha up
t1_02   btfsc spinac, 2
		return
		bsf STATUS, C
		rlf spinac, F
			;pokud poloha 3
		btfss spinac, 2
		goto t2_02
		bcf o_a, 0
		bcf PORTC, 0
		bcf o_a, 1
		bcf PORTC, 1
		bsf o_i, 2
		movlw b'11010' ;port D2
        movwf port
        movlw b'11' ;procesor 3
        movwf prc 
        call setout ;set port v prc
		bsf o_i, 3
		movlw b'11011' ;port D3
        movwf port
        movlw b'11' ;procesor 3
        movwf prc 
        call setout ;set port v prc
        movlw .40 ;nastavi startovani pouze max na vterinu
        movwf timspi
        return
        	;pokud poloha 2
t2_02	btfss spinac, 1
		goto t3_02
		bsf o_a, 0
		bsf PORTC, 0
		bsf o_a, 2
		bsf PORTC, 2
		return
			;pokud poloha 1
t3_02	bsf o_a, 1
		bsf PORTC, 1
        return
;spinacka poloha down
t1_03   btfss spinac, 0
		return
		bcf STATUS, C
		rrf spinac, F
			;pokud poloha 2
		btfss spinac, 1
		goto t2_03
		bsf o_a, 0
		bsf PORTC, 0
		bsf o_a, 1
		bsf PORTC, 1
		bcf o_i, 2
		movlw b'11010' ;port D2
        movwf port
        movlw b'11' ;procesor 3
        movwf prc 
        call clrout ;set port v prc
		bcf o_i, 3
		movlw b'11011' ;port D3
        movwf port
        movlw b'11' ;procesor 3
        movwf prc 
        call clrout ;set port v prc
        return
        	;pokud poloha 1
t2_03	btfss spinac, 0
		goto t3_03
		bcf o_a, 0
		bcf PORTC, 0
		bcf o_a, 2
		bcf PORTC, 2
		return
			;pokud poloha 0
t3_03	bcf o_a, 1
		bcf PORTC, 1
        return	
;alarm stop
t1_04   nop
        return
;varovna svetla
t1_05   clrf r2   ;pokud jeden nebo oba blinkry vyply - zapne verovky, opacne je vypne
        clrf r3
        btfsc o_e, 4
        bsf r2, 0
        btfsc o_e, 5
        bsf r3, 0
        movf r2, W
        andwf r3, F
        
        btfsc r3, 0 ;pokud oba zaply oba vypne
        bcf o_e, 4
        btfsc r3, 0 ;pokud oba zaply oba vypne
        bcf PORTD, 6
        btfsc r3, 0 ;pokud oba zaply oba vypne
        bcf o_e, 5
        btfsc r3, 0 ;pokud oba zaply oba vypne
        bcf PORTD, 7

        btfss r3, 0 ;pokud jeden vyply oba zapne
        bsf o_e, 4
        btfss r3, 0 ;pokud jeden vyply oba zapne
        bsf PORTD, 6
        btfss r3, 0 ;pokud jeden vyply oba zapne
        bsf o_e, 5
        btfss r3, 0 ;pokud jeden vyply oba zapne
        bsf PORTD, 7

        
        return
;vypnout vse
t1_06   nop
        return
;zamknuti
t1_07   bsf locked, 0 ;nastavi registr locked
        bcf o_h, 5 ;vypne v regs led odemceno
        movlw b'10101' ;port C5
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        call clrout ;smaz port v prc
        bsf o_h, 6 ;zapne v regs led zamceno
        movlw b'10110' ;port C6
        movwf port
        movlw b'0011' ;procesor 3
        movwf prc
        call setout ;nastav port v prc
        return
;odemknuti
t1_08   bcf locked, 0 ;smaze registr locked
        bsf o_h, 5 ;zapne v regs led odemceno
        movlw b'10101' ;port C5
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        call setout ;nastav port v prc
        bsf o_h, 6 ;vypne v regs led zamceno
        movlw b'10110' ;port C6
        movwf port
        movlw b'0011' ;procesor 3
        movwf prc
        call clrout ;smaz port v prc
        return
;pripraveno
t1_09   nop
        return

        
;odskok dvere 1
t1_10   bsf o_b, 4
		bsf PORTA, 4
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;odskok dvere 2
t1_11   bsf o_b, 5
		bsf PORTC, 7
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;odskok dvere 3
t1_12   btfsc o_i, 4
		return
		bsf o_b, 6
		bsf PORTB, 2
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;odskok dvere 4
t1_13   btfsc o_i, 4
		return
		bsf o_b, 7
		bsf PORTB, 3
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;odskok kufr
t1_14   bsf o_b, 3
		bsf PORTB, 4
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;odskok nadrz
t1_15   bsf o_e, 0
		bsf PORTB, 5
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;odskok kapota
t1_16   bsf o_c, 0
		bsf PORTB, 6
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;pripraveno
t1_17   nop
        return
;pripraveno
t1_18   nop
        return
;pripraveno
t1_19   nop
        return

        
;play pause
t1_20   bsf o_d, 1
		movlw b'10000' ;port C0
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		return
;stop
t1_21   bsf o_d, 2
		movlw b'10001' ;port C1
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		return
;forwind
t1_22   bsf o_d, 3
		movlw b'10010' ;port C2
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		return
;rewind
t1_23   bsf o_d, 4
		movlw b'10011' ;port C3
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		return
;volume +
t1_24   bsf o_d, 5
		movlw b'10100' ;port C4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		return
;volume -
t1_25   bsf o_d, 6
		movlw b'10101' ;port C5
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		return
;rozehrivani okenka
t1_26   movf o_f, W
        movwf r5
		
		btfss r5, 2
		bsf PORTC, 5
		btfss r5, 2
		bsf o_f, 2 
        
		btfsc r5, 2
		bcf PORTC, 5
        btfsc r5, 2
		bcf o_f, 2 
        return
;pripraveno
t1_27   nop
        return
;pripraveno
t1_28   nop
        return
;pripraveno
t1_29   nop
        return

        
;okno 1 up
t1_30   movf o1tar, W
		movwf r5
		movlw b'11110000' ;odecte od cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfss STATUS, C
		return
		movf r5, W
		movwf o1tar
        return
;okno 2 up
t1_31   movf o2tar, W
		movwf r5
		movlw b'11110000' ;odecte od cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfss STATUS, C
		return
		movf r5, W
		movwf o2tar
        return
;okno 3 up
t1_32   btfsc o_i, 4
		return
		movf o3tar, W
		movwf r5
		movlw b'11110000' ;odecte od cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfss STATUS, C
		return
		movf r5, W
		movwf o3tar
        return
;okno 4 up
t1_33   btfsc o_i, 4
		return
		movf o4tar, W
		movwf r5
		movlw b'11110000' ;odecte od cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfss STATUS, C
		return
		movf r5, W
		movwf o4tar
        return
;okno 1 down
t1_34   movf o1tar, W
		movwf r5
		movlw b'00010000' ;pricte k cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfsc STATUS, C
		return
		movf r5, W
		movwf o1tar
        return
;okno 2 down
t1_35   movf o2tar, W
		movwf r5
		movlw b'00010000' ;pricte k cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfsc STATUS, C
		return
		movf r5, W
		movwf o2tar
        return
;okno 3 down
t1_36   btfsc o_i, 4
		return
		movf o3tar, W
		movwf r5
		movlw b'00010000' ;pricte k cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfsc STATUS, C
		return
		movf r5, W
		movwf o3tar
        return
;detsk� z�mek zadn�ch oken a dveri
t1_37   btfss o_i, 4 ;zmeni stav indikace detskeho zamku
		goto t2_37
		bcf o_i, 4
		movlw b'11100' ;port D4
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        call clrout ;nastav port v prc        
		return
t2_37	bsf o_i, 4
		movlw b'11100' ;port D4
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        call setout ;nastav port v prc        
		return
;pripraveno
t1_38   nop
        return
;pripraveno
t1_39   nop
        return

        
;RED tuning
t1_40   movlw b'10110' ;port C6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        movf o_c, W
        movwf r5
		
		btfss r5, 2
		call setout ;nastav port v prc
		btfss r5, 2
		bsf o_c, 2 
        
		btfsc r5, 2
		call clrout ;smaz port v prc
        btfsc r5, 2
		bcf o_c, 2 
		return
;WHITE tunning
t1_41   movlw b'10111' ;port C7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        movf o_c, W
        movwf r5
		
		btfss r5, 3
		call setout ;nastav port v prc
		btfss r5, 3
		bsf o_c, 3 
        
		btfsc r5, 3
		call clrout ;smaz port v prc
        btfsc r5, 3
		bcf o_c, 3 
		return
;Parkova�ky
t1_42   movf o_e, W
        movwf r5
		
		btfss r5, 3
		bsf PORTD, 5
		btfss r5, 3
		bsf o_e, 3 
        
		btfsc r5, 3
		bcf PORTD, 5
        btfsc r5, 3
		bcf o_e, 3 
		return
;Sv�tla
t1_43   movf o_c, W
        movwf r5
		
		btfss r5, 1
		bsf PORTC, 3
		btfss r5, 1
		bsf o_c, 1 
        
		btfsc r5, 1
		bcf PORTC, 3
        btfsc r5, 1
		bcf o_c, 1 
		return
;Mlhovky zadn�
t1_44   movf o_f, W
        movwf r5
		
		btfss r5, 1
		bsf PORTC, 4
		btfss r5, 1
		bsf o_f, 1 
        
		btfsc r5, 1
		bcf PORTC, 4
        btfsc r5, 1
		bcf o_f, 1 
		return
;Blinkr lev�
t1_45   bsf o_e, 4
		bsf PORTD, 6
        return
;Blinkr prav�
t1_46   bsf o_e, 5
		bsf PORTD, 7
        return
;Mlhovky p�edn�
t1_47   movf o_c, W
        movwf r5
		
		btfss r5, 5
		bsf PORTD, 1
		btfss r5, 5
		bsf o_c, 5 
        
		btfsc r5, 5
		bcf PORTD, 1
        btfsc r5, 5
		bcf o_c, 5 
		return
;pripraveno
t1_48   nop
        return
;pripraveno
t1_49   nop
        return

        
;klakson
t1_50   bsf o_c, 4
		movlw b'11001' ;port D1
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        call setout ;nastav port v prc
        return
;st�ra�e
t1_51   bsf o_c, 7
		bsf PORTD, 3
        return
;odst�ikova�e
t1_52   bsf o_c, 6
		bsf PORTD, 2
        return
;Sir�na
t1_53   bsf o_e, 1
		movlw b'11000' ;port D0
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        call setout ;nastav port v prc
        return
;stroboskop
t1_54   movlw b'11001' ;port D1
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        movf o_e, W
        movwf r5
		
		btfss r5, 2
		call setout ;nastav port v prc
		btfss r5, 2
		bsf o_e, 2 
        
		btfsc r5, 2
		call clrout ;smaz port v prc
        btfsc r5, 2
		bcf o_e, 2 
		return
;D�lkov� sv�tla
t1_55   bsf o_d, 0
		bsf PORTD, 4
        return
;alarm start
t1_56   nop
        return
;pripraveno
t1_57   nop
        return
;pripraveno
t1_58   nop
        return
;pripraveno
t1_59   nop
        return

        
;okno 4 down
t1_60   btfsc o_i, 4
		return
		movf o4tar, W
		movwf r5
		movlw b'00010000' ;pricte k cilove polohy 1/16tinu celeho okna
		addwf r5, F
		btfsc STATUS, C
		return
		movf r5, W
		movwf o4tar
        return
;red interi�r
t1_61   movlw b'11010' ;port D2
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        movf o_f, W
        movwf r5
		
		btfss r5, 3
		call setout ;nastav port v prc
		btfss r5, 3
		bsf o_f, 3 
        
		btfsc r5, 3
		call clrout ;smaz port v prc
        btfsc r5, 3
		bcf o_f, 3 
		return
;white interier
t1_62   movlw b'11011' ;port D3
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        movf o_f, W
        movwf r5
		
		btfss r5, 4
		call setout ;nastav port v prc
		btfss r5, 4
		bsf o_f, 4 
        
		btfsc r5, 4
		call clrout ;smaz port v prc
        btfsc r5, 4
		bcf o_f, 4 
		return
;klima on/off
t1_63   bsf o_e, 7
		movlw b'11110' ;port D6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;klima teplota up
t1_64   bsf o_e, 6
		movlw b'11100' ;port D4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;klima teplota down
t1_65   bsf o_f, 5
		movlw b'11101' ;port D5
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;klima mista ventilace
t1_66   bsf o_f, 0
		movlw b'11111' ;port D7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        call setout ;nastav port v prc
		bsf casov, ODSKOK
		movlw .8
		movwf timods
        return
;pripraveno
t1_67   nop
        return
;pripraveno
t1_68   nop
        return
;pripraveno
t1_69   nop
        return


t1_x    nop
        return
        











w20i    movlw .5
        movwf r4
        decfsz r4, F
        goto $-1
        return
        

        
        ;cekej cca 100 cyklu 40us  + u kazdeho cekani je 7 cyklu povinych
w100c   movlw .80
        movwf r4
        decfsz r4, F
        goto $-1
        return

          ;cekej necelou polovinu w100c
w40c   movlw .30
        movwf r4
        decfsz r4, F
        goto $-1
        return




		
;obslouzeni okynek, (vy)stahuje v z�vislosti na aktualni a cilov� poloze
okna	movf ir_90, W
		andlw b'11110000' ;odseknu konecnou cast	
		movwf r1
		comf r1, F ;udel�m dvojkov� dopln�k
		movf o1tar, W
		andlw b'11110000' ;odseknu konecnou cast
		addwf r1, F ;sectu s dvojkovym doplnkem
		movf STATUS, W
		movwf r3
		btfsc r3, Z
		call o1stop
		btfsc r3, Z
		goto okno2
		btfss r3, C ;pokud nepreteklo, vyjed nahoru
		call o1up
		btfsc r3, C ;pokud preteklo, sjed dolu
		call o1down		
okno2	movf ir_91, W
		andlw b'11110000' ;odseknu konecnou cast	
		movwf r1
		comf r1, F ;udel�m dvojkov� dopln�k
		movf o2tar, W
		andlw b'11110000' ;odseknu konecnou cast
		addwf r1, F ;sectu s dvojkovym doplnkem
		movf STATUS, W
		movwf r3
		btfsc r3, Z
		call o2stop
		btfsc r3, Z
		goto okno3
		btfss r3, C ;pokud nepreteklo, vyjed nahoru
		call o2up
		btfsc r3, C ;pokud preteklo, sjed dolu
		call o2down
okno3	movf ir_92, W
		andlw b'11110000' ;odseknu konecnou cast	
		movwf r1
		comf r1, F ;udel�m dvojkov� dopln�k
		movf o3tar, W
		andlw b'11110000' ;odseknu konecnou cast
		addwf r1, F ;sectu s dvojkovym doplnkem
		movf STATUS, W
		movwf r3
		btfsc r3, Z
		call o3stop
		btfsc r3, Z
		goto okno4
		btfss r3, C ;pokud nepreteklo, vyjed nahoru
		call o3up
		btfsc r3, C ;pokud preteklo, sjed dolu
		call o3down
okno4	movf ir_93, W
		andlw b'11110000' ;odseknu konecnou cast	
		movwf r1
		comf r1, F ;udel�m dvojkov� dopln�k
		movf o4tar, W
		andlw b'11110000' ;odseknu konecnou cast
		addwf r1, F ;sectu s dvojkovym doplnkem
		movf STATUS, W
		movwf r3
		btfsc r3, Z
		call o4stop
		btfsc r3, Z
		return
		btfss r3, C ;pokud nepreteklo, vyjed nahoru
		call o4up
		btfsc r3, C ;pokud preteklo, sjed dolu
		call o4down	
		return

;okno 1 nahoru, dolu, zastavit
o1up	btfsc o_a, 3
		goto no1up
		movlw b'00100' ;port A4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_a, 3 
no1up	btfss o_a, 7
		return
		movlw b'01100' ;port B4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 7 		
        return
o1down	btfss o_a, 3
		goto no1down
		movlw b'00100' ;port A4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 3 
no1down	btfsc o_a, 7
		return
		movlw b'01100' ;port B4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_a, 7 		
        return
o1stop	btfss o_a, 3
		goto no1stop
		movlw b'00100' ;port A4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 3 
no1stop	btfss o_a, 7
		return
		movlw b'01100' ;port B4
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 7 		
        return
;okno 2 nahoru, dolu, zastavit
o2up	btfsc o_a, 4
		goto no2up
		movlw b'11000' ;port D0
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_a, 4 
no2up	btfss o_b, 0
		return
		movlw b'01101' ;port B5
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_b, 0 		
        return
o2down	btfss o_a, 4
		goto no2down
		movlw b'11000' ;port D0
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 4 
no2down	btfsc o_b, 0
		return
		movlw b'01101' ;port B5
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_b, 0 		
        return
o2stop	btfss o_a, 4
		goto no2stop
		movlw b'11000' ;port D0
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 4 
no2stop	btfss o_b, 0
		return
		movlw b'01101' ;port B5
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_b, 0 		
        return
;okno 3 nahoru, dolu, zastavit
o3up	btfsc o_a, 5
		goto no3up
		movlw b'01010' ;port B2
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_a, 5 
no3up	btfss o_b, 1
		return
		movlw b'01110' ;port B6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_b, 1 		
        return
o3down	btfss o_a, 5
		goto no3down
		movlw b'01010' ;port B2
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 5 
no3down	btfsc o_b, 1
		return
		movlw b'01110' ;port B6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_b, 1 		
        return
o3stop	btfss o_a, 5
		goto no3stop
		movlw b'01010' ;port B2
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 5 
no3stop	btfss o_b, 1
		return
		movlw b'01110' ;port B6
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_b, 1 		
        return
;okno 4 nahoru, dolu, zastavit
o4up	btfsc o_a, 6
		goto no4up
		movlw b'01011' ;port B3
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_a, 6 
no4up	btfss o_b, 2
		return
		movlw b'01111' ;port B7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_b, 2 		
        return
o4down	btfss o_a, 6
		goto no4down
		movlw b'01011' ;port B3
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 6 
no4down	btfsc o_b, 2
		return
		movlw b'01111' ;port B7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call setout ;smaz port v prc
		bsf o_b, 2 		
        return
o4stop	btfss o_a, 6
		goto no4stop
		movlw b'01011' ;port B3
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_a, 6 
no4stop	btfss o_b, 2
		return
		movlw b'01111' ;port B7
        movwf port
        movlw b'10' ;procesor 2
        movwf prc
        
        call clrout ;smaz port v prc
		bcf o_b, 2 		
        return


;zmeni stav sireny
sirena  movlw b'11000' ;port D0
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        
        movf o_e, W
        movwf r5
		
		btfss r5, 1
		call setout ;nastav port v prc
		btfss r5, 1
		bsf o_e, 1 
        
		btfsc r5, 1
		call clrout ;smaz port v prc
        btfsc r5, 1
		bcf o_e, 1 
        
		return

;zmeni stav LED zamceno
ledzam  movlw b'10110' ;port C6
        movwf port
        movlw b'11' ;procesor 3
        movwf prc
        
        movf o_h, W
        movwf r5
		
		btfss r5, 6
		call setout ;nastav port v prc
		btfss r5, 6
		bsf o_h, 6 
        
		btfsc r5, 6
		call clrout ;smaz port v prc
        btfsc r5, 6
		bcf o_h, 6 
        
		return












		org 800h ;zacina druha stranka programu
start   btfsc conf, T0OF ;pokud timer 0 p�etekl, spust� jeho obsluhu
		bcf PCLATH,4
		bcf PCLATH,3 ;Select page 0
		
		call timer0
		
		call okna ;spou�t� obsluhu jednotliv�ch ok�nek
		
		movlw b'00000101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_58, W
        addwf r1, F
        movf ADRESH, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_58  ;prepise reg AN prevedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_58  ;pokud zmena odesle na sbernici

        movlw b'00001101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_62, W
        addwf r1, F
        movf ADRESH, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_62  ;prepise reg AN prevedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_62  ;pokud zmena odesle na sbernici

        movlw b'00010101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_50, W
        addwf r1, F
        movf ADRESH, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_50  ;prepise reg AN prevedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_50  ;pokud zmena odesle na sbernici

        movlw b'00011101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_59, W
        addwf r1, F
        movf ADRESH, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_59  ;prepise reg AN prevedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_59  ;pokud zmena odesle na sbernici

        movlw b'00100101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_60, W
        addwf r1, F
        movf ADRESH, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_60  ;prepise reg AN prevedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_60  ;pokud zmena odesle na sbernici

        movlw b'00101101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_61, W
        addwf r1, F
        movf ADRESH, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_61  ;prepise reg AN prevedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_61  ;pokud zmena odesle na sbernici





                ;dotaz na procesor 2
        movlw .2  ;oznaceni ciloveho procesoru
        movwf cil
        call dotaz  ;prijem dat z procesoru do pri0 - pri7

        movf pri0, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_51, W
        addwf r1, F
        movf pri0, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_51  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_51  ;pokud zmena spusti podprig

        movf pri1, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_52, W
        addwf r1, F
        movf pri1, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_52  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_52  ;pokud zmena spusti podprig

        movf pri2, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_53, W
        addwf r1, F
        movf pri2, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_53  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_53  ;pokud zmena spusti podprig

        movf pri3, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_54, W
        addwf r1, F
        movf pri3, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_54  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_54  ;pokud zmena spusti podprig

        movf pri4, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_55, W
        addwf r1, F
        movf pri4, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_55  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_55  ;pokud zmena spusti podprig

        movf pri5, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_56, W
        addwf r1, F
        movf pri5, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_56  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_56  ;pokud zmena spusti podprig

        movf pri6, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_57, W
        addwf r1, F
        movf pri6, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_57  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_57  ;pokud zmena spusti podprig

        movf pri7, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_49, W
        addwf r1, F
        movf pri7, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_49  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_49  ;pokud zmena spusti podprig





                ;dotaz na procesor 3
        movlw .3  ;oznaceni ciloveho procesoru
        movwf cil
        call dotaz  ;prijem dat z procesoru do pri0 - pri7

        movf pri0, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_80, W
        addwf r1, F
        movf pri0, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_80  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_80  ;pokud zmena spusti podprig

        movf pri1, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_84, W
        addwf r1, F
        movf pri1, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_84  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_84  ;pokud zmena spusti podprig

        movf pri2, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_85, W
        addwf r1, F
        movf pri2, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_85  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_85  ;pokud zmena spusti podprig

        movf pri3, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_86, W
        addwf r1, F
        movf pri3, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_86  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_86  ;pokud zmena spusti podprig

        movf pri4, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_87, W
        addwf r1, F
        movf pri4, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_87  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_87  ;pokud zmena spusti podprig

        movf pri5, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_88, W
        addwf r1, F
        movf pri5, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_88  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_88  ;pokud zmena spusti podprig

        movf pri6, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_89, W
        addwf r1, F
        movf pri6, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_89  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_89  ;pokud zmena spusti podprig

        movf pri7, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_90, W
        addwf r1, F
        movf pri7, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_90  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_90  ;pokud zmena spusti podprig





                ;dotaz na procesor 4
        movlw .4  ;oznaceni ciloveho procesoru
        movwf cil
        call dotaz  ;prijem dat z procesoru do pri0 - pri7

        movf pri0, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_91, W
        addwf r1, F
        movf pri0, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_91  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_91  ;pokud zmena spusti podprig

        movf pri1, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_92, W
        addwf r1, F
        movf pri1, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_92  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_92  ;pokud zmena spusti podprig

        movf pri2, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_93, W
        addwf r1, F
        movf pri2, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_93  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_93  ;pokud zmena spusti podprig

        movf pri3, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_127, W
        addwf r1, F
        movf pri3, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_127  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_127  ;pokud zmena spusti podprig

        movf pri4, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_128, W
        addwf r1, F
        movf pri4, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_128  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_128  ;pokud zmena spusti podprig

        movf pri5, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_x, W
        addwf r1, F
        movf pri5, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_x  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_x  ;pokud zmena spusti podprig

        movf pri6, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_x, W
        addwf r1, F
        movf pri6, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_x  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_x  ;pokud zmena spusti podprig

        movf pri7, W    ;kontroluje zda je zmena od minule
        movwf r1
        comf ir_x, W
        addwf r1, F
        movf pri7, W
        incfsz r1, F  ;pokud zadna zmena pokracuje dal
        movwf ir_x  ;priepise reg AN prievedenou hodnotou
        movf r1, W
        btfss STATUS, Z
        call if_x  ;pokud zmena spusti podprig


        bcf PCLATH,4
		bsf PCLATH,3 ;Select page 1
		goto start      ;zpet v cyklu na zacatek
        


        end                                           ; KONEC PROGRAMU
