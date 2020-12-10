; **********************************************************
; * projekt_beta_2_3.asm - Playstation Controller an PIC16F84A *
; **********************************************************
;
;	Der PIC soll mit einem PS-Controller kommunizieren
;	und erkennen welche Tasten auf dem Controller gedrückt wurden.
;
;	Wenn er weiß was gedrückt wurde, schaltet er die zu den
;	entsprechenden Tasten gehörenden LED's ein bzw. aus.
;	
;	-> Verwendeter Baustein zur anzeige:	MAX 7219
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
; *			Changelog beta_1_4		*
; **************************************************************
;	MAX-7219	Kommunikation
;		Initialisierung und Anzeigesteuerung
;		via "Spagetti-Code" & dyn. Tabelle
; **************************************************************
; *			Changelog beta_1_3		*
; **************************************************************
;	einfache Anzeigeroutine
;	(nur ein Register wird angezeigt)
; **************************************************************
; *			Changelog beta_1_2		*
; **************************************************************
;	*ERROR*
;	kleine BUGFIXES der Anzeigeroutine mit dyn. Tabelle
;	*ERROR*
; **************************************************************
; *			Changelog beta_1_1		*
; **************************************************************
;	*ERROR*
;	Anzeigeroutine der einzelnen Register in einem
;	Unterprogramm mit dynamischer Tabelle
;	*ERROR*
; **************************************************************
; *			Changelog beta_1_0		*
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
	
;Register des PS2 Controller

		zaehler		;Übertragungszähler (Bits)

		sSTART		;START-Befehl     (00000001)
		;gSTART		;um später die PS2 Kommunikation per
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
;12 Register
	
	;Warteschlangen
	
		;wait_20us	;Wartezeit nach dem a_ATT auf 0 geht
		wait_50us	;Wartezeit nach dem a_ATT auf 0 geht    	;NEW
		
		;wait_5us	;Wartezeit zwischen CLOCK LOW und HIGH
		wait_25us	;Wartezeit zwischen CLOCK LOW und HIGH  	;NEW
;2 Register


;Register des MAX-7219

		zaehler_bit	;Zaehler der einzelnen Übertragenene Bits
		zaehler_tab	;Zaehler um in der MAX-Tabelle zu springen

		sMAX		;Register das zur Kommunikation zwischen PIC
				;und MAX-7219 dient
;3 Register
			
	;zur Initialisierung:
		
		;MAX Digit Kodierungs
		;kMODUS_adr	;Modusbefehlsadresse
		;m_MODUS		;MAX Digit Kodierungsmodus
		
		m_D_MODUS_adr	; 0x09 Digit Kodierungsmodus Adresse
		m_D_MODUS	; 0x00 MAX Digit Kodierungsmodus		->keine Kodierung<-
		
		;MAX Digit Helligkeit
		m_HELLIGKEIT_adr	; 0x0A MAX Helligkeitssteuerung Adresse
		m_HELLIGKEIT	; 0x15 MAX Helligkeitssteuerung		->Digit 31 / 32 (max ON)<-
		
		;MAX Digit Anzahl
		m_DIGITS_adr	; 0x0B Digitsanzahl Adresse
		m_DIGITS		; 0x01 Anzahl der aktivierten Digits 	->Digit 0 und 1<-
		
		;MAX Shutdown
		;kSTART_adr	; 0x0C Startbefehlsadresse
		;m_START		; 0x01 MAX Shutdownbefehl 			->Normal Operation<-
		
		m_SHUTDOWN_adr	; 0x0C SHUTDOWN Adresse
		m_SHUTDOWN	; 0x01 MAX Shutdownbefehl 			->Normal Operation<-
		
		;MAX Test
		m_TEST_adr	; 0x0F Testbefehlsadresse
		m_TEST		; 0x00 MAX Testmodus 			->KEIN TESTMODUS<-
