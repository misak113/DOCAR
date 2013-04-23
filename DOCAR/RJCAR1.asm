
; CONFIG BITS: 0x3F3E

      LIST        P=16F874A, R=DEC
      INCLUDE     <P16F874.INC>
      
      
;GLOBALNI deklarace registru
      cblock	0x20
r1          
r2          
r3          
r4          
r5          
r6         

w_temp     
s_temp      
pcl_temp   



;registry stavu
o_a         
o_b         
o_c         
o_d         
o_e         
o_f         
o_g         
o_h         
o_i         
o_j         
o_k         
o_l         

ir_x        
ir_49       
ir_50       
ir_51       
ir_52       
ir_53       
ir_54       
ir_55       
ir_56       
ir_57       
ir_58       
ir_59       
ir_60       
ir_61       
ir_62       
ir_80       
ir_84       
ir_85       
ir_86       
ir_87       
ir_88       
ir_89       
ir_90       
ir_91       
ir_92       
ir_93       
ir_127      
ir_128      

locked      
port        
prc         
tl1         
tl2         
tl3         
timsir      
cassir      
conf        
casov       
timvar      
timrtu      
timlza      

PORTA_temp
PORTB_temp
PORTC_temp
PORTD_temp
PORTE_temp


timwtu      
spinac      
timspi      
timods      
timala      
x0          

x1          
x2          
casvar
vterina
      ; registr 79/96
      endc

; BANK 1
      cblock	0x20

o1tmp       
o2tmp       
o3tmp       
o4tmp       
o1tar       
o2tar       
o3tar       
o4tar       
      endc


;Lokální proměne (pracovni a parametry) od 6D
      cblock 0x70
pri0       
pri1       
pri2        
pri3      
pri4        
pri5       
pri6    
pri7        
cil       
      endc  

      cblock 0x70
CIS1_L      
CIS1_H      
CIS2_L 
CIS2_H 
OUT_L 
OUT_H       
ran1      
ran2      
ran3       
ran4    
ran5  
      endc
  
      cblock 0x70
A1    
A2    
A3    
B1    
B2    
B3    
C1    
C2    
C3    
D1    
D2    
D3    
X1    
X2    
FL    
      endc



;KONSTANTY
;conf constant
T0OF        equ .0
STARTED     equ .1
WATCHOVER   equ .2
PCON_POR    equ .3
T1OF	    equ .4
;casov constant
;VAROV       equ .0
REDTUN      equ .1
LEDZAM      equ .2
WHITUN      equ .3
ODSKOK      equ .4
ALARM       equ .5

;system constants
POR	    equ .1



            org 000h        ;vektor zacatku
            goto init

            org 004h        ;vektor preruseni
            movwf w_temp ;copy w to temp register
            movf STATUS, W ;swap status to be saved into w
            movwf s_temp ;save status to bank zero s_temp register
            movf PCLATH, W ;swap pclath to be saved into w
            movwf pcl_temp ;save status to bank zero pclath_temp register
            clrf STATUS ;bank 0, regardless of current bank, clears irp,rp1,rp0
            
            bcf PCLATH,3 ;Select page 0
            call inter
        
            movf pcl_temp, W ;swap pcl_temp register into w
            movwf PCLATH ;move w into PCLATH register;(sets bank to original state)
            movf s_temp, W ;swap status_temp register into w
            movwf STATUS ;move w into status register;(sets bank to original state)
            movf w_temp, W ;
	    btfss s_temp, Z
	    bcf STATUS, Z
            btfsc s_temp, Z
	    bsf STATUS, Z
            return

init        bcf PCLATH,3 ;Select page 0
	    bcf PCLATH,4 ;Select page 0
	    	
	    clrf PORTA      ;Init PORTS	
            clrf PORTB
            clrf PORTC
            clrf PORTD
            clrf PORTE
            
            bsf STATUS, RP0  ;Bank 1
            
            movlw b'01001001' ;0 left justifed, FOSC/2 na rychlost prevodu 0, 00, nastaveni analogových vstupu a hodnotu k porovnání 0000
            movwf ADCON1
    
            movlw b'00101111'; 1 znamená vstup, 0 výstup
            movwf TRISA
            movlw b'00000001'
            movwf TRISB
            movlw b'00000000'
            movwf TRISC
            movlw b'00000000'
            movwf TRISD
            movlw b'00000001'
            movwf TRISE
            
	    clrwdt
            movlw b'11001100' ; timer0 control, WDT prescaler '100' -> 288ms
            movwf OPTION_REG
            
	    movf PCON, W
	    bsf PCON, POR

	    bcf STATUS, RP0 ;Bank 0

	    movwf r1
	    bcf conf, PCON_POR
	    btfsc r1, POR ;pokud neni zapnuto, obnovi stare registry
	    bsf conf, PCON_POR


            movlw b'00100001' ; nastaví control register timer1
            movwf T1CON
            movlw b'01000110' ; nastaví control register timer2
            movwf T2CON
            
            call inton
            
            
            bsf PCLATH,3 ;Select page 1
	    btfsc conf, PCON_POR ;pokud neni zapnuto, obnovi stare registry
	    goto restart

	    goto start      ;zacni na startu
        
        
        

inton       bcf INTCON, INTF ; nastavení přerušení od RB0        
            bsf INTCON, INTE
            ;bcf INTCON, T0IF ;nastavení přerušení od Timer0
            ;bsf INTCON, T0IE
            bcf PIR1, TMR1IF ;nastavení přerušení od Timer1
            bcf PIR1, TMR2IF ;nastavení přerušení od Timer2
            bsf STATUS, RP0  ;Bank 1
            bsf PIE1, TMR1IE
            bsf PIE1, TMR2IE
            bcf STATUS, RP0 ;Bank 0
            bsf INTCON, PEIE
            bsf INTCON, GIE
            return
        
intoff      bcf INTCON, INTE
            ;bcf INTCON, T0IE
            bsf STATUS, RP0  ;Bank 1
            bcf PIE1, TMR1IE
            bcf PIE1, TMR2IE
            bcf STATUS, RP0 ;Bank 0
            return



inter       call intoff
      
            btfsc INTCON, INTF      ;preruseni od RX B0 prijem radio signalu
            call radio
            ;btfsc INTCON, T0IF
            ;bsf conf, T0OF
            btfsc PIR1, TMR1IF      ;preruseni od timer1 watch
            bsf conf, T1OF
	    btfsc PIR1, TMR2IF      ;preruseni od timer2 watch
            call watchover
	    
            call inton
            return

;pokud přetekl timer2 pro watch
watchover   bsf conf, WATCHOVER
            return
            
