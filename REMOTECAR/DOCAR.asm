
 LIST	   P=16F690, R=DEC
 ;INCLUDE  <P16F690.INC>

                  ;deklarace registru
r1      equ 20h
r2      equ 21h
r3      equ 22h
r4      equ 23h
potbin  equ 24h
butbin  equ 25h
car0    equ 26h
car1    equ 27h
car2    equ 28h
car3    equ 29h
car4    equ 2Ah
car5    equ 2Bh
car6    equ 2Ch
car7    equ 2Dh
w_temp  equ 2Eh
s_temp  equ 2Fh
tm0     equ 30h
r5      equ 31h
tm1     equ 32h
vyp     equ 33h



        org 000h        ;vektor zacatku
        goto init

        org 004h        ;vektor preruseni
        goto inter




init    clrf PORTA      ;Init PORTS
        clrf PORTB
        clrf PORTC
        
        bsf STATUS, RP1 ;Bank 2
        movlw b'00000111';nastaveni analogovych vstupu
        movwf ANSEL     ;digital I/O
        movlw b'00000000'
        movwf ANSELH    ;digital I/O
                          ;nastaveni frekvence ad prevodniku
        movlw b'00000000' ;0, FOSC/2 na rychlost prevodu 000, 0000
        movwf ADCON1
        
        
        bsf IOCB, 5       ;nastavy Int on change od RB5
        bsf STATUS, RP0  ;Bank 1
        bcf STATUS, RP1
        movlw	b'00001111'; 1 znamená vstup, 0 výstup
        movwf	TRISA
        movlw	b'00100000'
        movwf	TRISB
        movlw b'00000000'
        movwf TRISC
        bsf IOCA, 3       ;nastavy Int on change od RA3
        movlw b'11000111'  ;pul-up disable, rising, internal clock, x, timer0, prescale 1/256
        movwf OPTION_REG
        
        clrf PCON

        bcf STATUS, RP0 ;Bank 0

        bsf PORTC, 0    ;uvitaci problikaci kontrola LEDek
        call ws
        bcf PORTC, 0
        bsf PORTC, 1
        call ws
        bcf PORTC, 1
        bsf PORTC, 2
        call ws
        bcf PORTC, 2
        bsf PORTC, 3
        call ws
        bcf PORTC, 3
        bsf PORTC, 4
        call ws
        bcf PORTC, 4
        bsf PORTC, 5
        call ws
        bcf PORTC, 5
        bsf PORTC, 6
        call ws
        bcf PORTC, 6
        bsf PORTC, 7
        call ws
        bcf PORTC, 7
        bsf PORTB, 4
        call ws
        bcf PORTB, 4
        bsf PORTB, 6
        call ws
        bcf PORTB, 6
        
        
        movlw b'00110001' ;00, prescle 11, 00, internal clock, Enable
        movwf T1CON

        call inton
        
        goto start      ;zacni na startu

inton   bcf INTCON, RABIF	; nastavení pøerušení od RAB
        bcf INTCON, T0IF
        bcf PIR1, TMR1IF
        
        bsf INTCON, RABIE
        bsf INTCON, T0IE
        bsf INTCON, PEIE
        bsf PIE1, TMR1IE
        
        bsf INTCON, GIE
        return

intoff  bcf INTCON, RABIE
        bcf INTCON, T0IE
        bcf INTCON, PEIE
        bcf PIE1, TMR1IE
        return

inter   call intoff
        movwf w_temp ;copy w to temp register
        swapf STATUS, W ;swap status to be saved into w
        clrf STATUS ;bank 0, regardless of current bank, clears irp,rp1,rp0
        movwf s_temp ;save status to bank zero status_temp register

        btfsc INTCON, RABIF   ;pokud preruseni od A nebo B
        call radio
        
        btfsc INTCON, T0IF
        call batery
        
        btfsc PIR1, TMR1IF
        call vypni

        swapf s_temp, W ;swap status_temp register into w
        movwf STATUS ;move w into status register;(sets bank to original state)
        swapf w_temp, F ;swap w_temp
        swapf w_temp, W ;
        call inton
        return


start   btfsc vyp, 0  ;pokud tlacitko on/off !vypnuto jdi do standby modu
        call standby
        btfss vyp, 0  ;pokud zapnuto kontroluj vstupni tlacitka, potenc. a vysilej
        call chin
        goto start      ;zpet v cyklu na zacatek


zlv     btfsc PORTA, 3
        goto $-1
        comf vyp, F
        return

radio   btfsc PORTA, 3    ;pokud je zaply pristroj, alarm se vypina
        goto zlv
        btfss PORTB, 5  ;pokud preruseni nebylo od radia skonci
        return
        bsf PORTC, 7    ;zapne ledku indikace signálu
        
        call w40c   ;posune se do prostred prijimaneho bitu
        
        movlw .8
        movwf r3