;10 Register
	
	;zur Digitauswahl
		
		m_TYPE_adr	; Type - Digit-Adresse
		m_STATUS_adr	; Status - Digit-Adresse
		
		m_LEFT_adr	; LINKS - Digit-Adresse
		m_RIGHT_adr	; RECHTS - Digit-Adresse
		
		m_RJoyX_adr	; Joystick rechts x-Achse - Digit-Adresse
		m_RJoyY_adr	; Joystick rechts y-Achse - Digit-Adresse
		
		m_LJoyX_adr	; Joystick links x-Achse - Digit-Adresse
		m_LJoyY_adr	; Joystick links y-Achse - Digit-Adresse 
;8 Register
		
;Register für die Debugging funktionen.....
		
		wait_05s
		wait_05s_1
		wait_05s_2

;3 Register		


;42 Register insgesammt -> Bank 0 reicht dafuer aus	
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
;#DEFINE	a_ACK		PORTA, 4		; ACK		Eingang		NICHT BENUTZT

;######################    Ports zur Anzeige     ##################### 
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
;###############################
#DEFINE	a_MAX_DATA	PORTB, 0		; MAX-7219-DATA	Ausgang
#DEFINE	a_MAX_LOAD	PORTB, 1		; MAX-7219-LOAD	Ausgang
#DEFINE	a_MAX_CLOCK	PORTB, 2		; MAX-7219-CLOCK	Ausgang
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

;PS2 - Übertragungsregister
;
	
	MOVLW	B'00000001'	
	MOVWF	sSTART		;START-Befehl     (00000001) = H'01'
	
	MOVLW	B'01000010'	
	MOVWF	sTYPE		;GET-TYPE-Befehl  (01000010) = H'42'
	
;PS2 - Vergleichsregister
;
	MOVLW	B'01011010'	; = 0x5A = Status des Controller wenn bereit
	MOVWF	rSTATUS		;Register wird zum Vergleichen benutzt
    				;wenn Controller nicht bereit ist soll von
    				;vorne Anfangen werden

;MAX - Register zur Initialisierung
;
;Ich haette auch alle (hab ich auch in einer früheren Programmversion)
;Initialisierungs Adressen/Befehle in Konstanten schreiben können. Da ich aber
;bei der Programmminimierung mir eine Senderoutine überlegt habe, die mit einer
;dynamischen Tabelle die komplette Übertragung (Initialisierung + Anzeige) ab
;arbeitet verwende ich jetzt Register.

	MOVLW	B'00001011' 	; 0x0B Digitsanzahl Adresse
	MOVWF	m_DIGITS_adr
	MOVLW	B'00000001' 	; 0x01 Anzahl der aktivierten Digits 	->Digit 0 und 1<-
	MOVWF	m_DIGITS
	
	MOVLW	B'00001100'	; 0x0C SHUTDOWN Adresse
	MOVWF	m_SHUTDOWN_adr
	MOVLW	B'00000001'	; 0x01 MAX Shutdownbefehl 			->Normal Operation<-
	MOVWF	m_SHUTDOWN
	
	MOVLW	B'00001111'	; 0x0F Testbefehlsadresse
	MOVWF	m_TEST_adr
	MOVLW	B'00000000'	; 0x00 MAX Testmodus 			->kein Testmodus<-
	MOVWF	m_TEST
	
	MOVLW	B'00001001'	; 0x09 Digit Kodierungsmodus Adresse
	MOVWF	m_D_MODUS_adr
	MOVLW	B'00000000'	; 0x00 MAX Digit Kodierungsmodus		->keine Kodierung<-
	MOVWF	m_D_MODUS
	
	MOVLW	B'00001010' 	; 0x0A MAX Helligkeitssteuerung Adresse
	MOVWF	m_HELLIGKEIT_adr
	MOVLW	B'00001111'	; 0x15 MAX Helligkeitssteuerung		->Digit 31 / 32 (max ON)<-
	MOVWF	m_HELLIGKEIT