;Zapnutí stopek pro kontrolu zacyklení - timer2
watchstart  bcf conf, WATCHOVER ;nastavi jako nepreteceny
            clrf TMR2 ;vynuluje timer2
            return
            
watchwait   btfss conf, WATCHOVER
            goto $-1
            ; pro jistotu jeste pocka aby dobehly hodiny v ostatnich PRCS
            call w100c
            return

;při zachyceni signalu na radiovem přijímači        
radio       nop
            return

;timer0	    nop
	    
	    ;bcf conf, T0OF
	    ;return

;při přetečení timeru 1, až po fázi synchronizace procesorů   
timer1      btfsc cassir, 0
            call sirbeep
            btfsc casvar, 0
            call varoff
            btfsc casov, REDTUN
            call rtuoff
            btfsc casov, LEDZAM
            call lzabli
            btfsc casov, WHITUN
            call wtuoff
            btfsc casov, ODSKOK
            call odsoff
            btfsc casov, ALARM
            call alabli
            btfsc spinac, 2
            call spioff

	    decf vterina, F
            btfsc STATUS, Z
	    call vterinka

            bcf conf, T1OF
            return
            
vterinka    nop

;Ledky blikajici kdyz je PC zaply
ledPCRun    movf o_g, W
	    movwf r5
	    movlw b'01100' ;port B4
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
	    btfsc r5, 5
            call setout ;nastav port v prc
            btfsc r5, 5
            bsf o_g, 4 
	    btfss r5, 5
            call clrout ;nastav port v prc
            btfss r5, 5
            bcf o_g, 4 
	    
	    movf o_g, W
	    movwf r5
	    movlw b'01101' ;port B5
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            btfss r5, 4
            call setout ;nastav port v prc
            btfss r5, 4
            bsf o_g, 5 
	    btfsc r5, 4
            call clrout ;nastav port v prc
            btfsc r5, 4
            bcf o_g, 5 

	    ;vypne zadni pasy po restartu
	    movlw b'01110' ;port B6
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
	    btfsc o_g, 6
            call clrout ;nastav port v prc
            bcf o_g, 6 
	    
	    movlw b'01111' ;port B7
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            btfsc o_g, 7
            call clrout ;nastav port v prc
            bcf o_g, 7 

	    ; nastaveni nove vterinky
	    movlw .9 ;nastavy na dalsich 240ms
            movwf vterina
	    return


;houkani sireny v intervalech cca 240ms        
sirbeep     decf timsir, F
            btfss STATUS, Z
            return
            bcf STATUS, C
            rrf cassir, F ;otaci az v 0 bude 1, pak timer sireny nevnima
            call t1_53 ;neguje houkani sireny
            movlw .3 ;nastavy na dalsich 240ms
            movwf timsir
            return
            
;blikani varovek
varoff      decf timvar, F
            btfss STATUS, Z
            return
            rrf casvar, F
            btfss STATUS, C
            bcf casvar, 7
            btfsc STATUS, C
            bsf casvar, 7
            
            clrf r2   ;pokud jeden nebo oba blinkry vyply - zapne varovky, opacne je vypne
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
            bcf PORTD_temp, 6
            btfsc r3, 0 ;pokud oba zaply oba vypne
            bcf PORTD, 6
            btfsc r3, 0 ;pokud oba zaply oba vypne
            bcf o_e, 5
            btfsc r3, 0 ;pokud oba zaply oba vypne
            bcf PORTD_temp, 7
	    btfsc r3, 0 ;pokud oba zaply oba vypne
            bcf PORTD, 7
    
            btfss r3, 0 ;pokud jeden vyply oba zapne
            bsf o_e, 4
            btfss r3, 0 ;pokud jeden vyply oba zapne
            bsf PORTD_temp, 6
            btfss r3, 0 ;pokud jeden vyply oba zapne
            bsf PORTD, 6
            btfss r3, 0 ;pokud jeden vyply oba zapne
            bsf o_e, 5
            btfss r3, 0 ;pokud jeden vyply oba zapne
            bsf PORTD_temp, 7
            btfss r3, 0 ;pokud jeden vyply oba zapne
            bsf PORTD, 7
            
            movlw .8 ;nastavy na dalsich 240ms
            movwf timvar
            return

;vypnuti red tuning
rtuoff      decf timrtu, F
            btfss STATUS, Z
            return
            bcf o_c, 2 ;vypne red tunning
            movlw b'10110' ;port C6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call clrout ;smaz port v prc
            bcf o_f, 3 ;vypne red interier
            movlw b'11010' ;port D2
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call clrout ;smaz port v prc
            bcf casov, REDTUN ;timer red tunningu nebude vniman
            return
            
;blikani led zamknuto
lzabli      decf timlza, F
            btfss STATUS, Z
            return
            call ledzam ;neguje led zamknuto
            movlw .15 ;nasavy na dalsich 240ms
            movwf timlza
            return
            
;vypnuti white tuning
wtuoff      decf timwtu, F
            btfss STATUS, Z
            return
            bcf o_c, 3 ;vypne white tunning
            movlw b'10111' ;port C7
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call clrout ;smaz port v prc
            bcf o_f, 4 ;vypne white interier
            movlw b'11011' ;port D3
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call clrout ;smaz port v prc
            bcf casov, WHITUN ;timer red tunningu nebude vniman
            return
            
;vypnuti polohy 3 spinacky
spioff      decf timspi, F
            btfss STATUS, Z
            return
            call t1_03
            return
            
;vypnuti odskoků
odsoff      decf timods, F
            btfss STATUS, Z
            return
            bcf o_b, 4
            movlw b'11111' ;port D7
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call clrout ;smaz port v prc
            bcf o_b, 5
            bcf PORTC_temp, 7
            bcf PORTC, 7
            bcf o_b, 6
            bcf PORTB_temp, 2
            bcf PORTB, 2
            bcf o_b, 7
            bcf PORTB_temp, 3
            bcf PORTB, 3
            bcf o_b, 3
            bcf PORTB_temp, 4
            bcf PORTB, 4
            bcf o_e, 0
            bcf PORTB_temp, 5
            bcf PORTB, 5
            bcf o_c, 0
            bcf PORTB_temp, 6
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


            ; vypnutí stahovani oken
            bsf PCLATH,3 ;Select page 1
            call o1stop
            call o2stop
            bcf PCLATH,3 ;Select page 0

            bcf casov, ODSKOK ;timer odskuku nebude vniman
            return
            