zn3     rlf r1, F
        btfss PORTB, 5  ;projde postupne prijimany signal, prvni bajt, ulozi do r1
        bcf r1, 0
        btfsc PORTB, 5
        bsf r1, 0
        call w100c
        decfsz r3, F
        goto zn3
        
        movlw 4Fh        ;skontroluje prvni sifrovaci bajt zda je spravny B1h
        addwf r1, W
        btfss STATUS, Z   ;pokud ne skonci prijem
        goto spa

        
        movlw .8
        movwf r3
zn4     rlf r2, F
        btfss PORTB, 5  ;projde postupne prijimany signal, druhy bajt, ulozi do r2
        bcf r2, 0
        btfsc PORTB, 5
        bsf r2, 0
        call w100c
        decfsz r3, F
        goto zn4
        
        movlw .8
        movwf r3
zn5     rlf car0, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car0, 0
        btfsc PORTB, 5
        bsf car0, 0
        call w100c
        decfsz r3, F
        goto zn5
      
        movlw .8
        movwf r3
zn6     rlf car1, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car1, 0
        btfsc PORTB, 5
        bsf car1, 0
        call w100c
        decfsz r3, F
        goto zn6
      
        movlw .8
        movwf r3
zn7     rlf car2, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car2, 0
        btfsc PORTB, 5
        bsf car2, 0
        call w100c
        decfsz r3, F
        goto zn7
      
        movlw .8
        movwf r3
zn8     rlf car3, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car3, 0
        btfsc PORTB, 5
        bsf car3, 0
        call w100c
        decfsz r3, F
        goto zn8
      
        movlw .8
        movwf r3
zn9     rlf car4, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car4, 0
        btfsc PORTB, 5
        bsf car4, 0
        call w100c
        decfsz r3, F
        goto zn9
      
        movlw .8
        movwf r3
znA     rlf car5, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car5, 0
        btfsc PORTB, 5
        bsf car5, 0
        call w100c
        decfsz r3, F
        goto znA
      
        movlw .8
        movwf r3
znB     rlf car6, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car6, 0
        btfsc PORTB, 5
        bsf car6, 0
        call w100c
        decfsz r3, F
        goto znB
      
        movlw .8
        movwf r3
znC     rlf car7, F
        btfss PORTB, 5  ;projde postupne prijimany signal,
        bcf car7, 0
        btfsc PORTB, 5
        bsf car7, 0
        call w100c
        decfsz r3, F
        goto znC
        
        
        movlw .1
        addwf r2, W
        btfsc STATUS, Z
        bsf PORTB, 6     ;nastavi bit alarmu
        btfsc STATUS, Z
        bcf vyp, 0      ;zapne pristroj
        

spa     bcf PORTC, 7      ;vypne ledku indikace signálu
        return


chin    call chanpot    ;do W vrati bin kod potenciometru (prvni 3 bity)
        movwf potbin    ;zapis W do zalozniho registru
        call dec1z8     ;premeni bin v W na 1 z 8mi a ulozi do w
        movwf PORTC     ;zapise W do LEDek
        call chanbut    ;do W vrati bin kod tlacitek (prvni 3 bity)
        movwf butbin    ;zapis W do zalozniho registru
        addlw 0h
        btfsc STATUS, Z ;zjisti zda tlacitko je stisknuto, pokud neni skonci dal
        goto nnn
        movf potbin, W  ;zkontroluje zda kod potenciometru neni 0111b znovu
        addlw b'11111001'
        btfss STATUS, Z ;pokud neni 0111b odesle kombinaci kodu tlacitek a potenciometru v sifre
        call sendsig    
nnn     movf potbin, W  ;zkontroluje zda kod potenciometru neni 0111b
        addlw b'11111001'
        btfsc STATUS, Z ;pokud je 0111b zapise indikace do ledek
        call indled
        return


standby call intoff
        bsf INTCON, RABIE
        bsf INTCON, GIE
        sleep             ;nastavi preruseni od rad a tlacitka
        btfsc vyp, 0
        goto standby
        clrf tm1
        call inton
        return
        
        
chanpot movlw b'00000011'  ;zachyceno doleva, komparace s +VDD, ANO POT, start conver, enable ADC
        movwf ADCON0
        btfsc ADCON0, 1   ;ceka az se prevede AN signal
        goto $-1
        bcf STATUS, C     ;toci registr vystupu AN dokud nezbyde pouze prvni 3 bity
        rrf ADRESH, W
        movwf r1
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, W         ;vlozi do W
        return
        
        
dec1z8  movwf r1
        incf r1, F
        movlw b'00000001'
        movwf r2
help1   decfsz r1, F
        goto help0
        movf r2, W
        return
        
help0   bcf STATUS, C
        rlf r2, F
        goto help1
        
        
chanbut movlw b'00000111'  ;zachyceno doleva, komparace s +VDD, AN1 BUT, start conver, enable ADC
        movwf ADCON0
        btfsc ADCON0, 1   ;ceka az se prevede AN signal
        goto $-1
        bcf STATUS, C     ;toci registr vystupu AN dokud nezbyde pouze prvni 3 bity
        rrf ADRESH, W
        movwf r1
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, F
        bcf STATUS, C
        rrf r1, W         ;vlozi do W
        return
        
        
