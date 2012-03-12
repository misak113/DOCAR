

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

        movlw b'00000000' ;0 left justifed, FOSC/2 na rychlost prevodu 0, 00, nastaveni analogových vstupu a hodnotu k porovnání 0000
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
        
        

start   movlw b'00000101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an0
        
        movlw b'00001101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an1
        
        movlw b'00010101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an2
        
        movlw b'00011101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an3
        
        movlw b'00100101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an4
        
        movlw b'00101101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an5
        
        movlw b'00110101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an6
        
        movlw b'00111101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
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


        end                                           ; KONEC PROGRAMU
