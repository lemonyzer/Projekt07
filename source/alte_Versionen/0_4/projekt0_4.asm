; *******************************************************
; * Projekt06.asm - Playstation Controller an PIC16F84A *
; *******************************************************
;
;	KOMMT NOCH.... 
;
;
; **************************************************************
; *			Changelog 0_3			*
; **************************************************************
;
; UP_Bit0 hinzugefügt
; UP_Bit1 hinzugefügt
;
; UP_Start an UP_BitX angepasst (Codeverkürzung - Abarbeitungszeit=LÄNGER)
; UP_Sende0 an UP_BitX angepasst 			"
; UP_Sende0_schleife an UP_BitX angepasst		"
;
;
;***************************************************************************
;* Bestimmung des Prozessortyps für den Assembler und das Programmiergerät *
;***************************************************************************

		LIST p=16F84A


;*******************************************************************
;* Includedatei für den 16F84A einbinden (vordef. Reg. und Konst.) *
;*******************************************************************

		#include <p16f84A.INC>

; Diese Datei enthält Vordefinitionen für wichtige Register und Konstanten.
; (Z.B. gibt es die Konstante PORTB mit der sich ohne Angabe der
; absoluten Adresse H'0006' der Port B des Prozessors ansprechen lässt)


;*********************************************************
;* Konfigurationseinstellungen für IC-Prog vordefinieren *
;*********************************************************

		__CONFIG _PWRTE_ON & _CP_OFF & _HS_OSC & _WDT_OFF

; Hier werden verschiedene Prozessoreigenschaften festgelegt:
; _PWRTE_ON schaltet den Power Up Timer ein, d.h. der Prozessor wartet nach
;           dem Einschalten ca. 70ms mit dem Programmstart, um sicher zu sein,
;           dass alle angeschlossene Peripherie bereit ist.
; _CP_OFF schaltet die Code-Protection des Prozesors aus. Damit ist das im Prozessor
;        befindliche Programm jederzeit auslesbar und überschreibbar.
; _HS_OSC spezifiziert einen Quarzoszillator (Highspeed) als Zeitbasis für den Prozessor.
; _WDT_OFF schaltet den Watchdog-Timer des Prozesors aus.


;***********************************
;* Register / Variablen  festlegen *
;***********************************
; hier werden Adressen von Registern / Variablen festgelegt. Diese werden beginnend
; mit der Adresse H'20' aufsteigend vergeben.


	CBLOCK	H'20'
		zaehler_in	;Zaehler innere Schleife
		zaehler_mid	;Zaehler mittlere Schleife
		zaehler_out	;Zaehler aeussere Schleife
		
		cnt_get_btn_stats	;Get_Btn_Stats Schleife
		
		wait250khz	;250kHz zaehler
		
		wait05s
		wait05s_1
		wait05s_2
		

	ENDC
	
	in_cnt		EQU D'0'		;Startwert inner Schleife
	mid_cnt		EQU D'0'		;Startwert mittlere ""
	out_cnt		EQU D'1'		;Startwert äussere ""
	
	get_btn_stats_cnt	EQU D'7'		;Startwert Get_Btn_Stats Schleife


;************************
;* Konstanten festlegen * 
;************************



; ***********************************************************************
; * Definition von einzelnen Bits in einem Register / in einer Variable *
; ***********************************************************************

;#####################################################################
#DEFINE	e_data		PORTA, 0		; Data		Eingang
#DEFINE	a_command	PORTA, 1		; Command	Ausgang
#DEFINE	a_clock		PORTA, 2		; Takt		Ausgang
#DEFINE	a_att		PORTA, 3		; ATT		Ausgang
;#####################################################################
#DEFINE	a_test		PORTB, 0		; Tets LED	Ausgang
;#####################################################################
#DEFINE	a1		PORTB, 0		; BCD-Decoder	Ausgang
#DEFINE	b1		PORTB, 1		; BCD-Decoder	Ausgang
#DEFINE	c1		PORTB, 2		; BCD-Decoder	Ausgang
#DEFINE	d1		PORTB, 3		; BCD-Decoder	Ausgang
;#####################################################################
#DEFINE	a2		PORTB, 4		; BCD-Decoder	Ausgang
#DEFINE	b2		PORTB, 5		; BCD-Decoder	Ausgang
#DEFINE	c2		PORTB, 6		; BCD-Decoder	Ausgang
#DEFINE	d2		PORTB, 7		; BCD-Decoder	Ausgang
;#####################################################################
#DEFINE	bank1		STATUS, RP0
;#####################################################################



