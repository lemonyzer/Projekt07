; ***********************************************************
; * lochraster_joysticks.asm - Playstation Controller an PIC16F84A *
; ***********************************************************
;
;	Aryan Layes	HBFI05a		04/2007
;
;	Der PIC soll mit einem PS-Controller kommunizieren
;	und erkennen wo die Joysticks stehen.
;
;	Anzeige -> PORTB
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
	
;Register des PS2 Controller
		
		sPSC		;Übertragungsregiser (dynamische Tabelle)
		sIDLE		;IDLE-Register (= 0)

		sSTART		;START-Befehl     (00000001)
		gSTART		;um später die PS2 Kommunikation per
				;dynamische Tabelle ab zu arbeiten

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
;14 Register

;Übertragung	
		zaehler_tab
		zaehler_bit
		
;2 Register
	
;Warteschlangen
	
		;wait_20us	;Wartezeit nach dem a_ATT auf 0 geht
		wait_50us	;Wartezeit nach dem a_ATT auf 0 geht    	;NEW
		
		;wait_5us	;Wartezeit zwischen CLOCK LOW und HIGH
		wait_25us	;Wartezeit zwischen CLOCK LOW und HIGH  	;NEW
;2 Register


;Register um zu Überprüfen ob Controller bereit
	       	zaehler
		
;Register für die debugging Funktionen.....
		
		wait_05s
		wait_05s_1
		wait_05s_2

;3 Register		


;23 Register insgesammt -> Bank 0 reicht dafuer aus	
	ENDC


;***************************************************************
;		* Konstanten festlegen * 
;***************************************************************

;*****************************************
;	* Konstanten des MAX-7219 * 
;*****************************************

; ***********************************************************************
; * Definition von einzelnen Bits in einem Register / in einer Variable *
; ***********************************************************************

;#####################     Ports zum Controller    ################### 
;##################### ___________________________ ###################
#DEFINE	e_DATA		PORTA, 0		; Data		Eingang
#DEFINE	a_COMMAND	PORTA, 1		; Command	Ausgang
#DEFINE	a_CLOCK		PORTA, 2		; Takt		Ausgang
#DEFINE	a_ATT		PORTA, 3		; ATT		Ausgang
;#DEFINE	a_ACK		PORTA, 4		; ACK	Eingang NICHT BENUTZT

;######################    Ports zur Anzeige     ##################### 
;###################### ________________________ #####################
#DEFINE	LED_l_down	PORTB, 0		; DEBBUGING	Ausgang
#DEFINE	LED_l_left	PORTB, 1		; 		Ausgang
#DEFINE	LED_l_right	PORTB, 2		; 		Ausgang
#DEFINE	LED_l_up		PORTB, 3		; 		Ausgang
;###############################
#DEFINE	LED_r_down	PORTB, 4		; 		Ausgang
#DEFINE	LED_r_left	PORTB, 5		; 		Ausgang
#DEFINE	LED_r_up		PORTB, 6		; 		Ausgang
#DEFINE	LED_r_right	PORTB, 7		; 		Ausgang
;###############################
;#DEFINE	a_MAX_DATA	PORTB, 0		; MAX-7219-DATA	Ausgang
;#DEFINE	a_MAX_LOAD	PORTB, 1		; MAX-7219-LOAD	Ausgang
;#DEFINE	a_MAX_CLOCK	PORTB, 2		; MAX-7219-CLOCK	Ausgang
;#####################################################################
#DEFINE	bank1		STATUS, RP0
;#####################################################################

;*****************
;* Programmstart *
;*****************

	ORG	H'00'	; Das Programm wird ab Speicherstelle 0 in den
 			; Speicher geschrieben
	GOTO	init	; Springe zur Grundinitialisierung der Ports A und B


;*******************
;* Initialisierung *
;*******************

init	BSF	bank1	; wechsle zu Registerbank 1 (spezielle Register)

	MOVLW	B'00000001'
	MOVWF	TRISA	; RA0 Eingang (RA1 bis RA7 sind Ausgänge)
	MOVLW	B'00000000'
	MOVWF	TRISB	; RB0 bis RB7 sind Ausgänge
	
; Die Register TRISA und TRISB legen fest, welche Bits in den jeweiligen Ports
; Ein- bzw. Ausgänge sind. Eine '1' an der entsprechenden Stelle setzt das Bit
; des Ports als Eingang eine '0' setzt das Bit als Ausgang.
	
	BCF	bank1	; wechsle zu Registerbank 0 
			; (normaler Speicherbereich)
			
	CLRF	PORTA	; Port A löschen
	CLRF	PORTB	; Port B löschen
	