;Problikavani alarmu
alabli      decf timala, F
            btfss STATUS, Z
            return

            call t1_40
            call t1_41
            call t1_61
            ;call t1_62 ;Baterie nebliká
            call klakson
            
            movlw .20 ;nasavy na dalsich 240ms
            movwf timala
            return






dotaz       bsf PORTB, 1  ;start bity XX - 10
            call w100c
            bcf PORTB, 1
            call w100c
            
            movf cil, W   ;vysila oznaceni cilového procesoru XXXX
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
            call w40c
            
            bsf STATUS, RP0  ;Bank 1
            bsf TRISB, 1  ;nastavim sbernici na vstup do procesoru
            bcf STATUS, RP0  ;Bank 0
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfss PORTB, 1  ;ceka az zacne vysilat signal
            goto $-3 ;ochrana proti zamrznuti
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci prvni start bit X - 1
            goto $-3 ;ochrana proti zamrznuti
            
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
            goto $-3 ;ochrana proti zamrznuti
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
            goto $-3 ;ochrana proti zamrznuti
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
            goto $-3 ;ochrana proti zamrznuti
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
            goto $-3 ;ochrana proti zamrznuti
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
            goto $-3 ;ochrana proti zamrznuti
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
            goto $-3 ;ochrana proti zamrznuti
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci privni synchronizacni bit X - 1
            goto $-3 ;ochrana proti zamrznuti
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
            
            btfsc conf, WATCHOVER
            goto dotazerr
            btfsc PORTB, 1  ;ceka az skonci STOP bity XXX - 111
            goto $-3 ;ochrana proti zamrznuti
            
            
dotazerr    bsf STATUS, RP0  ;Bank 1
            bcf TRISB, 1  ;nastavim sbernici na vystup z procesoru
            bcf STATUS, RP0  ;Bank 0
            return
        
        ; WATCH2 start
setout      bsf PORTB, 1  ;start bity XX - 10
            call w100c
            bcf PORTB, 1
            call w100c
            
            movf prc, W   ;vysila oznaceni cilového procesoru XXXX
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
            call w100c
            ; WATCH2 wait
            return

      ; WATCH2 start
clrout      bsf PORTB, 1  ;start bity XX - 10
            call w100c
            bcf PORTB, 1
            call w100c
            
            movf prc, W   ;vysila oznaceni cilového procesoru XXXX
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
            call w100c
            ; WATCH2 wait
            return
        
        
        
        
        
        
        
        
        
        
        
        ;podprogramy
;Tlačitka funkci 1
if_58       btfsc o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
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

;Tlačitka funkci 2
if_62       btfsc o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
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
;Tlačitka imobilizeru
if_50       nop
            return
             ;pasy
if_59       nop
            return
             ;rychlost
if_60       nop
            return
             ;otáčky
if_61       nop
            return
             ;teplota in set
if_49       nop
            return
             ;alarm senzory
if_80       nop
            return
             ;baterie
if_51       nop
            return
             ;teplota in
if_52       nop
            return
             ;teplota eng
if_53       nop
            return
             ;palivo
if_54       nop
            return
             ;dveře 1
if_55       nop
            return
             ;ruční brzda
if_56       nop
            return
             ;kvalt
if_57       nop
            return
             ;dveře 2
if_84       nop
            return
             ;dveře 3
if_85       nop
            return
             ;dveře 4
if_86       nop
            return
             ;kapota
if_87       nop
            return
             ;kufr
if_88       nop
            return
             ;nadrz
if_89       nop
            return
             ;okno 1
if_90       nop
            return
             ;okno 2
if_91       nop
            return
             ;okno 3
if_92       nop
            return
             ;okno 4
if_93       nop
            return
             ;teplota OUT
if_127      nop
            return

;Tlačítka funkcí 3
if_128      btfsc o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
            nop;return ;po dokonceni vyvoje vratit return z duvodu bezpecnosti a je to důležité !!!!!
            
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
            nop;call t1_00 ;prozatimne, je nutno odstranit po konci vyvoje
            incf r1, F
            btfsc STATUS, Z
            call t1_01 ;prozatimne, je nutno odstranit po konci vyvoje
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
            incf r1, F
            btfsc STATUS, Z
            call t1_x
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

;předpřipravené pro rozšíření procesoru 5 a vice
if_x        nop
            return

;vypina holdovaci vystupy
t1_stop     nop
            return
t2_stop     nop
            return
t3_stop     nop
            return
            
tx_stop     movlw b'10000' ;port C0    ;6 tlačítek ovládání rádia PLAY, STOP, FWD, RWD, VOL+, VOL-
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
            bcf PORTD_temp, 6
            bcf PORTD, 6
            bcf o_e, 5
            bcf PORTD_temp, 7
            bcf PORTD, 7
                  ;klakson
            movlw b'11001' ;port D1
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            btfsc o_c, 4
            call clrout ;nastav port v prc
            bcf o_c, 4
                  ;stěrače, odstřikovače
            bcf o_c, 7
            bcf PORTD_temp, 3
            bcf PORTD, 3
            bcf o_c, 6
            bcf PORTD_temp, 2
            bcf PORTD, 2
                  ;dálková světla
            bcf o_d, 0
            bcf PORTD_temp, 4
            bcf PORTD, 4
            return
        
        
        
