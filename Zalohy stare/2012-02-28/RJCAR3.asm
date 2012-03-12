
; CONFIG BITS: 0x3FFA

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
ran1      equ 3Dh
ran2      equ 3Eh
ran3       equ 3Fh
ran4       equ 40h
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
ran5  equ 50h
OUT_L equ 51h
OUT_H equ 52h

conf        equ 7Ch

;KONSTANTY
;conf constant
WATCHOVER   equ .2



        org 000h        ;vektor zacatku
        goto init

        org 004h        ;vektor preruseni
        goto inter




init    movlw .3    ;oznaceni tohoto procesoru
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
        bsf INTCON, INTE
        call inton
        
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

        btfsc INTCON, INTF   ;pokud preruseni od B0
        call prijem
        
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


      ; Zaène poèítat èas pro procesor WATCH2
prijem      call watchstart
            btfsc conf, WATCHOVER
            goto prijemerr
            btfsc PORTB, 0  ;ceka az skonci prvni start bit
            goto $-3 ;ochrana proti zamrznuti
            call w40c   ;posune do prostred prijimaneho bitu
            call w100c  ;odbije druhy startbit
            
            clrf cil        ; ulozi prijate oznaceni do cil XXXX
            movlw .4
            movwf r2
            rlf cil, F
            btfsc PORTB, 0
            bsf cil, 0
            btfss PORTB, 0
            bcf cil, 0
            call w100c
            decfsz r2, F
            goto $-7
    
            btfsc PORTB, 0  ;zkontroluje pokud (r5, 0) = 0 vysle sve registry, naopak zapise do svych reg
            bsf r5, 0
            btfss PORTB, 0
            bcf r5, 0
            call w100c
    
            clrf port        ; ulozi prijate do port XX
            movlw .2
            movwf r2
            rlf port, F
            btfsc PORTB, 0
            bsf port, 0
            btfss PORTB, 0
            bcf port, 0
            call w100c
            decfsz r2, F
            goto $-7
            
            clrf cislo        ; ulozi prijate do cislo portu XXX
            movlw .3
            movwf r2
            rlf cislo, F
            btfsc PORTB, 0
            bsf cislo, 0
            btfss PORTB, 0
            bcf cislo, 0
            call w100c
            decfsz r2, F
            goto $-7
    
            btfsc PORTB, 0  ;zkontroluje (r5, 1) = hodnota ciloveho registru
            bsf r5, 1
            btfss PORTB, 0
            bcf r5, 1
            call w100c
            
            btfsc conf, WATCHOVER
            goto prijemerr
            btfsc PORTB, 0  ;ceka az skonci prvni stop bity
            goto $-3 ;ochrana proti zamrznuti

            
    
            btfss r5, 0  ;pokud 1 tak chce poslat zdejsi registry
            goto ende
    
            comf num, W     ;pokud neni pro nej zkonci
            addwf cil, W
            movwf r1
            incfsz r1, F
            goto ende
            
            movf port, W      ;podle port, cislo, hodno - nastavy prislusny port na danou hodnotu napr.: RC3:=1
            movwf r1          ;zdrzuje cca 46 instrukci
            btfsc STATUS, Z
            call pra
            decf r1, F
            btfsc STATUS, Z
            call prb
            decf r1, F
            btfsc STATUS, Z
            call prc
            decf r1, F
            btfsc STATUS, Z
            call prd
        
ende        btfsc r5, 0 ;pokud r5, 1, tedy je pouze nastavovan registr v tomto prc tak skonci bez ohledu na vyhrazeny cas 
            call watchover
            btfsc r5, 0 
            return
                
            ;pokud 0 vysle sve registry nebo ceka X bitu pokud neni pro nej
            call vysilej
            
            ; Èeká až dobìhne èas vyhrazený pro tento procesor WATCH2
            ;call watchwait

prijemerr   nop
            return

pra     movf cislo, W
        movwf r2
        decf r2, F
        decf r2, F
        decf r2, F
        decf r2, F
        btfsc STATUS, Z
        goto na4
        return
        

na4     btfss r5, 1
        bcf PORTA, 4
        btfsc r5, 1
        bsf PORTA, 4
        return