;MAX - Register zur Digitzuweisung
;
;Könnte auch mit einem Zaehler gemacht werden, aber ich möchte auswählen
;wo welches Register angezeigt werden soll und auserdem ist es jetzt möglich
;die Initialisierung und die Anzeige in einem Unterprogramm ab zu arbeiten

	
	MOVLW	B'00000001'	; LINKS - Digit-Adresse			-> Digit 0
	MOVWF	m_LEFT_adr
	
	MOVLW	B'00000010'	; RECHTS - Digit-Adresse			-> Digit 1
	MOVWF	m_RIGHT_adr
	
	MOVLW	B'00000011'	; Joystick rechts, x-Achse - Digit-Adresse	-> Digit 2
	MOVWF	m_RJoyX_adr
	
	MOVLW	B'00000100'	; Joystick rechts, y-Achse - Digit-Adresse	-> Digit 3
	MOVWF	m_RJoyY_adr
	
	MOVLW	B'00000101'	; Joystick links, x-Achse - Digit-Adresse	-> Digit 4
	MOVWF	m_LJoyX_adr

	MOVLW	B'00000110'	; Joystick links, y-Achse - Digit-Adresse	-> Digit 5
	MOVWF	m_LJoyY_adr
	

;MAX - Starteinstellungen
;	
	BSF	a_MAX_LOAD	; MAX-Baustein soll am Anfang nicht im ...
	BSF	a_MAX_CLOCK	; ...Übertragungsmodus sein
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
;	BSF	a1;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Start		;Senden:		H'01' Startbefehl
;	BCF	a1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########	
;	BSF	b1;;;;;;;;;	;--------------------------------------------DEBUGGING	
	CALL	UP_Get_Type	;Senden:		H'42' Datenanfrage
 				;------------------------------------
				;Empfangen:	H'41'=Digital
 				;ODER		H'23'=NegCon
				;ODER		H'73'=Analogue Red LED
				;ODER		H'53'=Analogue Green LED
;	BCF	b1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	c1;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Get_Status	;Empfangen:  H'5A' - Status:READY
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	c1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	d1;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Get_L_btns	;Empfangen:  H'xx' - Status der linken Btns
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	d1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	a2;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Get_R_btns	;Empfangen:  H'xx' - Status der rechten Btns
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	a2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	b2;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Get_R_Joy_X	;Empfangen:  H'xx' - rechtes Joystick, X-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	b2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	c2;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Get_R_Joy_Y	;Empfangen:  H'xx' - rechtes Joystick, Y-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	c2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	d2;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Get_L_Joy_X	;Empfangen:  H'xx' - linkes Joystick, X-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	d2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	c2;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_Get_L_Joy_Y	;Empfangen:  H'xx' - linkes Joystick, Y-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	c2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	b2;;;;;;;;;	;--------------------------------------------DEBUGGING
;	CALL	UP_Show_btns	;Ausgabe der gXXXX (g=> GET) Register
;	BCF	b2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########

;#########
         ;BCF	d2		;--------------------------------------------DEBUGGING
	;CALL	UP_MAX		;Ausgabe 
	;BSF	d2		;--------------------------------------------DEBUGGING
;#########	 


;#########
         BSF	d2		;--------------------------------------------DEBUGGING
	CALL	UP_MAX_send_tabelle	;Ausgabe 
	BCF	d2		;--------------------------------------------DEBUGGING
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
	MOVFW	gRIGHT		;Rechte BTNS Register
	MOVWF	PORTB		;an PORTB anzeigen
         
;	CLRF	PORTB       
;	MOVFW	gRJoyX		;RJoyX Register
;	MOVWF	PORTB		;an PORTB anzeigen
;	CALL	UP_wait_05s
;##################
         
;	CLRF	PORTB
;	MOVFW	gRJoyY		;RJoyY Register	
;	MOVWF	PORTB		;an PORTB anzeigen
;	CALL	UP_wait_05s
;##################
         