;zamknuti alarm on
t1_00       btfsc o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
            return
	    ;btfsc cassir, 0 ;pokud nyni pulsne houka sirena tak nelze provadet operaci
            ;return
            ;movf ir_55, W ;zkontroluje dvere, pokud jsou otevrene promluvy a 3x rychle zahraje sirenu
            ;iorwf ir_84, W
            ;iorwf ir_85, W
            ;iorwf ir_86, W
            ;iorwf ir_87, W
            ;iorwf ir_88, W
            ;iorwf ir_89, W
            ;movwf r6
            ;btfsc r6, 7
            ;nop ;MLUV "zkontrolujte vstupy do auta"
            ;btfsc r6, 7
            ;call t1_53 ;zapne sirenu
            ;btfsc r6, 7
            ;movlw b'00011111' ;nastavi do timeru ze houkne 3x po 200ms
            ;btfsc r6, 7
            ;movwf cassir
            ;btfsc r6, 7
            ;movlw .3
            ;btfsc r6, 7
            ;movwf timsir
            ;btfsc r6, 7  ;AŽ budou indikace otevřených dveří, tohle odkomentovat
            ;return

            call t1_06 ;vypne vse 
            bsf o_d, 7 ;zapne alarm cidla
            bsf PORTB_temp, 7
            bsf PORTB, 7
                  ;zapne probliknuti nejakych svetel a sirenu a po urcitem case vypne, 
                  ;zatahne okna a pamatuje si polohu, zacne problikavat LED zamceno, promluvi ze je zamceno
            
            
            call t1_05 ;zapne varovky
            movlw b'00011111' ;nastavi do timeru ze houkne 3x po 200ms
            movwf casvar
            movlw .8
            movwf timvar
            
            
            movlw b'10110' ;port C6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfss o_c, 2
            call setout ;set port v prc
            bsf o_c, 2 ;problikne red tunning na 1 sekundu

            ;movlw b'11010' ;port D2
            ;movwf port
            ;movlw b'10' ;procesor 2
            ;movwf prc 
            ;btfss o_f, 3
            ;call setout ;set port v prc
            ;bsf o_f, 3 ;problikne red interier na 1 sekundu

            bsf casov, REDTUN ;do timeru ze po 1s vypne
            movlw .20
            movwf timrtu

            call t1_53 ;zahraje sirenou na 200ms
            movlw b'00000001' ;nastavi do timeru ze houkne 1x po 200ms
            movwf cassir
            movlw .8
            movwf timsir

            bcf o_f, 7 ;sklopi zrcatka neboli vypne
            bcf PORTE_temp, 1
            bcf PORTE, 1

            nop ;MLUV "auto zamčeno"
            call t1_07 ;zamkne

            bsf casov, LEDZAM ;zapne problikavani LED zamceno po 500ms
            movlw .15
            movwf timlza

                  ;zatahnuti okenek
            ;movf ir_90, W ;ulozi si aktualni polohy okenek pro stazeni pri odemknuti
            ;movwf o1tmp
            ;movf ir_91, W
            ;movwf o2tmp
            ;movf ir_92, W
            ;movwf o3tmp
            ;movf ir_93, W
            ;movwf o4tmp
            ;movlw b'00000000' ;nastavy vyslednou polohu vsech okenek na same nuly (vytazene)
            ;movwf o1tar
            ;movwf o2tar
            ;movwf o3tar
            ;movwf o4tar
 
            return
            
;odemknuti alarm off
t1_01       btfss o_d, 7 ;pokud alarm zapnut nefungujou tlacitka
            return
	    ;btfsc cassir, 0 ;pokud nyni pulsne houka sirena tak nelze provadet operaci
            ;return
            
            bcf o_d, 7 ;vypne alarm cidla
            bcf PORTB_temp, 7
            bcf PORTB, 7
                  ;zapne probliknuti nejakych svetel a sirenu a po urcitem case vypne, STOP alarm
                  ;stahne okna do pamatovane polohy, prestane problikavat LED zamceno, promluvi ze je odemceno
            call t1_04
            
            
            call t1_05 ;zapne varovky
            movlw b'00000111' ;nastavi do timeru ze houkne 3x po 200ms
            movwf casvar
            movlw .8
            movwf timvar
            
            
            movlw b'10111' ;port C7
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfss o_c, 3
            call setout ;set port v prc
            bsf o_c, 3 ;problikne white tunning na 1 sekundu

            ;movlw b'11011' ;port D3
            ;movwf port
            ;movlw b'10' ;procesor 2
            ;movwf prc 
            ;btfss o_f, 4
            ;call setout ;set port v prc
            ;bsf o_f, 4 ;problikne white interier na 1 sekundu

            bsf casov, WHITUN ;do timeru ze po 1s vypne
            movlw .20
            movwf timwtu

            call t1_53 ;zahraje sirenou na 200ms
            movlw b'00000111' ;nastavi do timeru ze houkne 2x po 200ms
            movwf cassir
            movlw .8
            movwf timsir

            bsf o_f, 7 ;odklopi zrcatka neboli zapne
            bsf PORTE_temp, 1
            bsf PORTE, 1

            nop ;MLUV "auto odemčeno"
            bcf casov, LEDZAM ;zapne problikavani LED zamceno po 500ms

            call t1_08 ;odemkne

                  ;stahnuti okenek
            ;movf o1tmp, W
            ;movwf o1tar
            ;movf o2tmp, W
            ;movwf o2tar
            ;movf o3tmp, W
            ;movwf o3tar
            ;movf o4tmp, W
            ;movwf o4tar
 
            return
            
;spinacka poloha up
t1_02       btfsc spinac, 2
            return
            bsf STATUS, C
            rlf spinac, F
                  ;pokud poloha 3
            btfss spinac, 2
            goto t2_02
            bcf o_a, 0
            bcf PORTC_temp, 0
            bcf PORTC, 0
            bcf o_a, 1
            bcf PORTC_temp, 1
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
            movlw .15 ;nastavi startovani pouze max na vterinu
            movwf timspi
            return
            ;pokud poloha 2
t2_02       btfss spinac, 1
            goto t3_02
            bsf o_a, 0
            bsf PORTC_temp, 0
            bsf PORTC, 0
            bsf o_a, 2
            bsf PORTC_temp, 2
            bsf PORTC, 2
            return
            ;pokud poloha 1
t3_02       bsf o_a, 1
            bsf PORTC_temp, 1
            bsf PORTC, 1
            return
            
;spinacka poloha down
t1_03       btfss spinac, 0
            return
            bcf STATUS, C
            rrf spinac, F
            ;pokud poloha 2
            btfss spinac, 1
            goto t2_03
            bsf o_a, 0
            bsf PORTC_temp, 0
            bsf PORTC, 0
            bsf o_a, 1
            bsf PORTC_temp, 1
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
t2_03       btfss spinac, 0
            goto t3_03
            bcf o_a, 0
            bcf PORTC_temp, 0
            bcf PORTC, 0
            bcf o_a, 2
            bcf PORTC_temp, 2
            bcf PORTC, 2
            return
            ;pokud poloha 0
t3_03       bcf o_a, 1
            bcf PORTC_temp, 1
            bcf PORTC, 1
            return
            
;alarm stop
t1_04       btfss casov, ALARM
            return
            movlw b'11000' ;port D0  ;sirena
            movwf port
            movlw b'11' ;procesor 3
            movwf prc 
            btfsc o_e, 1
            call clrout ;set port v prc
            bcf o_e, 1
            ;varovky
            call t1_05
            
            ;stroboskop
            movlw b'11001' ;port D1
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_e, 2
            call clrout ;set port v prc
            bcf o_e, 2
            
            movlw b'10110' ;port C6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_c, 2
            call clrout ;set port v prc
            bcf o_c, 2
            movlw b'10111' ;port C7
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_c, 3
            call clrout ;set port v prc
            bcf o_c, 3
            movlw b'11010' ;port D2
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_f, 3
            call clrout ;set port v prc
            bcf o_f, 3
            ;movlw b'11011' ;port D3
            ;movwf port
            ;movlw b'10' ;procesor 2
            ;movwf prc
            ;btfsc o_f, 4
            ;call clrout ;set port v prc
            ;bcf o_f, 4
            movlw b'11001' ;port D1
            movwf port
            movlw b'11' ;procesor 3
            movwf prc 
            btfsc o_c, 4
            call clrout ;set port v prc
            bcf o_c, 4
            
            bcf casov, ALARM ;zacne problikavat tuning, interier a klakson
            return
            
