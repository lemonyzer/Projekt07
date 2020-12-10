; **********************************************************
; * projekt_beta_1.asm - Playstation Controller an PIC16F84A *
; **********************************************************
;
;	Der PIC soll mit einem PS-Controller kommunizieren
;	und erkennen welche Tasten auf dem Controller gedrückt wurden.
;
;	Wenn er weiß was gedrückt wurde, schaltet er die zu den
;	entsprechenden Tasten gehörenden LED's ein bzw. aus.
;
;	Optional:
;			Kommunikation mit dem PC (RS232)
;			um einen PS-PC Konverter zu ermöglichen
;
; #############################################################################
;
;	D: Digitaler Controller (keine Joysticks)
;	A: Analoger Controller (2 Joysticks)
;
;RxByte	Type	Taste	Hex	Binär
;-------------------------------------------	
;1	D/A	Left	0xFE	11111110
;1	D/A	Down	0xFD	11111101
;1	D/A	Right	0xFB	11111011
;1	D/A	Up	0xF7	11110111
;1	D/A	Start	0xEF	11101111
;1	A	Joy-R	0xDF	11011111	---- Nur Analoger Controller
;1	A	Joy-L	0xBF	10111111	---- Nur Analoger Controller
;1	D/A	Select	0x7F	01111111
;-------------------------------------------
;2	D/A	[]	0xFE	11111110
;2	D/A	X	0xFD	11111101
;2	D/A	O	0xFB	11111011
;2	D/A	/_\	0xF7	11110111
;2	D/A	R1	0xEF	11101111	
;2	D/A	L1	0xDF	11011111
;2	D/A	R2	0xBF	10111111
;2	D/A	L2	0x7F	01111111
;-------------------------------------------
;  Mehrere Buttons werden UND Verknüpft...
;-------------------------------------------
;	A	Joy-R-X	
;	A	Joy-R-X	
;	A	Joy-R-X	
;	A	Joy-R-X	
;	A	Joy-R-X	
;	A	Joy-R-X	
;	A	Joy-R-X	
;	A	Joy-R-X	
;	-----------------------------------
;	A	Joy-R-Y	
;	A	Joy-R-Y	
;	A	Joy-R-Y
;	A	Joy-R-Y	
;	A	Joy-R-Y	
;	A	Joy-R-Y	
;	A	Joy-R-Y	
;	A	Joy-R-Y	
;	-----------------------------------
;	A	Joy-L-X	
;	A	Joy-L-X	
;	A	Joy-L-X	
;	A	Joy-L-X	
;	A	Joy-L-X	
;	A	Joy-L-X	
;	A	Joy-L-X	
;	A	Joy-L-X	
;	-----------------------------------
;	A	Joy-L-Y	
;	A	Joy-L-Y	
;	A	Joy-L-Y	
;	A	Joy-L-Y	
;	A	Joy-L-Y	
;	A	Joy-L-Y	
;	A	Joy-L-Y	
;	A	Joy-L-Y	
;	-----------------------------------
;
;
; **************************************************************
; *			Changelog beta_1			*
; **************************************************************
;	sXXXXX	Register Verarbeitung geändert
;	zaehler	Register Verarbeitung geändert
;
;	main	programmpositions LED-Anzeige geändert
; **************************************************************
; *			Changelog 0_7_5			*
; **************************************************************
;	Warteschleifen geändert:
;
;		UP_wait_25us <- hinzugefügt	CLOCK
;		UP_wait_50us <- hinzugefügt	ATT
;
; **************************************************************
; *			Changelog 0_7_4			*
; **************************************************************
;	Empfangsabfrage zurück auf 0_7_2
;	Warteschleifen geändert:
;
;		UP_wait_5us <- hinzugefügt		CLOCK
;		UP_wait_20us <- hinzugefügt	ATT
;
;		UP_wait_4us <- durch UP_wait_5us ersetzt
;		UP_wait_100us <- gelöscht
; **************************************************************
; *			Changelog 0_7_3			*
; **************************************************************
;	Empfangsabfrage geändert...
; **************************************************************
; *			Changelog 0_7_2			*
; **************************************************************
;
;	UP_wait_100us hinzugefügt (ausgetauscht mit UP_wait_4us)
;
;  	
; **************************************************************
; *			Changelog 0_7_1			*
; **************************************************************
;
;	UP_wait_05s hinzugefügt
;
;	Anzeigeroutine folgender Register hinzugefügt:
;	 - gSTATUS,gLEFT,gRIGHT,gRJoyX,gRJoyY,gLJoyX,gLJoyY
;
;	kleine Bugfixes
;
; **************************************************************
; *			Changelog 0_7			*
; **************************************************************
;
;	KOMPLETT NEUE Sende- & Empfangsroutine
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
	
		zaehler		;Übertragungszähler (Bits)

		sSTART		;START-Befehl     (00000001)

		sTYPE		;GET TYPE-Befehl  (01000010)
		gTYPE		;Empfangene Daten nach dem GET TYPE Befehl

		gSTATUS		;Status des Controllers (0x5A wenn bereit)
		rSTATUS		;Register um gSTATUS mit 0x5A zu vergleichen

		gLEFT		;Status der Buttons: 
				;<- | \/ | -> | /\ | Start | JL | JR | Select
		
		gRIGHT		;Status der Buttons:
				;[] | X | O | /_\ | R1 | L1 | R2 | L2
				
		gRJoyX		;X Position des rechten Joysticks
		gRJoyY		;Y Position des rechten Joysticks
		
		gLJoyX		;X Position des linken Joysticks
		gLJoyY		;X Position des linken Joysticks
		
		;wait_20us	;Wartezeit nach dem a_ATT auf 0 geht
		wait_50us	;Wartezeit nach dem a_ATT auf 0 geht    ;NEW
		
		;wait_5us		;Wartezeit zwischen CLOCK LOW und HIGH
		wait_25us	;Wartezeit zwischen CLOCK LOW und HIGH  ;NEW
		
		wait_05s
		wait_05s_1
		wait_05s_2
	
	ENDC