;	CLRF	PORTB
;	MOVFW	gLJoyX		;LJoyX Register
;	MOVWF	PORTB		;an PORTB anzeigen
;	CALL	UP_wait_05s
;##################
         
;	CLRF	PORTB
;	MOVFW	gLJoyY		;LJoyY Register
;	MOVWF	PORTB		;an PORTB anzeigen
;	CALL	UP_wait_05s
         
RETURN
;###############################################################################
UP_MAX

;kTYPE_adr	EQU	B'00000001' ; Type - Digit-Adresse
;kSTATUS_adr	EQU	B'00000010' ; Status - Digit-Adresse

;kLEFT_adr	EQU	B'00000011' ; LINKS - Digit-Adresse
;kRIGHT_adr	EQU	B'00000100' ; RECHTS - Digit-Adresse

;kRJoyX_adr	EQU	B'00000101' ; Joystick rechts x-Achse - Digit-Adresse
;kRJoyY_adr	EQU	B'00000110' ; Joystick rechts y-Achse - Digit-Adresse

;kLJoyX_adr	EQU	B'00000111' ; Joystick links x-Achse - Digit-Adresse
;kLJoyY_adr	EQU	B'00001000' ; Joystick links y-Achse - Digit-Adresse 
         
	
	CALL	UP_MAX_init	;Initialisierung des MAX-Bausteins
	
	
;###################################
	MOVF	m_LEFT_adr,W	; Digit Adresse senden
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	;  
	;-
	;MOVF	gTYPE,W		;
         MOVF	gLEFT,W		;
         ;MOVWF	PORTB		;-------DEBUGGING--------
         ;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	;
	
	BSF	a_MAX_LOAD
	
         ;CALL	UP_wait_05s
;###################################
	MOVF	m_RIGHT_adr,W	; Digit Adresse senden
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	; 
         ;-
         ;MOVF	gSTATUS,W	;
         MOVF	gRIGHT,W		; 
         ;MOVWF	PORTB		;-------DEBUGGING--------
         ;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	;
         
         BSF	a_MAX_LOAD
RETURN
;#####################################
UP_MAX_init

         BSF	a_MAX_LOAD	; Falls es noch auf LOW steht.. wird es jetz HIGH 
	
         ;###########################	Anzahl der genutzten Digits senden
	MOVF	m_DIGITS_adr,W	; erst Adresse
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------		
	CALL	UP_MAX_send	; 	0x0B
	;#########	         ;
	MOVF	m_DIGITS,W	; dann die Anzahl der Digits
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------		
	CALL	UP_MAX_send	;	0x01 (2 Digits)
	
	BSF	a_MAX_LOAD	; Nach 2 Byte (1 word) muss LOAD auf HIGH
	
	;###########################	Shutdownmodus senden	
				; 
	MOVF	m_SHUTDOWN_adr,W	; erst Adresse
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	; 	0x0C
         ;#########		; dann der Befehl selbst senden
	MOVF	m_SHUTDOWN,W	; 	0x01 (Normal Operation)
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	;
         
	BSF	a_MAX_LOAD	; Nach 2 Byte (1 word) muss LOAD auf HIGH
	
	;###########################	Testmodus senden	
				; 
	MOVF	m_TEST_adr,W	; erst Adresse
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	; 	0x0C
         ;#########		; dann der Befehl selbst senden
	MOVF	m_TEST,W		; 	0x01 (Normal Operation)
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	;
         
	BSF	a_MAX_LOAD	; Nach 2 Byte (1 word) muss LOAD auf HIGH
	
         ;###########################	Digit Kodierungsmodus senden
	MOVF	m_D_MODUS_adr,W	; erst Adresse
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------	
         CALL	UP_MAX_send	;	0x09 
         ;#########		; dann der Befehl selbst
         MOVF	m_D_MODUS,W	;	0x00 (keine Kodierung der Digits)
         ;MOVWF	PORTB		;-------DEBUGGING--------
         ;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	;
         
         BSF	a_MAX_LOAD	; Nach 2 Byte (1 word) muss LOAD auf HIGH
         
         ;###########################	Helligkeitseinstellung senden
	MOVFW	m_HELLIGKEIT_adr	; erst Adresse
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------
         CALL	UP_MAX_send	; 	0x0A
         ;#########		; dann die Helligkeitseinstellung selbst
         MOVFW	m_HELLIGKEIT	;	0x15 (31/32 an)
	;MOVWF	PORTB		;-------DEBUGGING--------
	;CALL	UP_wait_05s	;-------DEBUGGING--------		
         CALL	UP_MAX_send	; 
         
         BSF	a_MAX_LOAD	; Nach 2 Byte (1 word) muss LOAD auf HIGH


	