; In diesem Beispiel steht das Wort ir_sensor für Bit 0 von Port A und das Wort motor
; für das Bit 0 von Port B.


;*****************
;* Programmstart *
;*****************

	ORG	H'00'		; Das Programm wird ab Speicherstelle 0 in den Speicher geschrieben
	GOTO	init		; Springe zur Grundinitialisierung der Ports A und B


;*******************
;* Initialisierung *
;*******************

init	BSF	bank1		; wechsle zu Registerbank 1 (spezielle Register)

	MOVLW	B'00000001'
	MOVWF	TRISA		; RA0 Eingang (RA1 bis RA3 sind Ausgänge)
	MOVLW	B'00000000'
	MOVWF	TRISB		; RB0 bis RB7 sind Ausgänge
	
	BCF	bank1		; wechsle zu Registerbank 0 (normaler Speicherbereich)
        
	CLRF	PORTA		; Port A löschen
	CLRF	PORTB		; Port B löschen
        
; Die Register TRISA und TRISB legen fest, welche Bits in den jeweiligen Ports Ein- bzw.
; Ausgänge sind. Eine '1' an der entsprechenden Stelle setzt das Bit des Ports als Ein-
; gang eine '0' setzt das Bit als Ausgang.



;*****************
;* Hauptprogramm *
;*****************

;#######################################################################
;#DEFINE	e_data		PORTA, 0		; Data		Eingang #
;#DEFINE	a_command	PORTA, 1		; Command	Ausgang #
;#DEFINE	a_clock		PORTA, 2		; Takt		Ausgang #
;#DEFINE	a_att		PORTA, 3		; ATT		Ausgang #
;#######################################################################
;#DEFINE	a_test		PORTB, 0		; Tets LED	Ausgang #
;#######################################################################
;#DEFINE	a1		PORTB, 0		; BCD-Decoder	Ausgang #
;#DEFINE	b1		PORTB, 1		; BCD-Decoder	Ausgang #
;#DEFINE	c1		PORTB, 2		; BCD-Decoder	Ausgang #
;#DEFINE	d1		PORTB, 3		; BCD-Decoder	Ausgang #
;#######################################################################
;#DEFINE	a2		PORTB, 4		; BCD-Decoder	Ausgang #
;#DEFINE	b2		PORTB, 5		; BCD-Decoder	Ausgang #
;#DEFINE	c2		PORTB, 6		; BCD-Decoder	Ausgang #
;#DEFINE	d2		PORTB, 7		; BCD-Decoder	Ausgang #
;#######################################################################