;************************
;* Konstanten festlegen * 
;************************



; ***********************************************************************
; * Definition von einzelnen Bits in einem Register / in einer Variable *
; ***********************************************************************

;##################### Verbindungen zum Controller ################### 
;##################### ___________________________ ###################
#DEFINE	e_DATA		PORTA, 0		; Data		Eingang
#DEFINE	a_COMMAND	PORTA, 1		; Command	Ausgang
#DEFINE	a_CLOCK		PORTA, 2		; Takt		Ausgang
#DEFINE	a_ATT		PORTA, 3		; ATT		Ausgang

;###################### Verbindungen zur Anzeige ##################### 
;###################### ________________________ #####################
#DEFINE	a1		PORTB, 0		; 		Ausgang
#DEFINE	b1		PORTB, 1		; 		Ausgang
#DEFINE	c1		PORTB, 2		; 		Ausgang
#DEFINE	d1		PORTB, 3		; 		Ausgang
;###############################
#DEFINE	a2		PORTB, 4		; 		Ausgang
#DEFINE	b2		PORTB, 5		; 		Ausgang
#DEFINE	c2		PORTB, 6		; 		Ausgang
#DEFINE	d2		PORTB, 7		; 		Ausgang
;#####################################################################
#DEFINE	bank1		STATUS, RP0
;#####################################################################

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
	MOVWF	TRISA		; RA0 Eingang (RA1 bis RA7 sind Ausgänge)
	MOVLW	B'00000000'
	MOVWF	TRISB		; RB0 bis RB7 sind Ausgänge
	