prb     movf cislo, W
        movwf r2
        decf r2, F
        btfsc STATUS, Z
        goto nb1
        decf r2, F
        btfsc STATUS, Z
        goto nb2
        decf r2, F
        btfsc STATUS, Z
        goto nb3
        decf r2, F
        btfsc STATUS, Z
        goto nb4
        decf r2, F
        btfsc STATUS, Z
        goto nb5
        decf r2, F
        btfsc STATUS, Z
        goto nb6
        decf r2, F
        btfsc STATUS, Z
        goto nb7
        return
        

nb1     btfss r5, 1
        bcf PORTB, 1
        btfsc r5, 1
        bsf PORTB, 1
        return
nb2     btfss r5, 1
        bcf PORTB, 2
        btfsc r5, 1
        bsf PORTB, 2
        return
nb3     btfss r5, 1
        bcf PORTB, 3
        btfsc r5, 1
        bsf PORTB, 3
        return
nb4     btfss r5, 1
        bcf PORTB, 4
        btfsc r5, 1
        bsf PORTB, 4
        return
nb5     btfss r5, 1
        bcf PORTB, 5
        btfsc r5, 1
        bsf PORTB, 5
        return
nb6     btfss r5, 1
        bcf PORTB, 6
        btfsc r5, 1
        bsf PORTB, 6
        return
nb7     btfss r5, 1
        bcf PORTB, 7
        btfsc r5, 1
        bsf PORTB, 7
        return
        
        
prc     movf cislo, W
        movwf r2
        btfsc STATUS, Z
        goto nc0
        decf r2, F
        btfsc STATUS, Z
        goto nc1
        decf r2, F
        btfsc STATUS, Z
        goto nc2
        decf r2, F
        btfsc STATUS, Z
        goto nc3
        decf r2, F
        btfsc STATUS, Z
        goto nc4
        decf r2, F
        btfsc STATUS, Z
        goto nc5
        decf r2, F
        btfsc STATUS, Z
        goto nc6
        decf r2, F
        btfsc STATUS, Z
        goto nc7
        return
        
nc0     btfss r5, 1
        bcf PORTC, 0
        btfsc r5, 1
        bsf PORTC, 0
        return
nc1     btfss r5, 1
        bcf PORTC, 1
        btfsc r5, 1
        bsf PORTC, 1
        return
nc2     btfss r5, 1
        bcf PORTC, 2
        btfsc r5, 1
        bsf PORTC, 2
        return
nc3     btfss r5, 1
        bcf PORTC, 3
        btfsc r5, 1
        bsf PORTC, 3
        return
nc4     btfss r5, 1
        bcf PORTC, 4
        btfsc r5, 1
        bsf PORTC, 4
        return
nc5     btfss r5, 1
        bcf PORTC, 5
        btfsc r5, 1
        bsf PORTC, 5
        return
nc6     btfss r5, 1
        bcf PORTC, 6
        btfsc r5, 1
        bsf PORTC, 6
        return
nc7     btfss r5, 1
        bcf PORTC, 7
        btfsc r5, 1
        bsf PORTC, 7
        return
        
        
prd     movf cislo, W
        movwf r2
        btfsc STATUS, Z
        goto nd0
        decf r2, F
        btfsc STATUS, Z
        goto nd1
        decf r2, F
        btfsc STATUS, Z
        goto nd2
        decf r2, F
        btfsc STATUS, Z
        goto nd3
        decf r2, F
        btfsc STATUS, Z
        goto nd4
        decf r2, F
        btfsc STATUS, Z
        goto nd5
        decf r2, F
        btfsc STATUS, Z
        goto nd6
        decf r2, F
        btfsc STATUS, Z
        goto nd7
        return
        
nd0     btfss r5, 1
        bcf PORTD, 0
        btfsc r5, 1
        bsf PORTD, 0
        return
nd1     btfss r5, 1
        bcf PORTD, 1
        btfsc r5, 1
        bsf PORTD, 1
        return
nd2     btfss r5, 1
        bcf PORTD, 2
        btfsc r5, 1
        bsf PORTD, 2
        return
nd3     btfss r5, 1
        bcf PORTD, 3
        btfsc r5, 1
        bsf PORTD, 3
        return