;varovna svetla
t1_05       btfsc casvar, 0 ;pokud oba zaply oba vypne
            bcf o_e, 4
            btfsc casvar, 0 ;pokud oba zaply oba vypne
            bcf PORTD_temp, 6
            btfsc casvar, 0 ;pokud oba zaply oba vypne
            bcf PORTD, 6
            btfsc casvar, 0 ;pokud oba zaply oba vypne
            bcf o_e, 5
            btfsc casvar, 0 ;pokud oba zaply oba vypne
            bcf PORTD_temp, 7
	    btfsc casvar, 0 ;pokud oba zaply oba vypne
            bcf PORTD, 7
    
            btfss casvar, 0 ;pokud jeden vyply oba zapne
            bsf o_e, 4
            btfss casvar, 0 ;pokud jeden vyply oba zapne
            bsf PORTD_temp, 6
            btfss casvar, 0 ;pokud jeden vyply oba zapne
            bsf PORTD, 6
            btfss casvar, 0 ;pokud jeden vyply oba zapne
            bsf o_e, 5
            btfss casvar, 0 ;pokud jeden vyply oba zapne
            bsf PORTD_temp, 7
            btfss casvar, 0 ;pokud jeden vyply oba zapne
            bsf PORTD, 7
            
            btfsc casvar, 0
            movlw b'00000000' ;nastavi do timeru ze prestane blikat porad
            btfss casvar, 0
            movlw b'11111111' ;nastavi do timeru ze bude blikat porad
            movwf casvar
            movlw .8
            movwf timvar
            
            return
            
;vypnout vse
t1_06       btfsc conf, STARTED ;kdyz neni nastartovano vypni vse
            return
            ;svetla 
            bcf o_c, 1
            bcf PORTC_temp, 3
            bcf PORTC, 3
            ;red tuning
            ;white tunning
            ;red interier
            ;white interier
            movlw b'10111' ;port C7
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_c, 3
            call clrout ;set port v prc
            bcf o_c, 3
            movlw b'11011' ;port D3
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_f, 4
            call clrout ;set port v prc
            bcf o_f, 4
            movlw b'10110' ;port C6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_c, 2
            call clrout ;set port v prc
            bcf o_c, 2
            movlw b'11010' ;port D2
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_f, 3
            call clrout ;set port v prc
            bcf o_f, 3
        
            ;stroboskop
            movlw b'11001' ;port D1
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfsc o_e, 2
            call clrout ;set port v prc
            bcf o_e, 2
            ;sirena
            movlw b'11000' ;port D0
            movwf port
            movlw b'11' ;procesor 3
            movwf prc 
            btfsc o_e, 1
            call clrout ;set port v prc
            bcf o_e, 1
            ;parkovacky
            bcf o_e, 3
            bcf PORTD_temp, 5
            bcf PORTD, 5
            ;mlhovky zadni
            bcf o_f, 1
            bcf PORTC_temp, 4
            bcf PORTC, 4
            ;mlhovky predni
            bcf o_c, 5
            bcf PORTD_temp, 1
            bcf PORTD, 1
            ;rozehrivani okenka
            bcf o_f, 2
            bcf PORTC_temp, 5
            bcf PORTC, 5
            return
            
;zamknuti
t1_07       bsf locked, 0 ;nastavi registr locked
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
t1_08       bcf locked, 0 ;smaze registr locked
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
t1_09       nop
            return

;odskok dvere 1
t1_10       bsf o_b, 4
            movlw b'11111' ;port D7
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call setout ;smaz port v prc
            bsf casov, ODSKOK
            movlw .8
            movwf timods
            return
            
;odskok dvere 2
t1_11       bsf o_b, 5
            bsf PORTC_temp, 7
            bsf PORTC, 7
            bsf casov, ODSKOK
            movlw .8
            movwf timods
            return
            
;odskok dvere 3
t1_12       btfsc o_i, 4
            return
            bsf o_b, 6
            bsf PORTB_temp, 2
            bsf PORTB, 2
            bsf casov, ODSKOK
            movlw .8
            movwf timods
            return
            
;odskok dvere 4
t1_13       btfsc o_i, 4
            return
            bsf o_b, 7
            bsf PORTB_temp, 3
            bsf PORTB, 3
            bsf casov, ODSKOK
            movlw .8
            movwf timods
            return
            
;odskok kufr
t1_14       bsf o_b, 3
            bsf PORTB_temp, 4
            bsf PORTB, 4
            bsf casov, ODSKOK
            movlw .8
            movwf timods
            return
            
;odskok nadrz
t1_15       bsf o_e, 0
            bsf PORTB_temp, 5
            bsf PORTB, 5
            bsf casov, ODSKOK
            movlw .8
            movwf timods
            return
            
;odskok kapota
t1_16       bsf o_c, 0
            bsf PORTB_temp, 6
            bsf PORTB, 6
            bsf casov, ODSKOK
            movlw .8
            movwf timods
            return
            
;pripraveno
t1_17       nop
            return
;pripraveno
t1_18       nop
            return
;pripraveno
t1_19       nop
            return

;play pause
t1_20       bsf o_d, 1
            movlw b'10000' ;port C0
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call setout ;nastav port v prc
            return
            
;stop
t1_21       bsf o_d, 2
            movlw b'10001' ;port C1
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call setout ;nastav port v prc
            return
            
;forwind
t1_22       bsf o_d, 3
            movlw b'10010' ;port C2
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call setout ;nastav port v prc
            return
            
;rewind
t1_23       bsf o_d, 4
            movlw b'10011' ;port C3
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call setout ;nastav port v prc
            return
            
;volume +
t1_24       bsf o_d, 5
            movlw b'10100' ;port C4
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call setout ;nastav port v prc
            return
            
;volume -
t1_25       bsf o_d, 6
            movlw b'10101' ;port C5
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            call setout ;nastav port v prc
            return
            