; Die Register TRISA und TRISB legen fest, welche Bits in den jeweiligen Ports Ein- bzw.
; Ausgänge sind. Eine '1' an der entsprechenden Stelle setzt das Bit des Ports als Ein-
; gang eine '0' setzt das Bit als Ausgang.
	
	BCF	bank1		; wechsle zu Registerbank 0 (normaler Speicherbereich)
	        
	CLRF	PORTA		; Port A löschen
	CLRF	PORTB		; Port B löschen
	CLRF	gTYPE
	CLRF	gSTATUS
	CLRF	gLEFT
	CLRF	gRIGHT
	CLRF	gRJoyX
	CLRF	gRJoyY
	CLRF	gLJoyX
	CLRF	gLJoyY
	
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	
	MOVLW	B'00000001'	
	MOVWF	sSTART		;START-Befehl     (00000001) = H'01'
	
	MOVLW	B'01000010'	
	MOVWF	sTYPE		;GET-TYPE-Befehl  (01000010) = H'42'
	
	MOVLW	B'01011010'	
	MOVWF	rSTATUS		;rSTATUS = Status des Controller wenn bereit
				;0x5A = 1011010
;*****************
;* Hauptprogramm *
;*****************

main
    	CALL	UP_wait_50us	;	
	BSF	a_ATT		; ATT auf HIGH, Controller wird abgewählt
				; (ignoriert alle Daten)
	CALL	UP_wait_25us
	BSF	a_CLOCK		; Clock HIGH
	BSF	a_COMMAND	; Command HIGH
	
	BCF	a_ATT		; ATT auf LOW das der Controller
				; die Daten annimmt
					
	CALL	UP_wait_50us	; Warteschlange bis Controller bereit ist
	
;#########		
	BSF	a1;;;;;;;;;								
	CALL	UP_Start		;Senden:		H'01' Startbefehl
	BCF	a1;;;;;;;;;
;#########	
	BSF	b1;;;;;;;;;	
	CALL	UP_Get_Type	;Senden:		H'42' Datenanfrage
 				;------------------------------------
				;Empfangen:	H'41'=Digital
 				;ODER		H'23'=NegCon
				;ODER		H'73'=Analogue Red LED
				;ODER		H'53'=Analogue Green LED
	BCF	b1;;;;;;;;;
;#########
	BSF	c1;;;;;;;;;
	CALL	UP_Get_Status	;Empfangen:  H'5A' - Status:READY
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
	BCF	c1;;;;;;;;;
;#########
	BSF	d1;;;;;;;;;
	CALL	UP_Get_L_btns	;Empfangen:  H'xx' - Status der linken Btns
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
	BCF	d1;;;;;;;;;
;#########
	BSF	a1;;;;;;;;;
	CALL	UP_Get_R_btns	;Empfangen:  H'xx' - Status der rechten Btns
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
	BCF	a1;;;;;;;;;
;#########
	BSF	b1;;;;;;;;;
	CALL	UP_Get_R_Joy_X	;Empfangen:  H'xx' - rechtes Joystick, X-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
	BCF	b1;;;;;;;;;
;#########
	BSF	c1;;;;;;;;;
	CALL	UP_Get_R_Joy_Y	;Empfangen:  H'xx' - rechtes Joystick, Y-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
	BCF	c1;;;;;;;;;
;#########
	BSF	d1;;;;;;;;;
	CALL	UP_Get_L_Joy_X	;Empfangen:  H'xx' - linkes Joystick, X-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
	BCF	d1;;;;;;;;;
;#########
	BSF	a2;;;;;;;;;
	CALL	UP_Get_L_Joy_Y	;Empfangen:  H'xx' - linkes Joystick, Y-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
	BCF	a2;;;;;;;;;	
;#########

	 CALL	UP_Show_btns	;Ausgabe der gXXXX (g=> GET) Register

;#########
	 
	 

GOTO	main			;Springe wieder an den Anfang zurück   

;******************
;* Unterprogramme *
;******************
;###############################################################################
;###############################################################################
UP_Start	
	;H'01' (Bitfolge 00000001) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	
	MOVLW	B'00000001'	
	MOVWF	sSTART		;START-Befehl     (00000001) = H'01'
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	
Start_1	RRF	sSTART		;verschiebe sSTART nach rechts...
	BTFSS	STATUS,C		;und prüfe Wertigkeit des rausgeworfenen Bits
	GOTO	UP_Bit0		;(STATUS,C=0)-> Übertrage '0' an Controller...
	GOTO	UP_Bit1		;(STATUS,C=1)-> ansonsten Übertrage '1'	