;PS2 - Übertragungsregister
;
	CLRF	sIDLE
	
	MOVLW	B'00000001'	
	MOVWF	sSTART		;START-Befehl     (00000001) = H'01'
	
	MOVLW	B'01000010'	
	MOVWF	sTYPE		;GET-TYPE-Befehl  (01000010) = H'42'
		
;PS2 - Vergleichsregister
;
	MOVLW	B'01011010'	; = 0x5A = Status des Controller wenn bereit
	MOVWF	rSTATUS		;Register wird zum Vergleichen benutzt
    				;wenn Controller nicht bereit ist soll von
    				;er zurück zu main springen und die
    				;Anzeige löschen


;*****************
;* Hauptprogramm *
;*****************

main
	
	BSF	a_ATT		; ATT auf HIGH, Controller wird abgewählt
				; (ignoriert alle Daten)
	CALL	UP_wait_25us
	BSF	a_CLOCK		; Clock HIGH
	BSF	a_COMMAND	; Command HIGH
	
	BCF	a_ATT		; ATT auf LOW das der Controller
				; die Daten annimmt
					
	CALL	UP_wait_50us	; Warteschlange bis Controller bereit ist
	
;#########		
;	BSF	a1;;;;;;;;;	;-----DEBUGGING
	CALL	UP_PSC_send_tabelle
	COMF	gLEFT,F		;Speicherzellen werden invertiert ( 1 zu 0 
	COMF	gRIGHT,F		;und 0 zu 1). Weil wenn eine Taste gedrückt
				;ist dann liegt ein 0 Signal am PIC an
	
	MOVF	rSTATUS,W	;Controller Status auf Zustand "bereit"		
	SUBWF	gSTATUS		;prüfen...
	BTFSS	STATUS,Z		;Wenn breit, Zerobit = 1
	GOTO	nicht_bereit	;<- Controller nicht bereit...
				;<- Controller bereit...
		
;#########
         ;BCF	d2		;------DEBUGGING
         CLRF	PORTB		; Anzeige löschen
	CALL	UP_Display_r	;rechte Display LED auswählen
	CALL	UP_Display_l	;linke Display LED auswählen
	;CALL	UP_wait_05s 
	;BSF	d2		;------DEBUGGING
;#########	 



GOTO	main			;Springe wieder an den Anfang zurück   

nicht_bereit
	CLRF	PORTB
	GOTO	main

	
	

;******************
;* Unterprogramme *
;******************
;###############################################################################
;###############################################################################
UP_PSC_send_tabelle
	
	MOVLW	D'0'
	MOVWF	zaehler_tab
	
PSC_st1	MOVLW	D'8'
	MOVWF	zaehler_bit
	
	BCF      STATUS, IRP	; Bank 0 oder 1 (alle Register aus der
 		        		; Tabelle sind in Bank 0)
	
	MOVF	zaehler_tab,W	;wird mit dem PCL addiert
	
	CALL	tab_PSC		;Öffnet die "dynamische Tabelle"
				;Im Workregister steht jetzt die Adresse
    				;des Registers dessen Inhalt
			     	;Übertragen werden soll
			     	
	MOVWF	FSR		;der Zeiger zeigt jetzt auf das Register
				;dessen Inhalt Übertragen werden soll
				
	MOVF	INDF,W		;mit dem virtuellen Register INDF kann der
				;Inhalt des Registers ausgegeben werden,
    				;auf das der Zeiger FSR zeigt

	MOVWF	sPSC		;Inhalt wird in sende Register kopiert,
				;da ein weiteres Register aus der Tabelle
				;benötigt wird um die empfangenen Bits zu
				;speichern
	
	INCF	zaehler_tab	;nächste Tabellenreihe
	
	MOVF	zaehler_tab,W	;wird mit dem PCL addiert
	CALL	tab_PSC		;Öffnet die "dynamische Tabelle"
				;Im Workregister steht jetzt die Adresse
    				;des Registers in das geschrieben wird
				    
	MOVWF	FSR		;der Zeiger zeigt jetzt auf das Register
				;in das die empfangenen Bits gespeichert
				;werden
				;-
				;mit dem virtuellen Register INDF kann der
				;Inhalt des Registers geändert werden,
    				;auf das der Zeiger FSR zeigt				
					
PSC_1	RRF	sPSC		;verschiebe sende Register nach rechts...
	BTFSS	STATUS,C		;prüfe Wertigkeit des rausgeworfenen Bits
	GOTO	PSC_sende_0	;(STATUS,C=0)-> Übertrage 0 an Controller...
	GOTO	PSC_sende_1	;(STATUS,C=1)-> ansonsten Übertrage '1'	