main	
	BSF	a_att		; ATT auf HIGH, Controller ignoriert
 				; alle Daten
 				
	BSF	a_clock		; Clock HIGH
	CALL 	UP_wait250khz
	BSF	a_command	; Command HIGH
	CALL 	UP_wait250khz
	
	BCF	a_att		; ATT auf LOW das der Controller
				; die Daten annimmt
	CALL	UP_wait05s
		
	BSF	a1;;;;;;;;;				
	CALL	UP_wait05s				
	CALL	UP_Start		;Empfangen:  H'XX'
				;------------------------------------	
 				;Senden:     H'01' Startbefehl
	BCF	a1;;;;;;;;;
	
	BSF	b1;;;;;;;;;	
	CALL	UP_wait05s
	CALL	UP_GetType	;Empfangen:  H'41'=Digital
 				;ODER	    H'23'=NegCon
				;ODER	    H'73'=Analogue Red LED
				;ODER	    H'53'=Analogue Green LED
				;------------------------------------	
 				;Senden:     H'42' Datenanfrage
	BCF	b1;;;;;;;;;
	
	BSF	c1;;;;;;;;;
	CALL	UP_wait05s
	CALL	UP_Status	;Empfangen:  H'5A'=Status:READY
				;------------------------------------	
 				;Senden:     H'00' Idle
	BCF	c1;;;;;;;;;
	
	BSF	d1;;;;;;;;;
	CALL	UP_wait05s
	CALL	UP_linke_btns	;Empfangen:  H'XX'
				;------------------------------------	
 				;Senden:     H'00' Idle
	BCF	d1;;;;;;;;;
	
	BSF	a2;;;;;;;;;
	CALL	UP_wait05s
	CALL	UP_rechte_btns	;Empfangen:  H'XX'
				;------------------------------------	
 				;Senden:     H'00' Idle
	BCF	a2;;;;;;;;;
	
	BSF	b2;;;;;;;;;
	CALL	UP_wait05s
	CALL	UP_sende0	;#########################
	CALL	UP_sende0	;Hier kommen die Joysticks
	CALL	UP_sende0	;die abgefragt werden aber
	CALL	UP_sende0	;nicht gespeichert
	BCF	b2;;;;;;;;;	




	GOTO	main


;******************
;* Unterprogramme *
;******************

;PSX_TxRx:
;  FOR idx = 0 TO 7
;    PsxCmd = psxOut.LOWBIT(idx)                 setup command bit
;    PsxClk = ClockMode                          clock the bit (low)
;    psxIn.LOWBIT(idx) = PsxDat                  get data bit
;    PsxClk = ~ClockMode                         r(high)
;  NEXT

;###############################################################################
UP_Start	
	;H'01' (Bitfolge 00000001) muss im LSB-Verfahren über 
	;a_command gesendet werden.
	
;0	
	;Bit 1 Senden
	CALL 	UP_Bit1
;1	
	;Bit 0 Senden
	CALL 	UP_Bit0
;2
	;Bit 0 Senden
	CALL 	UP_Bit0
;3	
	;Bit 0 Senden
	CALL 	UP_Bit0
;4
	;Bit 0 Senden
	CALL 	UP_Bit0
;5	
	;Bit 0 Senden
	CALL 	UP_Bit0
;6
	;Bit 0 Senden
	CALL 	UP_Bit0
;7	
	;Bit 0 Senden
	CALL 	UP_Bit0

RETURN      	
;###############################################################################
UP_GetType	
	;H'42' (Bitfolge 01000010) muss im LSB-Verfahren über 
	;a_command gesendet werden.
	
;0	
	;Bit 0 Senden
	CALL 	UP_Bit0
;1	
	;Bit 1 Senden
	CALL 	UP_Bit1
;2
	;Bit 0 Senden
	CALL 	UP_Bit0
;3	
	;Bit 0 Senden
	CALL 	UP_Bit0
;4
	;Bit 0 Senden
	CALL 	UP_Bit0
;5	
	;Bit 0 Senden
	CALL 	UP_Bit0
;6
	;Bit 1 Senden
	CALL 	UP_Bit1
;7	
	;Bit 0 Senden
	CALL 	UP_Bit0
	
	
RETURN
;###############################################################################
UP_Status	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_command gesendet werden.
	
;0	
	;Bit 0 Senden
	CALL 	UP_Bit0
;1	
	;Bit 0 Senden
	CALL 	UP_Bit0
;2
	;Bit 0 Senden
	CALL 	UP_Bit0
;3	
	;Bit 0 Senden
	CALL 	UP_Bit0
;4
	;Bit 0 Senden
	CALL 	UP_Bit0
;5	
	;Bit 0 Senden
	CALL 	UP_Bit0
;6
	;Bit 0 Senden
	CALL 	UP_Bit0
;7	
	;Bit 0 Senden
	CALL 	UP_Bit0