RETURN
         
;#####################################
UP_MAX_send
	MOVWF	sMAX
	MOVLW	D'8'
	MOVWF	zaehler
	BCF	a_MAX_LOAD	;Vor der Übertragung von 2 Bytes auf LOW
	
MAX_s1	RLF	sMAX		;MSB zuerst...
	BTFSC	STATUS,C
	GOTO	MAX_send_1	;MAX-Datenleitung auf HIGH	(Übertrage 1)
	BCF	a_MAX_DATA	;MAX-Datenleitung auf LOW	(Übertrage 0)	
	
MAX_s2	BCF	a_MAX_CLOCK	;
	;CALL	UP_wait_05s	; #############DEBUGGING#############
	BSF	a_MAX_CLOCK	;Positive Flanke erzeugen
	BCF	a_MAX_CLOCK
	
	DECF	zaehler
	MOVF	zaehler,F	; Zähler ...
	BTFSS	STATUS,Z		; ... auf 0 prüfen,
	GOTO	MAX_s1		; <-- Zähler != 0
		        	  	; <-- Zähler == 0 (Schleifenende)
	;BSF	a_MAX_LOAD	;NACH der Übertragung von 2 Bytes auf LOW
	
 				;geht hier noch nicht, da ich nur ein Byte
 				;über das UP_MAX_send übertrage!!!!
	RETURN
	
MAX_send_1
	BSF	a_MAX_DATA
	GOTO	MAX_s2
;#####################################
UP_MAX_send_tabelle
	
	MOVLW	D'0'
	MOVWF	zaehler_tab
	
MAX_st1	MOVLW	D'8'
	MOVWF	zaehler_bit
	
	BCF      STATUS, IRP	; Bank 0 oder 1  
	
	MOVF	zaehler_tab,W
	
	CALL	tab_MAX		;Öffnet die "dynamische Tabelle"
				;Im Workregister steht jetzt die Adresse
    				;des Registers dessen Inhalt Übertragen werden soll
			     	
	MOVWF	FSR		;der Zeiger zeigt jetzt auf das Register
				;dessen Inhalt Übertragen werden soll
				
	MOVFW	INDF		;mit dem virtuellen Register INDF kann der
				;Inhalt des Registers ausgegeben werden,
    				;auf das der Zeiger FSR zeigt
	;MOVWF	PORTB		; #############DEBUGGING#############
	;CALL	UP_wait_05s	; #############DEBUGGING#############
	MOVWF	sMAX
	
	BCF	a_MAX_LOAD	;Vor der Übertragung von 2 Bytes auf LOW
	
	
MAX_st2	RLF	sMAX		;MSB zuerst...
	BTFSC	STATUS,C
	GOTO	MAX_send_tabelle_1	;MAX-Datenleitung auf HIGH	(Übertrage 1)
	BCF	a_MAX_DATA		;MAX-Datenleitung auf LOW	(Übertrage 0)	
	