PSC_2	DECF	zaehler_bit
	MOVF	zaehler_bit,F	; Zähler ...
	BTFSS	STATUS,Z		; ... auf 0 prüfen,
	GOTO	PSC_1		; <-- Zähler != 0 --> nächstes Bit übertrag.
				; <-- Zähler == 0
				 

	INCF	zaehler_tab
	MOVLW	D'18'		;PS2-Analog-Mode Controller
	SUBWF	zaehler_tab,W
	BTFSS	STATUS,Z		
	GOTO	PSC_st1		;zaehler_tab < 18
	RETURN			;zaehler_tab = 18
;###########################################################	
PSC_sende_0
	BCF	a_COMMAND	;auf 0 setzten
	BCF	a_CLOCK		;negative Flanke (Controller ließt COMMAND)
	CALL	UP_wait_25us	;aber erst nach 25µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	INDF_0_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	INDF_0_write_0	;empfangenes Bit in Carry-Flag setzen
PSC_sende_0_next	
	RRF	INDF		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	PSC_2
;######################################	
INDF_0_write_1
	BSF	STATUS,C
	GOTO	PSC_sende_0_next

INDF_0_write_0			;zur Übersicht, hier geschrieben!!!
	BCF	STATUS,C
	GOTO	PSC_sende_0_next	
;###########################################################
PSC_sende_1
	BSF	a_COMMAND	;auf 1 setzten
	BCF	a_CLOCK		;negative Flanke (Controller ließt COMMAND)
	CALL	UP_wait_25us	;aber erst nach 4µs !!!
	BTFSC	e_DATA		;e_DATA prüfen
	GOTO	INDF_1_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	INDF_1_write_0	;empfangenes Bit in Carry-Flag setzen
PSC_sende_1_next	
	RRF	gTYPE		;empfangenes Bit in Register hinzufügen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	PSC_2
;######################################
INDF_1_write_1
	BSF	STATUS,C
	GOTO	PSC_sende_1_next

INDF_1_write_0			;zur Übersicht, hier geschrieben!!!
	BCF	STATUS,C
	GOTO	PSC_sende_1_next
;###############################################################################
UP_Display_r			;Positionsberechnung Joystick rechts 
	MOVLW	D'85'
	SUBWF	gRJoyX,W
	BTFSC	STATUS,C
	GOTO	x_groesser_85

x_kleiner_gleich_85	
	MOVLW	D'85'
	SUBWF	gRJoyY,W
	BTFSC	STATUS,C
	GOTO	y_groesser_85	
y_kleiner_gleich_85
;	BSF	m_display_r,6		;LINKS OBEN
	RETURN
	
	
y_groesser_85
	MOVLW	D'170'
	SUBWF	gRJoyY,W
	BTFSC	STATUS,C
	GOTO	y_groesser_170
y_kleiner_gleich_170
	BSF	LED_r_left		;LINKS
	RETURN
	
	
y_groesser_170
	;BSF	m_display_r,0		;LINKS UNTEN
	RETURN
;####################################
;####################################	
x_groesser_85
	MOVLW	D'170'
	SUBWF	gRJoyX,W
	BTFSC	STATUS,C
	GOTO	x_groesser_170		
x_kleiner_gleich_170
	MOVLW	D'85'
	SUBWF	gRJoyY,W
	BTFSC	STATUS,C
	GOTO	y_2_groesser_85	
y_2_kleiner_gleich_85
	BSF	LED_r_up			;OBEN
	RETURN
	
	
y_2_groesser_85
	MOVLW	D'170'
	SUBWF	gRJoyY,W
	BTFSC	STATUS,C
	GOTO	y_2_groesser_170
y_2_kleiner_gleich_170
	;BSF	m_display_c,0		;MITTE
	RETURN
	
	
y_2_groesser_170
	BSF	LED_r_down		;UNTEN
	RETURN	
	
;####################################
;####################################	
x_groesser_170
	MOVLW	D'85'
	SUBWF	gRJoyY,W
	BTFSC	STATUS,C
	GOTO	y_3_groesser_85	
y_3_kleiner_gleich_85
	;BSF	m_display_r,4		;RECHTS OBEN
	RETURN
	
	
y_3_groesser_85
	MOVLW	D'170'
	SUBWF	gRJoyY,W
	BTFSC	STATUS,C
	GOTO	y_3_groesser_170