Start_2	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F	;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Startbefehl ausgeführt
	GOTO	Start_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
	
UP_Bit0	BCF	a_COMMAND	;auf 0 setzten
	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	Start_2
	
UP_Bit1	BSF	a_COMMAND	;auf 1 setzten
	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	Start_2
;###############################################################################      	
;###############################################################################
UP_Get_Type	
	;H'42' (Bitfolge 01000010) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	
	MOVLW	B'01000010'	
	MOVWF	sTYPE		;GET-TYPE-Befehl  (01000010) = H'42'
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	
Type_1	RRF	sTYPE		;verschiebe sSTART nach rechts...
	BTFSS	STATUS,C		;und prüfe Wertigkeit des rausgeworfenen Bits
	GOTO	UP_Bit0_write_gTYPE	;(STATUS,C=0)-> Übertrage '0' an Controller...
	GOTO	UP_Bit1_write_gTYPE	;(STATUS,C=1)-> ansonsten Übertrage '1'	

Type_2	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 GET-Type-Befehl ausgeführt
	GOTO	Type_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;###########################################################	
UP_Bit0_write_gTYPE
	BCF	a_COMMAND	;auf 0 setzten
	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	sTYPE0_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	sTYPE0_write_0	;empfangenes Bit in Carry-Flag setzen
sTYPE0_next	
	RLF	gTYPE		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	Type_2
;######################################	
sTYPE0_write_1
	BSF	STATUS,C
	GOTO	sTYPE0_next

sTYPE0_write_0
	BCF	STATUS,C
	GOTO	sTYPE0_next	
;###########################################################
UP_Bit1_write_gTYPE
	BSF	a_COMMAND	;auf 1 setzten
	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	sTYPE1_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	sTYPE1_write_0	;empfangenes Bit in Carry-Flag setzen
sTYPE1_next	
	RLF	gTYPE		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	Type_2
;######################################
sTYPE1_write_1
	BSF	STATUS,C
	GOTO	sTYPE1_next

sTYPE1_write_0
	BCF	STATUS,C
	GOTO	sTYPE1_next
;###############################################################################
;###############################################################################
UP_Get_Status	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	;IDLE-Modus
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	BCF	a_COMMAND	;auf 0 setzten
	
Status_1	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	gSTATUS_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	gSTATUS_write_0	;empfangenes Bit in Carry-Flag setzen
Status_2	
	RLF	gSTATUS		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Status empfangen
	GOTO	Status_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;######################################	
gSTATUS_write_1
	BSF	STATUS,C
	GOTO	Status_2

gSTATUS_write_0
	BCF	STATUS,C
	GOTO	Status_2
;###############################################################################
;###############################################################################
UP_Get_L_btns	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	;IDLE-Modus
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	BCF	a_COMMAND	;auf 0 setzten
	
L_btns_1	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	gLEFT_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	gLEFT_write_0	;empfangenes Bit in Carry-Flag setzen
L_btns_2	
	RLF	gLEFT		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Status der linken Buttons empfangen
 				;<- | \/ | -> | /\ | Start | JL | JR | Select 
	GOTO	L_btns_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;######################################	
gLEFT_write_1
	BSF	STATUS,C
	GOTO	L_btns_2

gLEFT_write_0
	BCF	STATUS,C
	GOTO	L_btns_2
;###############################################################################
;###############################################################################
UP_Get_R_btns	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	;IDLE-Modus
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	BCF	a_COMMAND	;auf 0 setzten
	
R_btns_1	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	gRIGHT_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	gRIGHT_write_0	;empfangenes Bit in Carry-Flag setzen
R_btns_2	
	RLF	gRIGHT		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Status der rechten Buttons empfangen
 				;[] | X | O | /_\ | R1 | L1 | R2 | L2
	GOTO	R_btns_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;######################################	