RETURN
;###############################################################################
UP_linke_btns	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_command gesendet werden.
	
	; Pfeiltaste nach links <-
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz	
	BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	c1	
	BSF	a_clock		; Clock HIGH
	
	; Pfeiltaste nach unten \/
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a1
	BSF	a_clock		; Clock HIGH	
	
	; Pfeiltaste nach rechts ->
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	b1
	BSF	a_clock		; Clock HIGH
	
	; Pfeiltaste nach oben /\
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	d1
	BSF	a_clock		; Clock HIGH
	
	; Start
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; Joy-R
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; Joy-L
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; Select
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH

RETURN
;###############################################################################
UP_rechte_btns	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_command gesendet werden.
	
	; [] - Quadrat Taste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz	
	;BTFSC	e_data		; e_data in Register speichern - controller type	
	BSF	a_clock		; Clock HIGH
	
	; X - X Taste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH	
	
	; O - Kreis Taste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; /.\ - Dreick Taste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; R1 - Schultertaste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; L1 - Schultertaste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; R2 - Schultertaste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
	
	; L2 - Schultertaste
	;#####################
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH

RETURN
;###############################################################################
UP_sende0
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_command gesendet werden.
;0	
	;Bit 0 Senden
	CALL 	UP_Bit0
;1	
	;Bit 0 Senden
	CALL 	UP_Bit0
;2
	;Bit 0 Senden
	CALL 	UP_Bit0
;3	
	;Bit 0 Senden
	CALL 	UP_Bit0
;4
	;Bit 0 Senden
	CALL 	UP_Bit0
;5	
	;Bit 0 Senden
	CALL 	UP_Bit0
;6
	;Bit 0 Senden
	CALL 	UP_Bit0
;7	
	;Bit 0 Senden
	CALL 	UP_Bit0

RETURN
;###############################################################################
UP_sende0_schleife	
	MOVLW	get_btn_stats_cnt		;Startwert innere Schleife
	MOVWF	cnt_get_btn_stats
	
loop_btn_stats	
		CALL 	UP_Bit0
		
		DECFSZ	cnt_get_btn_stats, F	; innnere Schleife
		GOTO	loop_btn_stats
		
RETURN
;###############################################################################	
UP_wait	
	MOVLW	out_cnt	;Startwert äussere Schleife
	MOVWF	zaehler_out

loop_out
	MOVLW	mid_cnt	;Startwert mittlere Schleife
	MOVWF	zaehler_mid

loop_mid	
	MOVLW	in_cnt	;Startwert innere Schleife
	MOVWF	zaehler_in
	
loop_in	
	DECFSZ	zaehler_in, F; innnere Schleife
	GOTO	loop_in
	
	DECFSZ	zaehler_mid, F; mittlere Schleife
	GOTO	loop_mid
	
	DECFSZ	zaehler_out, F; äussere Schleife
	GOTO	loop_out
	
RETURN
;###############################################################################
UP_wait250khz
			;19 cycles
	movlw	0x06
	movwf	wait250khz
Delay_0
	decfsz	wait250khz, f
	goto	Delay_0

			;1 cycle
	nop
	
RETURN
;###############################################################################
UP_wait05s
			;2499999 cycles
	movlw	0x16
	movwf	wait05s
	movlw	0x74
	movwf	wait05s_1
	movlw	0x06
	movwf	wait05s_2
Delay_05
	decfsz	wait05s, f
	goto	$+2
	decfsz	wait05s_1, f
	goto	$+2
	decfsz	wait05s_2, f
	goto	Delay_05

			;1 cycle
	nop
RETURN
;###############################################################################
UP_Bit0	
	;Bit 0 Senden
	CALL 	UP_wait250khz
	BCF	a_command	; "0" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
RETURN
;###############################################################################
UP_Bit1	
	;Bit 1 Senden
	CALL 	UP_wait250khz
	BSF	a_command	; "1" senden
	BCF	a_clock		; Clock LOW
	CALL 	UP_wait250khz
	;BTFSC	e_data		; e_data in Register speichern - controller type
	BSF	a_clock		; Clock HIGH
RETURN
;###############################################################################
END