y_3_kleiner_gleich_170
	BSF	LED_r_right		;RECHTS
	RETURN
	
	
y_3_groesser_170
	;BSF	m_display_r,2		;RECHTS UNTEN
	RETURN	
;###############################################################################
UP_Display_l			;Positionsberechnung Joystick links
	MOVLW	D'85'		;links und rechts kann auch wieder mit
	SUBWF	gLJoyX,W		;Tabelle minimiert weden!
	BTFSC	STATUS,C
	GOTO	_x_groesser_85

_x_kleiner_gleich_85	
	MOVLW	D'85'
	SUBWF	gLJoyY,W
	BTFSC	STATUS,C
	GOTO	_y_groesser_85	
_y_kleiner_gleich_85
	;BSF	m_display_l,6		;LINKS OBEN
	RETURN
	
	
_y_groesser_85
	MOVLW	D'170'
	SUBWF	gLJoyY,W
	BTFSC	STATUS,C
	GOTO	_y_groesser_170
_y_kleiner_gleich_170
	BSF	LED_l_left		;LINKS
	RETURN
	
	
_y_groesser_170
	;BSF	m_display_l,0		;LINKS UNTEN
	RETURN
;####################################
;####################################	
_x_groesser_85
	MOVLW	D'170'
	SUBWF	gLJoyX,W
	BTFSC	STATUS,C
	GOTO	_x_groesser_170
_x_kleiner_gleich_170
	MOVLW	D'85'
	SUBWF	gLJoyY,W
	BTFSC	STATUS,C
	GOTO	_y_2_groesser_85	
_y_2_kleiner_gleich_85
	BSF	LED_l_up			;OBEN
	RETURN
	
	
_y_2_groesser_85
	MOVLW	D'170'
	SUBWF	gLJoyY,W
	BTFSC	STATUS,C
	GOTO	_y_2_groesser_170
_y_2_kleiner_gleich_170
	;BSF	m_display_c,1		;MITTE
	RETURN
	
	
_y_2_groesser_170
	BSF	LED_l_down		;UNTEN
	RETURN	
	
;####################################
;####################################	
_x_groesser_170
	MOVLW	D'85'
	SUBWF	gLJoyY,W
	BTFSC	STATUS,C
	GOTO	_y_3_groesser_85	
_y_3_kleiner_gleich_85
	;BSF	m_display_l,4		;RECHTS OBEN
	RETURN
	
	
_y_3_groesser_85
	MOVLW	D'170'
	SUBWF	gLJoyY,W
	BTFSC	STATUS,C
	GOTO	_y_3_groesser_170
_y_3_kleiner_gleich_170
	BSF	LED_l_right		;RECHTS
	RETURN
	
	
_y_3_groesser_170
	;BSF	m_display_l,2		;RECHTS UNTEN
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
;########################### DEBUGGING Warteschleife ###########################
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
;###############################################################################
;###########################        Tabellen        ############################
;###############################################################################

;############################***********************############################
;###########################       PSC-Tabelle       ###########################

tab_PSC				;Tabellenlänge: 18; -> zaehler_tab max. 18!
	BSF	PCLATH,0		;PCLATH auf ...
	BSF	PCLATH,1		;... 0x3 stellen
	MOVWF	PCL		;PCL ist jetzt 0x300 + zaehler_tab
	
	
	
ORG	0x300			; Tabelle in Speicherblock 3
	
	RETLW	sSTART		; Playstation Controller - Startbefehl
	RETLW	gSTART		; empfange... irgentwas

	RETLW	sTYPE		; Playstation Controller - Typebefehl
	RETLW	gTYPE		; empfange Type des Controllers

	RETLW	sIDLE		; übertrage 0 Signal
	RETLW	gSTATUS		; empfange Status des Controllers 

	RETLW	sIDLE		; übertrage 0 Signal
	RETLW	gLEFT		; empfange Status der Tasten LINKS

	RETLW	sIDLE		; übertrage 0 Signal
	RETLW	gRIGHT		; empfange Status der Tasten RECHTS

	RETLW	sIDLE		; übertrage 0 Signal
	RETLW	gRJoyX		; empfange : Joystick rechts, x-Achse

	RETLW	sIDLE		; übertrage 0 Signal
	RETLW	gRJoyY		; empfange : Joystick rechts, y-Achse

	RETLW	sIDLE		; übertrage 0 Signal
	RETLW	gLJoyX		; empfange : Joystick links, x-Achse

	RETLW	sIDLE		; übertrage 0 Signal
	RETLW	gLJoyY		; empfange : Joystick links, y-Achse


END