;rozehrivani okenka
t1_26       movf o_f, W
            movwf r5

            btfss r5, 2
            bsf PORTC_temp, 5
            btfss r5, 2
            bsf PORTC, 5
            btfss r5, 2
            bsf o_f, 2 
        
            btfsc r5, 2
            bcf PORTC_temp, 5
            btfsc r5, 2
            bcf PORTC, 5
            btfsc r5, 2
            bcf o_f, 2 
            return
            
;pripraveno
t1_27       nop
            return
;pripraveno
t1_28       nop
            return
;pripraveno
t1_29       nop
            return

;okno 1 up        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ve vsech oknech dodelat drobne veci typu pokud je uplne nahore, tak se prepne dolu
t1_30       bsf PCLATH,3 ;Select page 1
            call o1up
            bcf PCLATH,3 ;Select page 0
            ; zapne casovac na vypnuti
            bsf casov, ODSKOK
            movlw .16 ; o neco déle než odskok
            movwf timods
            return
            
;okno 2 up
t1_31       bsf PCLATH,3 ;Select page 1
            call o2up
            bcf PCLATH,3 ;Select page 0
            ; zapne casovac na vypnuti
            bsf casov, ODSKOK
            movlw .16 ; o neco déle než odskok
            movwf timods
            return
            
;okno 3 up
t1_32       return;btfsc o_i, 4
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
t1_33       return;btfsc o_i, 4
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
t1_34       bsf PCLATH,3 ;Select page 1
            call o1down
            bcf PCLATH,3 ;Select page 0
            ; zapne casovac na vypnuti
            bsf casov, ODSKOK
            movlw .16 ; o neco déle než odskok
            movwf timods
            return
            
;okno 2 down
t1_35       bsf PCLATH,3 ;Select page 1
            call o2down
            bcf PCLATH,3 ;Select page 0
            ; zapne casovac na vypnuti
            bsf casov, ODSKOK
            movlw .16 ; o neco déle než odskok
            movwf timods
            return
            
;okno 3 down
t1_36       return;btfsc o_i, 4
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
            
;detský zámek zadních oken a dveri
t1_37       btfss o_i, 4 ;zmeni stav indikace detskeho zamku
            goto t2_37
            bcf o_i, 4
            movlw b'11100' ;port D4
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call clrout ;nastav port v prc        
            return
            
t2_37       bsf o_i, 4
            movlw b'11100' ;port D4
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call setout ;nastav port v prc        
            return
            
;pripraveno
t1_38       nop
            return
;pripraveno
t1_39       nop
            return

;RED tuning
t1_40       movlw b'10110' ;port C6
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
t1_41       movlw b'10111' ;port C7
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
            
;Parkovačky
t1_42       movf o_e, W
            movwf r5

            btfss r5, 3
            bsf PORTD_temp, 5
            btfss r5, 3
            bsf PORTD, 5
            btfss r5, 3
            bsf o_e, 3 
        
            btfsc r5, 3
            bcf PORTD_temp, 5
            btfsc r5, 3
            bcf PORTD, 5
            btfsc r5, 3
            bcf o_e, 3 
            return
            
;Světla
t1_43       movf o_c, W
            movwf r5

            btfss r5, 1
            bsf PORTC_temp, 3
            btfss r5, 1
            bsf PORTC, 3
            btfss r5, 1
            bsf o_c, 1 
        
            btfsc r5, 1
            bcf PORTC_temp, 3
            btfsc r5, 1
            bcf PORTC, 3
            btfsc r5, 1
            bcf o_c, 1 
            return
            
;Mlhovky zadní
t1_44       movf o_f, W
            movwf r5

            btfss r5, 1
            bsf PORTC_temp, 4
            btfss r5, 1
            bsf PORTC, 4
            btfss r5, 1
            bsf o_f, 1 
        
            btfsc r5, 1
            bcf PORTC_temp, 4
            btfsc r5, 1
            bcf PORTC, 4
            btfsc r5, 1
            bcf o_f, 1 
            return
            
;Blinkr levý
t1_45       bsf o_e, 4
            bsf PORTD_temp, 6
            bsf PORTD, 6
            return
            
;Blinkr pravý
t1_46       bsf o_e, 5
            bsf PORTD_temp, 7
            bsf PORTD, 7
            return
            
;Mlhovky přední
t1_47       movf o_c, W
            movwf r5

            btfss r5, 5
            bsf PORTD_temp, 1
            btfss r5, 5
            bsf PORTD, 1
            btfss r5, 5
            bsf o_c, 5 
        
            btfsc r5, 5
            bcf PORTD_temp, 1
            btfsc r5, 5
            bcf PORTD, 1
            btfsc r5, 5
            bcf o_c, 5 
            return
            
;pripraveno
t1_48       nop
            return
;pripraveno
t1_49       nop
            return

;klakson
t1_50       bsf o_c, 4
            movlw b'11001' ;port D1
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call setout ;nastav port v prc
            return
            
;stěrače
t1_51       bsf o_c, 7
            bsf PORTD_temp, 3
            bsf PORTD, 3
            return
;odstřikovače
t1_52       bsf o_c, 6
            bsf PORTD_temp, 2
            bsf PORTD, 2
            return
            
;Siréna
t1_53       movlw b'11000' ;port D0
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

;stroboskop
t1_54       movlw b'11001' ;port D1
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
            
;Dálkové světla
t1_55	    bsf o_d, 0
            bsf PORTD_temp, 4
            bsf PORTD, 4
            return
            
;alarm start
t1_56       movlw b'11000' ;port D0  ;sirena
            movwf port
            movlw b'11' ;procesor 3
            movwf prc 
            btfss o_e, 1
            call setout ;set port v prc
            bsf o_e, 1
            ;varovky
            call t1_05
            
            ;stroboskop
            movlw b'11001' ;port D1
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfss o_e, 2
            call setout ;set port v prc
            bsf o_e, 2
            ;red tunning
            movlw b'10110' ;port C6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc 
            btfss o_c, 2
            call setout ;set port v prc
            bsf o_c, 2
            ;white interier
            ;movlw b'11011' ;port D3
            ;movwf port
            ;movlw b'10' ;procesor 2
            ;movwf prc
            ;btfss o_f, 4
            ;call setout ;set port v prc
            ;bsf o_f, 4
            
            bsf casov, ALARM ;zacne problikavat tuning, interier a klakson
            movlw .30
            movwf timala

            return
            
;pripraveno
t1_57       nop
            return
            
;pripraveno
t1_58       nop
            return
            
;pripraveno
t1_59       nop
            return
        
;okno 4 down
t1_60       return;btfsc o_i, 4
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
            
;red interiér
t1_61       movlw b'11010' ;port D2
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
            
