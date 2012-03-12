

 LIST	   P=16F874A, R=DEC
 INCLUDE  <P16F874.INC>

                  ;deklarace registru
r1      equ 20h
r2      equ 21h
r3      equ 22h
r4      equ 23h

cil     equ 24h
port    equ 25h
cislo   equ 26h

r5      equ 27h

w_temp  equ 2Bh
s_temp  equ 2Ch

num     equ 30h

an0     equ 31h
an1     equ 32h
an2     equ 33h
an3     equ 34h
an4     equ 35h
an5     equ 36h
an6     equ 37h
an7     equ 38h

CIS1_L      equ 39h
CIS1_H      equ 3Ah
CIS2_L      equ 3Bh
CIS2_H      equ 3Ch
L_BYTE      equ 3Dh
H_BYTE      equ 3Eh
OUT_L       equ 3Fh
OUT_H       equ 40h
A1    equ 41h
A2    equ 42h
A3    equ 43h
B1    equ 44h
B2    equ 45h
B3    equ 46h
C1    equ 47h
C2    equ 48h
C3    equ 49h
D1    equ 4Ah
D2    equ 4Bh
D3    equ 4Ch
X1    equ 4Dh
X2    equ 4Eh
FL    equ 4Fh


conf        equ 7Ch

;KONSTANTY
;conf constant
WATCHOVER   equ .2



        org 000h        ;vektor zacatku
        goto init

        org 004h        ;vektor preruseni
        goto inter




init    movlw .4    ;oznaceni tohoto procesoru
        movwf num

        clrf PORTA      ;Init PORTS
        clrf PORTB
        clrf PORTC
        clrf PORTD
        clrf PORTE
        

        bsf STATUS, RP0  ;Bank 1

        movlw b'01000000' ;0 left justifed, FOSC/2 na rychlost prevodu 0, 00, nastaveni analogových vstupu a hodnotu k porovnání 0000
        movwf ADCON1

        movlw	b'00101111'; 1 znamená vstup, 0 výstup
        movwf	TRISA
        movlw	b'00000001'
        movwf	TRISB
        movlw b'00000000'
        movwf TRISC
        movlw b'00000000'
        movwf TRISD
        movlw b'00000111'
        movwf TRISE
        
        movlw b'11000000'
        movwf OPTION_REG

        bcf STATUS, RP0 ;Bank 0

        movlw b'01000110' ; nastaví control register timer2
        movwf T2CON
        
        ; Zapne preruseni a to i pro com
        ;bsf INTCON, INTE
        ;call inton
        
        goto start      ;zacni na startu
        
        
intoff      bcf INTCON, INTE
            bsf STATUS, RP0  ;Bank 1
            bcf PIE1, TMR2IE
            bcf STATUS, RP0 ;Bank 0
            return

        
inton       bcf INTCON, INTF	; nastavení pøerušení od RB0        
            ;bsf INTCON, INTE
            bcf PIR1, TMR2IF ;nastavení pøerušení od Timer2
            bsf STATUS, RP0  ;Bank 1
            bsf PIE1, TMR2IE
            bcf STATUS, RP0 ;Bank 0
            bsf INTCON, PEIE
            bsf INTCON, GIE
            return
        

inter   call intoff
        movwf w_temp ;copy w to temp register
        swapf STATUS, W ;swap status to be saved into w
        clrf STATUS ;bank 0, regardless of current bank, clears irp,rp1,rp0
        movwf s_temp ;save status to bank zero status_temp register
        
        btfsc PIR1, TMR2IF      ;preruseni od timer2 watch
        call watchover

        swapf s_temp, W ;swap status_temp register into w
        movwf STATUS ;move w into status register;(sets bank to original state)
        swapf w_temp, F ;swap w_temp
        swapf w_temp, W ;
        call inton
        return
        
        
        
;pokud pøetekl timer2 pro watch
watchover   bsf conf, WATCHOVER
            bcf INTCON, INTF	; nastavení pøerušení od RB0        
            bsf INTCON, INTE
            ;bsf INTCON, GIE
            return
            