gRIGHT_write_1
	BSF	STATUS,C
	GOTO	R_btns_2

gRIGHT_write_0
	BCF	STATUS,C
	GOTO	R_btns_2
;###############################################################################
;###############################################################################
UP_Get_R_Joy_X	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	;IDLE-Modus
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	BCF	a_COMMAND	;auf 0 setzten
	
R_JoyX_1	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	gRJoyX_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	gRJoyX_write_0	;empfangenes Bit in Carry-Flag setzen
R_JoyX_2	
	RLF	gRJoyX		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Position des rechten Joysticks (x-Achse)
	GOTO	R_JoyX_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;######################################	
gRJoyX_write_1
	BSF	STATUS,C
	GOTO	R_JoyX_2

gRJoyX_write_0
	BCF	STATUS,C
	GOTO	R_JoyX_2
;###############################################################################
;###############################################################################
UP_Get_R_Joy_Y	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	;IDLE-Modus
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	BCF	a_COMMAND	;auf 0 setzten
	
R_JoyY_1	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	gRJoyY_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	gRJoyY_write_0	;empfangenes Bit in Carry-Flag setzen
R_JoyY_2	
	RLF	gRJoyY		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Position des rechten Joysticks (y-Achse)
	GOTO	R_JoyY_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;######################################	
gRJoyY_write_1
	BSF	STATUS,C
	GOTO	R_JoyY_2

gRJoyY_write_0
	BCF	STATUS,C
	GOTO	R_JoyY_2
;###############################################################################
;###############################################################################
UP_Get_L_Joy_X	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	;IDLE-Modus
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	BCF	a_COMMAND	;auf 0 setzten
	
L_JoyX_1	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	gLJoyX_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	gLJoyX_write_0	;empfangenes Bit in Carry-Flag setzen
L_JoyX_2	
	RLF	gLJoyX		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Position des linken Joysticks (x-Achse)
	GOTO	L_JoyX_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;######################################	
gLJoyX_write_1
	BSF	STATUS,C
	GOTO	L_JoyX_2

gLJoyX_write_0
	BCF	STATUS,C
	GOTO	L_JoyX_2
;###############################################################################
;###############################################################################
UP_Get_L_Joy_Y	
	;H'00' (Bitfolge 00000000) muss im LSB-Verfahren über 
	;a_COMMAND gesendet werden.
	;IDLE-Modus
	
	MOVLW	D'8'		;Anzahl der Bits die pro Befehl gesendet bzw
	MOVWF	zaehler		;empfangen werden sollen
	BCF	a_COMMAND	;auf 0 setzten
	