;white interier (Baterie na budíkách)
t1_62       movlw b'11011' ;port D3
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
t1_63       bsf o_e, 7
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
t1_64       bsf o_e, 6
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
t1_65       bsf o_f, 5
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
t1_66       bsf o_f, 0
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
t1_67       nop
            return
;pripraveno
t1_68       nop
            return
;pripraveno
t1_69       nop
            return

t1_x        nop
            return
            





w20i        movlw .5
            movwf r4
            decfsz r4, F
            goto $-1
            return

;cekej cca 100 cyklu 40us  + u kazdeho cekani je 7 cyklu povinych
w100c       movlw .80
            movwf r4
            decfsz r4, F
            goto $-1
            return

;cekej necelou polovinu w100c
w40c        movlw .30
            movwf r4
            decfsz r4, F
            goto $-1
            return
            





klakson     movlw b'11001' ;port D1
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            
            movf o_c, W
            movwf r5

            btfss r5, 4
            call setout ;nastav port v prc
            btfss r5, 4
            bsf o_c, 4 
        
            btfsc r5, 4
            call clrout ;smaz port v prc
            btfsc r5, 4
            bcf o_c, 4 
            return


;zmeni stav LED zamceno
ledzam      movlw b'10110' ;port C6
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
restart	    bcf PCLATH,3 ;Select page 0
	    ;Po restartu se obnovi stare registry PORTU

	    movf PORTA_temp, W
	    movwf PORTA
	    movf PORTB_temp, W
	    movwf PORTB
	    movf PORTC_temp, W
	    movwf PORTC
	    movf PORTD_temp, W
	    movwf PORTD
	    movf PORTE_temp, W
	    movwf PORTE

	    ;zapne zadni pasy po restartu
	    movlw b'01110' ;port B6
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call setout ;nastav port v prc
            bsf o_g, 6 
	    
	    movlw b'01111' ;port B7
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call setout ;nastav port v prc
            bsf o_g, 7 

	    ; zapne predni pasy po startu
	    movlw b'01100' ;port B4
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call clrout ;nastav port v prc
            bcf o_g, 4 
	    
	    movlw b'01101' ;port B5
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call clrout ;nastav port v prc
            bcf o_g, 5 

	    movlw .30 ;trochu delsi vterina
	    movwf vterina
        

	    bsf PCLATH,3 ;Select page 0
	    goto loop
    
start       bcf PCLATH,3 ;Select page 0
	    
	    clrf PORTA_temp
	    clrf PORTB_temp
	    clrf PORTC_temp
	    clrf PORTD_temp
	    clrf PORTE_temp

	    call w100c
	    
	    ;call t1_00  ;@todo: Zkouška, aby se po startu vše nevypínalo ;po startu zamkne a zapne alarm
	    
	    ; zapne predni pasy po startu
	    movlw b'01100' ;port B4
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call setout ;nastav port v prc
            bsf o_g, 4 
	    
	    movlw b'01101' ;port B5
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call setout ;nastav port v prc
            bsf o_g, 5 

	    ;zapne zadni pasy po restartu
	    movlw b'01110' ;port B6
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call clrout ;nastav port v prc
            bcf o_g, 6 
	    
	    movlw b'01111' ;port B7
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            call clrout ;nastav port v prc
            bcf o_g, 7 

	    movlw .30
	    movwf vterina
        

	    bsf PCLATH,3 ;Select page 0
	    goto loop

loop	    bcf PCLATH,3 ;Select page 0
	    
	    clrwdt
   
            ;#### Čeká několik cyklů aby se stihly ostatní procesory vzpamatovat z případnejch problémů
            ; Začne počítat čas odpočinku procesorů WATCH2
            call watchstart
            ; Čeká až skončí čas odpočinku procesorů WATCH2
            call watchwait
            
            ; Začne počítat čas odpočinku procesorů WATCH2
            call watchstart
            ; Čeká až skončí čas odpočinku procesorů WATCH2
            call watchwait
            
            ; Začne počítat čas odpočinku procesorů WATCH2
            call watchstart
            ; Čeká až skončí čas odpočinku procesorů WATCH2
            call watchwait
            
            ; Začne počítat čas odpočinku procesorů WATCH2
            call watchstart
            ; Čeká až skončí čas odpočinku procesorů WATCH2
            call watchwait
      
      
      
            btfsc conf, T1OF ;pokud timer 1 přetekl, spustí jeho obsluhu
            call timer1

            bsf PCLATH,3 ;Select page 1
            ;call okna ;spouští obsluhu jednotlivých okének DEBUG
            bcf PCLATH,3 ;Select page 0


            
            
            movlw .0 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            bsf PCLATH,3 ;Select page 1
            call adconv
            bcf PCLATH,3 ;Select page 0
            movf ran1, W
            movwf r1
            
            comf ir_58, W
            addwf r1, F
            movf ADRESH, W
            incfsz r1, F  ;pokud zadna zmena pokracuje dal
            movwf ir_58  ;prepise reg AN prevedenou hodnotou
            movf r1, W
            bcf PCLATH,3 ;Select page 0
            btfss STATUS, Z
            call if_58  ;pokud zmena odesle na sbernici
            
            
            movlw .1 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            bsf PCLATH,3 ;Select page 1
            call adconv
            bcf PCLATH,3 ;Select page 0
            movf ran1, W
            movwf r1
            
            comf ir_62, W
            addwf r1, F
            movf ADRESH, W
            incfsz r1, F  ;pokud zadna zmena pokracuje dal
            movwf ir_62  ;prepise reg AN prevedenou hodnotou
            movf r1, W
            bcf PCLATH,3 ;Select page 0
            btfss STATUS, Z
            call if_62  ;pokud zmena odesle na sbernici
            
            
            movlw .2 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            bsf PCLATH,3 ;Select page 1
            call adconv
            bcf PCLATH,3 ;Select page 0
            movf ran1, W
            movwf r1
            
            comf ir_50, W
            addwf r1, F
            movf ADRESH, W
            incfsz r1, F  ;pokud zadna zmena pokracuje dal
            movwf ir_50  ;prepise reg AN prevedenou hodnotou
            movf r1, W
            bcf PCLATH,3 ;Select page 0
            btfss STATUS, Z
            call if_50  ;pokud zmena odesle na sbernici
            
            
            movlw .3 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            bsf PCLATH,3 ;Select page 1
            call adconv
            bcf PCLATH,3 ;Select page 0
            movf ran1, W
            movwf r1
            
            comf ir_59, W
            addwf r1, F
            movf ADRESH, W
            incfsz r1, F  ;pokud zadna zmena pokracuje dal
            movwf ir_59  ;prepise reg AN prevedenou hodnotou
            movf r1, W
            bcf PCLATH,3 ;Select page 0
            btfss STATUS, Z
            call if_59  ;pokud zmena odesle na sbernici
            
            
            movlw .4 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            bsf PCLATH,3 ;Select page 1
            call adconv
            bcf PCLATH,3 ;Select page 0
            movf ran1, W
            movwf r1
            
            comf ir_60, W
            addwf r1, F
            movf ADRESH, W
            incfsz r1, F  ;pokud zadna zmena pokracuje dal
            movwf ir_60  ;prepise reg AN prevedenou hodnotou
            movf r1, W
            bcf PCLATH,3 ;Select page 0
            btfss STATUS, Z
            call if_60  ;pokud zmena odesle na sbernici
            
            
            movlw .5 ;nastavime ANx kde x je zadane cislo
            movwf ran1
            bsf PCLATH,3 ;Select page 1
            call adconv
            bcf PCLATH,3 ;Select page 0
            movf ran1, W
            movwf r1
            
            comf ir_61, W
            addwf r1, F
            movf ADRESH, W
            incfsz r1, F  ;pokud zadna zmena pokracuje dal
            movwf ir_61  ;prepise reg AN prevedenou hodnotou
            movf r1, W
            bcf PCLATH,3 ;Select page 0
            btfss STATUS, Z
            call if_61  ;pokud zmena odesle na sbernici
            
            
            
            


            ; Začne počítat čas pro procesor WATCH2
            call watchstart

            ;dotaz na procesor 2
            movlw .2  ;oznaceni ciloveho procesoru
            movwf cil
            call dotaz  ;prijem dat z procesoru do pri0 - pri7
    
            ; Čeká až doběhne čas vyhrazený pro tento procesor WATCH2
            call watchwait
    
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


            ; Začne počítat čas pro procesor WATCH2
            call watchstart

            ;dotaz na procesor 3
            movlw .3  ;oznaceni ciloveho procesoru
            movwf cil
            call dotaz  ;prijem dat z procesoru do pri0 - pri7
            
            ; Čeká až doběhne čas vyhrazený pro tento procesor WATCH2
            call watchwait
            
    
    
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



            ; Začne počítat čas pro procesor WATCH2
            call watchstart

            ;dotaz na procesor 4
            movlw .4  ;oznaceni ciloveho procesoru
            movwf cil
            call dotaz  ;prijem dat z procesoru do pri0 - pri7
            
            ; Čeká až doběhne čas vyhrazený pro tento procesor WATCH2
            call watchwait
            
    
    
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



            bsf PCLATH,3 ;Select page 1
            goto loop      ;zpet v cyklu na zacatek
        
        
        