;Zapnutí stopek pro kontrolu zacyklení - timer2
watchstart  bcf conf, WATCHOVER ;nastavi jako nepreteceny
            bcf INTCON, INTF
            bcf PIR1, TMR2IF ;nastavení pøerušení od Timer2
            bsf STATUS, RP0  ;Bank 1
            bsf PIE1, TMR2IE
            bcf STATUS, RP0 ;Bank 0
            bsf INTCON, PEIE
            bsf INTCON, GIE
            clrf TMR2 ;vynuluje timer2
            return
            
watchwait   btfss conf, WATCHOVER
            goto $-1
            ; pro jistotu jeste pocka aby dobehly hodiny v ostatnich PRCS
            return



start    comf PORTB, F
      
        ;movlw .4 ;nastavime ANx kde x je zadane cislo
        ;movwf r1
        ;call adconv_one
        ;movf r1, W
        ;movwf an4
        
        movlw b'10100101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an4
        
        ;;;;;;;;;;;;;;;; DEBUG
        btfss an4, 0
        bcf PORTD, 1
        btfsc an4, 0
        bsf PORTD, 1
        
        btfss an4, 1
        bcf PORTD, 2
        btfsc an4, 1
        bsf PORTD, 2
        
        btfss an4, 2
        bcf PORTD, 3
        btfsc an4, 2
        bsf PORTD, 3
        
        btfss an4, 3
        bcf PORTC, 4
        btfsc an4, 3
        bsf PORTC, 4
        
        btfss an4, 4
        bcf PORTC, 5
        btfsc an4, 4
        bsf PORTC, 5
        
        btfss an4, 5
        bcf PORTC, 6
        btfsc an4, 5
        bsf PORTC, 6
        
        btfss an4, 6
        bcf PORTC, 7
        btfsc an4, 6
        bsf PORTC, 7
        
        btfss an4, 7
        bcf PORTD, 4
        btfsc an4, 7
        bsf PORTD, 4
        
        
        
        movlw .5
        movwf r2
        movlw .200
        movwf r3
        call w100c
        decfsz r3, F
        goto $-2
        decfsz r2, F
        goto $-4
        
        
        
        goto start      ;zpet v cyklu na zacatek
        
        
        
        
adconv      movlw .50 ; kolikrat se ma merit vstup
            movwf r2 ; decrementator pro cykl
            movwf r5 ; delitel pro vypocet prumeru
            movf r1, W
            movwf r3 ; zachováni ANx vstupu
            clrf CIS2_L
            clrf CIS2_H
            
adconv2     movf r3, W
            movwf r1 ; nasteni znova ANx vstupu
            call adconv_one
            
            ; pripraveni cisla 1 k pricteni
            clrf CIS1_H
            movf r1, W
            movwf CIS1_L
            
            ; Secte dve 16-bitova cisla do max. hodnoty vysledku FFFFh (65535d)
            ; CIS1_H, CIS1_L + CIS2_H, CIS2_L -> OUT_H a OUT_L
        
        	movf	CIS1_L,W	; CIS1_L do W
        	addwf	CIS2_L,W	; W + CIS2_L do W
        	movwf	OUT_L		; W do OUT_L
        
        	movf	CIS1_H,W	; CIS1_H do W
        	btfsc	STATUS,C
        	addlw	0x01		; C=1, scitani preteklo tak uloz 1 do W
        	addwf	CIS2_H,W
        	movwf	OUT_H		; W do OUT_H
        	
        	; ulozi OUT do CIS2
            movf OUT_L, W
            movwf CIS2_L
            movf OUT_H, W
            movwf CIS2_H
            
            
            decfsz r2, F
            goto adconv2
            
            ; vydeli poctem mereni
            movf CIS2_L, W
            movwf A1
            movf CIS2_H, W
            movwf A2
            clrf A3
            
            movf r5, W
            movwf B1
            clrf B2
            clrf B3
            
            call LOMENO24
            movf C1, W
            movwf r1
            
            return
        