indled  movf butbin, W  ;pokud butom = 111
        addlw b'11111001'
        btfss STATUS, Z
        goto $+3
        movf car7, W    ;na vystup ledek prislusny registr
        movwf PORTC
        
        movf butbin, W  ;pokud butom = 110
        addlw b'11111010'
        btfss STATUS, Z
        goto $+3
        movf car6, W
        movwf PORTC
        
        movf butbin, W  ;pokud butom = 101
        addlw b'11111011'
        btfss STATUS, Z
        goto $+3
        movf car5, W
        movwf PORTC
        
        movf butbin, W  ;pokud butom = 100
        addlw b'11111100'
        btfss STATUS, Z
        goto $+3
        movf car4, W
        movwf PORTC
        
        movf butbin, W  ;pokud butom = 011
        addlw b'11111101'
        btfss STATUS, Z
        goto $+3
        movf car3, W
        movwf PORTC
        
        movf butbin, W  ;pokud butom = 010
        addlw b'11111110'
        btfss STATUS, Z
        goto $+3
        movf car2, W
        movwf PORTC
        
        movf butbin, W  ;pokud butom = 001
        addlw b'11111111'
        btfss STATUS, Z
        goto $+3
        movf car1, W
        movwf PORTC
        
        movf butbin, W  ;pokud butom = 000
        addlw b'00000000'
        btfss STATUS, Z
        goto $+3
        movf car0, W
        movwf PORTC
        
        bsf PORTC, 7
        return


sendsig bcf INTCON, GIE ;zastavi vsechna preruseni
        movf butbin, W
        movwf r1
        movf potbin, W
        movwf r2
        bcf STATUS, C   ;zakodovani informace do dvou bajtu
        rlf r2, F       ;pot a but do jednoho reg
        rlf r2, F
        rlf r2, F
        rlf r2, F
        rlf r1, W
        iorwf r2, W
        movwf r2      ;v r2 je kombinovany signal pot a but
        
        movwf r1     ;pridani sude a liche parity
        movlw .6
        movwf r3
        clrf r4
        
        btfsc r1, 1   ;spocita pocet jednicek
        incf r4, F
        rrf r1, F
        decfsz r3, F
        goto $-4
        
        btfsc r4, 0    ;vlozi na zacatek lichou paritu
        bsf r2, 0
        btfss r4, 0     ;vlozi nakonec sudou paritu
        bsf r2, 7
        
        movlw b'10110001' ;sifrovaci bajt B1h
        movwf r1          ;v r1 je sifrovaci bajt

        movlw .8
        movwf r3
zn1     btfsc r1, 0       ;pokud je nulty bit 1 nastav 1
        bsf PORTB, 7
        btfss r1, 0       ;pokud je 0 nastav 0
        bcf PORTB, 7
        rrf r1, F
        call w100c        ;pockej do 100 cyklu
        decfsz r3, F
        goto zn1

        movlw .8
        movwf r3
zn2     btfsc r2, 0       ;pokud je nulty bit 1 nastav 1
        bsf PORTB, 7
        btfss r2, 0       ;pokud je 0 nastav 0
        bcf PORTB, 7
        rrf r2, F
        call w100c        ;pockej do 100 cyklu
        decfsz r3, F
        goto zn2
        
        bcf PORTB, 7  ;vynuluje bit 7 TX po odeslani
        clrf tm1      ;vynuluje pomocny timer1 který zjištuje aktivitu tlacitek
        bsf INTCON, GIE ;pokracuje v prerusenich
        return


vypni   decfsz tm1, F
        return
        bsf vyp, 0    ;nastavy bit zda vypnutu na 1 
        return

batery  btfss PORTB, 4
        goto batwai ;kdyz ceka - indikaci, pridat rychlost podle napeti az 6700ms
        goto batsvi ;kdyz sviti ledka pouze indikacni cast 26ms


batwai  decfsz tm0, F
        return
        bsf PORTB, 4
        return
        
batsvi  call chanbat
        movwf r4
        rlf r4, F
        rlf r4, W
        movwf tm0
        bcf PORTB, 4
        return
        
        
chanbat movlw b'00001011'  ;zachyceno doleva, komparace s +VDD, AN2 POT, start conver, enable ADC
        movwf ADCON0
        btfsc ADCON0, 1   ;ceka az se prevede AN signal
        goto $-1
        bcf STATUS, C
        movf ADRESH, W ;vlozi do W
        return
        

        ;cekej cca 100 cyklu 40us
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


        ;cekej 100ms
ws      movlw .250
        movwf r1
        movlw .250
        movwf r2
        movlw .1
        movwf r3
        nop
        decfsz r3, F
        goto $-2
        decfsz r2, F
        goto $-6
        decfsz r1, F
        goto $-10
        return

        end                                           ; KONEC PROGRAMU
