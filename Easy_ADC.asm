
 LIST	   P=16F874A, R=DEC
 INCLUDE  <P16F874.INC>

                  ;deklarace registru
r1      equ 20h
r2      equ 21h
r3      equ 22h
r4      equ 23h
an4         equ 24h





        org 000h        ;vektor zacatku
        goto init

        org 004h        ;vektor preruseni
        goto inter




init    nop
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

        
        
        
start  nop;
      
      
        movlw b'10100101' ;00 Fosc/2, 000 AN0, 1 start & in progres, 0, 1 shut up (povoleno)
        movwf ADCON0
        btfsc ADCON0, 2   ;ceka nez skonci AD prevod
        goto $-1
        movf ADRESH, W    ;kontroluje zda je zmena od minule
        movwf an4
        
        
        
        
        
        
        
        ;;;;;;;;;;;;;;;; DEBUG
        btfss an4, 0
        bcf PORTD, 0
        btfsc an4, 0
        bsf PORTD, 0
        
        btfss an4, 1
        bcf PORTD, 1
        btfsc an4, 1
        bsf PORTD, 1
        
        btfss an4, 2
        bcf PORTD, 2
        btfsc an4, 2
        bsf PORTD, 2
        
        btfss an4, 3
        bcf PORTD, 3
        btfsc an4, 3
        bsf PORTD, 3
        
        btfss an4, 4
        bcf PORTD, 4
        btfsc an4, 4
        bsf PORTD, 4
        
        btfss an4, 5
        bcf PORTD, 5
        btfsc an4, 5
        bsf PORTD, 5
        
        btfss an4, 6
        bcf PORTD, 6
        btfsc an4, 6
        bsf PORTD, 6
        
        btfss an4, 7
        bcf PORTD, 7
        btfsc an4, 7
        bsf PORTD, 7
        
        
        
        movlw .5
        movwf r2
        movlw .200
        movwf r3
        call w100c
        decfsz r3, F
        goto $-2
        decfsz r2, F
        goto $-4
        
        
        
        
      goto start




inter   nop;






        ;cekej cca 100 cyklu 40us  + u kazdeho cekani je 7 cyklu povinych
w100c   movlw .80
        movwf r4
        decfsz r4, F
        goto $-1
        return


        end                                           ; KONEC PROGRAMU