adconv_one  bcf STATUS, C
            rlf r1, F
            rlf r1, F
            rlf r1, W
            movwf ADCON0
            ; ADCON0 REG     ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
            bcf ADCON0, 7
            bsf ADCON0, 6
            ; 5
            ; 4
            ; 3
            bsf ADCON0, 2
            ; 1
            bsf ADCON0, 0
            
            btfsc ADCON0, 2   ;ceka nez skonci AD prevod
            goto $-1
            movf ADRESH, W    ;kontroluje zda je zmena od minule
            movwf r1
            return
        
        
        
        
        
;-------------------------------;
; A1,2,3 / B1,2,3 = C1,2,3
;24Bit, pouze kladna cisla
;SZ=1=deleni nulou (B1,2,3=0)
;B se nezmeni, v A bude zbytek
;pouziva D1,2,3; X1
LOMENO24
;test B na nulu; sZ=1=ANO
	MOVF	B1,F
	BTFSC	STATUS,Z	;nenulove?
	MOVF	B2,F
	BTFSC	STATUS,Z	;nenulove?
	MOVF	B3,F
	BTFSC	STATUS,Z	;nenulove?
	RETURN			;B1,2,3=0
;priprava pro deleni
LOM24	MOVF	A1,W		;A do D
	MOVWF	D1		;
	MOVF	A2,W		;
	MOVWF	D2		;
	MOVF	A3,W		;
	MOVWF	D3		;
	CLRF	A1		;nulovat
	CLRF	A2		;
	CLRF	A3		;
	MOVLW	24		;pocet bitu
	MOVWF	X1		;
	BCF	STATUS,C	;SC=0
;deleni
LDalsi	CALL	x2M		;D,A posun vlevo, A-B=C
	BTFSS	STATUS,C	;kladny vysledek?
	GOTO	LZapor		;NE
;LKlad
	MOVWF	A3		;C do A
	MOVF	C2,W		;
	MOVWF	A2		;
	MOVF	C1,W		;
	MOVWF	A1		;

LZapor	DECFSZ	X1,F		;-1=0?
	GOTO	LDalsi		;jeste neni konec
;vysledek
	RLF	D1,W		;posledni x2
	MOVWF	C1		; a W do C
	RLF	D2,W		;
	MOVWF	C2		;
	RLF	D3,W		;
	MOVWF	C3		;

	BCF	STATUS,Z	;SZ=0
	RETURN


;................................
; D1,2,3 A1,2,3 * 2 a Minus
x2M	RLF	D1,F		;posuv vlevo
	RLF	D2,F		;
	RLF	D3,F		;
	RLF	A1,F		;
	RLF	A2,F		;
	RLF	A3,F		;
				;pokracuje MINUS
;--------------------------------
; A1,2,3 - B1,2,3 = C1,2,3
;SC=0=zaporny vysledek
;A,B se nezmeni
MINUS	MOVF	B1,W		;W=B1
	SUBWF	A1,W		;A1-B1=W
	MOVWF	C1		;C1=W=vysledek1
	CLRW			;W=0
	BTFSS	STATUS,C	;SUB kladne?
	MOVLW	1		;W=1
	ADDWF	B2,W		;B2+W=W
	CLRF	C3		;C3=0
	BTFSC	STATUS,C	;ADD nepreteklo?
	BSF	C3,0		;C3=1
	SUBWF	A2,W		;A2-W=W
	MOVWF	C2		;C2=w=vysledek2
	MOVF	C3,W		;W=C3
	BTFSS	STATUS,C	;SUB kladne?
	MOVLW	1		;W=1
	ADDWF	B3,W		;B3+W=W
	CLRF	C3		;C3=0
	BTFSC	STATUS,C	;ADD nepreteklo?
	BSF	C3,0		;C3=1
	SUBWF	A3,W		;A3-W=W
	BTFSC	C3,0		;C3=0?
	BCF	STATUS,C	;SC=0
	MOVWF	C3		;C3=W=vysledek3
	RETURN






        ;cekej cca 100 cyklu 40us  + u kazdeho cekani je 7 cyklu povinych
w100c   movlw .80
        movwf r4
        decfsz r4, F
        goto $-1
        return

          ;cekej necelou polovinu w100c
w40c    movlw .30
        movwf r4
        decfsz r4, F
        goto $-1
        return


        end                                           ; KONEC PROGRAMU