nd4     btfss r5, 1
        bcf PORTD, 4
        btfsc r5, 1
        bsf PORTD, 4
        return
nd5     btfss r5, 1
        bcf PORTD, 5
        btfsc r5, 1
        bsf PORTD, 5
        return
nd6     btfss r5, 1
        bcf PORTD, 6
        btfsc r5, 1
        bsf PORTD, 6
        return
nd7     btfss r5, 1
        bcf PORTD, 7
        btfsc r5, 1
        bsf PORTD, 7
        return


vysilej comf num, W     ;pokud neni pro nej skonci
        addwf cil, W
        movwf r1
        incfsz r1, F
        return
        
        bsf STATUS, RP0  ;Bank 1
        bcf TRISB, 0  ;nastavim sbernici na vystup z procesoru
        bcf STATUS, RP0  ;Bank 0
        
        bsf PORTB, 0  ;vysle start bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        
                ; vysle bajt AN XXXX XXXX
        movf an0, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle synchronizacni bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        

                ; vysle bajt AN XXXX XXXX
        movf an1, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle synchronizacni bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        

                ; vysle bajt AN XXXX XXXX
        movf an2, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle synchronizacni bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        

                ; vysle bajt AN XXXX XXXX
        movf an3, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle synchronizacni bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        

                ; vysle bajt AN XXXX XXXX
        movf an4, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle synchronizacni bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        

                ; vysle bajt AN XXXX XXXX
        movf an5, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle synchronizacni bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        

                ; vysle bajt AN XXXX XXXX
        movf an6, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle synchronizacni bity XX - 10
        call w100c
        bcf PORTB, 0
        call w100c
        

                ; vysle bajt AN XXXX XXXX
        movf an7, W
        movwf r1
        movlw .8
        movwf r2
        btfsc r1, 7
        bsf PORTB, 0
        btfss r1, 7
        bcf PORTB, 0
        call w100c
        rlf r1, F
        decfsz r2, F
        goto $-7
        
        bsf PORTB, 0  ;vysle stop bity XXX - 111
        call w100c
        call w100c
        call w100c
        bcf PORTB, 0
        call w40c


        bsf STATUS, RP0  ;Bank 1
        bsf TRISB, 0  ;nastavim sbernici na vstup do procesoru
        bcf STATUS, RP0  ;Bank 0

        return
        
        

start       movlw .0 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an0
            
            movlw .1 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an1
            
            movlw .2 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an2
            
            movlw .3 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an3
            
            movlw .4 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an4
            
            movlw .5 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an5
            
            movlw .6 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an6
            
            movlw .7 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            call adconv
            movf ran1, W
            movwf an7
        
            goto start      ;zpet v cyklu na zacatek
        
        


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







adconv      movlw .50 ; kolikrat se ma merit vstup
            movwf ran2 ; decrementator pro cykl
            movwf ran5 ; delitel pro vypocet prumeru
            movf ran1, W
            movwf ran3 ; zachováni ANx vstupu
            clrf CIS2_L
            clrf CIS2_H
            
adconv2     movf ran3, W
            movwf ran1 ; nasteni znova ANx vstupu
            call adconv_one
            
            ; pripraveni cisla 1 k pricteni
            clrf CIS1_H
            movf ran1, W
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
            
            
            decfsz ran2, F
            goto adconv2
            
            ; vydeli poctem mereni
            movf CIS2_L, W
            movwf A1
            movf CIS2_H, W
            movwf A2
            clrf A3
            
            movf ran5, W
            movwf B1
            clrf B2
            clrf B3
            
            call LOMENO24
            movf C1, W
            movwf ran1
            
            return
        
adconv_one  bcf STATUS, C
            rlf ran1, F
            rlf ran1, F
            rlf ran1, F
            
            ; ADCON0 REG     ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
            bcf ran1, 7
            bsf ran1, 6
            ; 5
            ; 4
            ; 3
            bsf ran1, 2
            ; 1
            bsf ran1, 0
            
            movf ran1, W
            movwf ADCON0
            
            btfsc ADCON0, 2   ;ceka nez skonci AD prevod
            goto $-1
            movf ADRESH, W    ;kontroluje zda je zmena od minule
            movwf ran1
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




        end                                           ; KONEC PROGRAMU