okna        movf ir_90, W
            andlw b'11110000' ;odseknu konecnou cast
            movwf r1
            comf r1, F ;udelám dvojkový doplněk
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
okno2       movf ir_91, W
            andlw b'11110000' ;odseknu konecnou cast
            movwf r1
            comf r1, F ;udelám dvojkový doplněk
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
okno3       movf ir_92, W
            andlw b'11110000' ;odseknu konecnou cast
            movwf r1
            comf r1, F ;udelám dvojkový doplněk
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
okno4       movf ir_93, W
            andlw b'11110000' ;odseknu konecnou cast
            movwf r1
            comf r1, F ;udelám dvojkový doplněk
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
o1up        btfsc o_a, 3
            goto no1up
            movlw b'11101' ;port D5
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
        
            bcf PCLATH,3 ;Select page 0
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_a, 3 
no1up       btfss o_a, 7
            return
            movlw b'01100' ;port B4
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 0
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 7             
            return
o1down      btfss o_a, 3
            goto no1down
            movlw b'11101' ;port D5
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            
            bcf PCLATH,3 ;Select page 0
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 3 
no1down     btfsc o_a, 7
            return
            movlw b'01100' ;port B4
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_a, 7             
            return
o1stop      btfss o_a, 3
            goto no1stop
            movlw b'11101' ;port D5
            movwf port
            movlw b'11' ;procesor 3
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 3 
no1stop     btfss o_a, 7
            return
            movlw b'01100' ;port B4
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 7             
            return
;okno 2 nahoru, dolu, zastavit
o2up        btfsc o_a, 4
            goto no2up
            movlw b'11000' ;port D0
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_a, 4 
no2up       btfss o_b, 0
            return
            movlw b'01101' ;port B5
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_b, 0             
            return
o2down      btfss o_a, 4
            goto no2down
            movlw b'11000' ;port D0
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 4 
no2down     btfsc o_b, 0
            return
            movlw b'01101' ;port B5
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_b, 0             
            return
o2stop      btfss o_a, 4
            goto no2stop
            movlw b'11000' ;port D0
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 4 
no2stop     btfss o_b, 0
            return
            movlw b'01101' ;port B5
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_b, 0             
            return
;okno 3 nahoru, dolu, zastavit
o3up        btfsc o_a, 5
            goto no3up
            movlw b'01010' ;port B2
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_a, 5 
no3up       btfss o_b, 1
            return
            movlw b'01110' ;port B6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_b, 1             
            return
o3down      btfss o_a, 5
            goto no3down
            movlw b'01010' ;port B2
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 5 
no3down     btfsc o_b, 1
            return
            movlw b'01110' ;port B6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_b, 1             
            return
o3stop      btfss o_a, 5
            goto no3stop
            movlw b'01010' ;port B2
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 5 
no3stop     btfss o_b, 1
            return
            movlw b'01110' ;port B6
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_b, 1             
            return
;okno 4 nahoru, dolu, zastavit
o4up        btfsc o_a, 6
            goto no4up
            movlw b'01011' ;port B3
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_a, 6 
no4up       btfss o_b, 2
            return
            movlw b'01111' ;port B7
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_b, 2             
            return
o4down      btfss o_a, 6
            goto no4down
            movlw b'01011' ;port B3
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 6 
no4down     btfsc o_b, 2
            return
            movlw b'01111' ;port B7
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call setout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bsf o_b, 2             
            return
o4stop      btfss o_a, 6
            goto no4stop
            movlw b'01011' ;port B3
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_a, 6 
no4stop     btfss o_b, 2
            return
            movlw b'01111' ;port B7
            movwf port
            movlw b'10' ;procesor 2
            movwf prc
            
            bcf PCLATH,3 ;Select page 1
            call clrout ;smaz port v prc
            bsf PCLATH,3 ;Select page 1
            bcf o_b, 2             
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