L_JoyY_1	BCF	a_CLOCK		;negative Flanke (Controller ließt a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	gLJoyY_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	gLJoyY_write_0	;empfangenes Bit in Carry-Flag setzen
L_JoyY_2	
	RLF	gLJoyY		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	DECF	zaehler		;zaehler -1
	MOVF	zaehler,F		;zaehler ins Arbeitsregister...
	BTFSC	STATUS,Z		;um zaehler auf 0 zu Prüfen
	RETURN			;(STATUS,Z=1)-> zaehler =0 Position des linken Joysticks (y-Achse)
	GOTO	L_JoyY_1		;(STATUS,Z=0)-> zaehler >0 nächstes Bit senden
;######################################	
gLJoyY_write_1
	BSF	STATUS,C
	GOTO	L_JoyY_2

gLJoyY_write_0
	BCF	STATUS,C
	GOTO	L_JoyY_2

;###############################################################################
UP_Show_btns
;Ausgabe der Register in denen der Status und die einzelnen Zustände der Buttons stehen 
         CLRF	PORTB
         BSF	PORTB,0		;Register LED (STATUS) [DEBUGGING]
         CALL	UP_wait_05s
         CLRF	PORTB
;#########         
	MOVFW	gSTATUS		;Status Register
         MOVWF	PORTB		;an PORTB anzeigen
         CALL	UP_wait_05s
;##################         
         
         CLRF	PORTB
         BSF	PORTB,1		;Register LED (LINKS) [DEBUGGING]
         CALL	UP_wait_05s
         CLRF	PORTB
;#########         
	MOVFW	gLEFT		;LINKS Register
         MOVWF	PORTB		;an PORTB anzeigen
         CALL	UP_wait_05s
;##################         
         
         CLRF	PORTB
         BSF	PORTB,2		;Register LED (RECHTS) [DEBUGGING]
         CALL	UP_wait_05s
         CLRF	PORTB
;#########         
         MOVFW	gRIGHT		;RIGHT Register
         MOVWF	PORTB		;an PORTB anzeigen
         CALL	UP_wait_05s
;##################         
         
         CLRF	PORTB
         BSF	PORTB,3		;Register LED (rechtes Joxstick x-Achse) [DEBUGGING]
         CALL	UP_wait_05s
         CLRF	PORTB
;#########         
         MOVFW	gRJoyX		;RJoyX Register
         MOVWF	PORTB		;an PORTB anzeigen
         CALL	UP_wait_05s
;##################
         
         CLRF	PORTB
         BSF	PORTB,4		;Register LED (rechtes Joxstick y-Achse) [DEBUGGING]
         CALL	UP_wait_05s
         CLRF	PORTB
;#########
         MOVFW	gRJoyY		;RJoyY Register
         MOVWF	PORTB		;an PORTB anzeigen
         CALL	UP_wait_05s
;##################
         
         CLRF	PORTB
         BSF	PORTB,5		;Register LED (linkes Joxstick x-Achse) [DEBUGGING]
         CALL	UP_wait_05s
         CLRF	PORTB
;#########
         MOVFW	gLJoyX		;LJoyX Register
         MOVWF	PORTB		;an PORTB anzeigen
         CALL	UP_wait_05s
;##################
         
         CLRF	PORTB
         BSF	PORTB,6		;Register LED (linkes Joxstick x-Achse) [DEBUGGING]
         CALL	UP_wait_05s
         CLRF	PORTB
;#########
         MOVFW	gLJoyY		;LJoyY Register
         MOVWF	PORTB		;an PORTB anzeigen
         CALL	UP_wait_05s
         
RETURN
;###############################################################################
;###########################      Warteschleifen     ###########################
;###############################################################################

;############################***********************############################
;##########################  ATTENTION Warteschleife  ##########################
;UP_wait_20us
;			;100 cycles
;	movlw	0x21
;	movwf	wait_20us
;loop20us_0
;	decfsz	wait_20us, f
;	goto	loop20us_0
;RETURN
;##########################  ATTENTION Warteschleife 2 #########################
UP_wait_50us
			;250 cycles
	movlw	0x53
	movwf	wait_50us
loop50us_0
	decfsz	wait_50us, f
	goto	loop50us_0
RETURN
;########################**********************************#####################
;###################### CLOCK LOW - CLOCK HIGH Warteschleife ###################
;UP_wait_5us		;UP_wait_5us
;			;25 cycles
;	movlw	0x08
;	movwf	wait_5us
;loop5us_0
;	decfsz	wait_5us, f
;	goto	loop5us_0
;RETURN
;##################### CLOCK LOW - CLOCK HIGH Warteschleife 2 ##################
UP_wait_25us		;UP_wait_5us
			;124 cycles
	movlw	0x29
	movwf	wait_25us
loop25us_0
	decfsz	wait_25us, f
	goto	loop25us_0

			;1 cycle
	nop
RETURN
;############################***********************############################
;############################ Ausgabe Warteschleife ############################
UP_wait_05s
			;2499999 cycles
	movlw	0x16
	movwf	wait_05s
	movlw	0x74
	movwf	wait_05s_1
	movlw	0x06
	movwf	wait_05s_2
loop05s_0
	decfsz	wait_05s, f
	goto	$+2
	decfsz	wait_05s_1, f
	goto	$+2
	decfsz	wait_05s_2, f
	goto	loop05s_0

			;1 cycle
	nop
RETURN

END