MAX_st3	BCF	a_MAX_CLOCK	;
	;CALL	UP_wait_05s	; #############DEBUGGING#############
	BSF	a_MAX_CLOCK	;Positive Flanke erzeugen
	BCF	a_MAX_CLOCK
	
	DECF	zaehler_bit
	MOVF	zaehler_bit,F	; Zähler ...
	BTFSS	STATUS,Z		; ... auf 0 prüfen,
	GOTO	MAX_st2		; <-- Zähler != 0
	BTFSS	zaehler_tab,0	; <-- Zähler == 0
	BSF	a_MAX_LOAD	; <-- Zähler_tab == gerade
				; <-- Zähler_tab == ungerade
	INCF	zaehler_tab
	MOVLW	D'22'
	SUBWF	zaehler_tab,W
	BTFSS	STATUS,Z		
	GOTO	MAX_st1		;zaehler_tab < 22
	RETURN			;zaehler_tab = 22
	
MAX_send_tabelle_1
	BSF	a_MAX_DATA
	GOTO	MAX_st3
		
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



;###############################################################################
;
;	geht auch mit dyn. Tabelle!!!
;	zaehler HOCHZÄHLEN lassen, in Tabelle springen (Übertragungsbyte)
;	laden und dann zaehler auf Anzahl der Übertragungsbytes prüfen,
;	zaehler<Anzahl der Übertragungsbytes -> nächste Tabellenzeile übertragen
;	zaehler=Anzahl der Übertragungsbytes -> RETURN
;
tab_MAX				;Tabellenlänge: 22; -> zaehler max. 23!
	BSF	PCLATH,0		;Lade PCLATH mit Seite 3
	BSF	PCLATH,1
	MOVWF	PCL		;Computed Goto
	
	
ORG	0x300		; Tabelle in Speicherblock 3
	
	RETLW	m_DIGITS_adr	; Anzahl der genutzten Digits
	RETLW	m_DIGITS		; 

	RETLW	m_SHUTDOWN_adr	; Normalmodus oder Ausgeschaltet
	RETLW	m_SHUTDOWN	; 

	RETLW	m_TEST_adr	; Normalmodus oder Displaytest
	RETLW	m_TEST		; 

	RETLW	m_D_MODUS_adr	; Dekodierungsmodus 
	RETLW	m_D_MODUS	; 

	RETLW	m_HELLIGKEIT_adr	; Helligkeitssteuerung der LED's (WAZUP ???)
	RETLW	m_HELLIGKEIT	;
 
	;RETLW	m_TYPE_adr	; Type - Digit-Adresse
	;RETLW	gTYPE		; Controller Type
	
	;RETLW	m_STATUS_adr	; Status - Digit-Adresse 
	;RETLW	gSTATUS		; Controller Status

	RETLW	m_LEFT_adr	; Tasten LINKS - Digit-Adresse
	RETLW	gLEFT		; Tasten LINKS

	RETLW	m_RIGHT_adr	; Tasten RECHTS - Digit-Adresse
	RETLW	gRIGHT		; Tasten RECHTS

	RETLW	m_RJoyX_adr	; Joystick rechts, x-Achse - Digit-Adresse
	RETLW	gRJoyX		; Joystick rechts, x-Achse

	RETLW	m_RJoyY_adr	; Joystick rechts, y-Achse - Digit-Adresse
	RETLW	gRJoyY		; Joystick rechts, y-Achse

	RETLW	m_LJoyX_adr	; Joystick links, x-Achse - Digit-Adresse
	RETLW	gLJoyX		; Joystick links, x-Achse

	RETLW	m_LJoyY_adr	; Joystick links,	y-Achse - Digit-Adresse
	RETLW	gLJoyY		; Joystick links, y-Achse
; mit DT lässt sich eine Wertetabelle aufbauen. Dabei steht jeder Wert für die Anweisung
; 'RETLW <wert>'. Die Tabelle lässt sich also alternativ auch mit einer Liste von 'RETLW'-
; Anweisungen aufbauen.

END
