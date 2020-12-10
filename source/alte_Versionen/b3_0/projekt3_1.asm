; **********************************************************
; * projekt_beta_3_0.asm - Playstation Controller an PIC16F84A *
; **********************************************************
;
;	Der PIC soll mit einem PS-Controller kommunizieren
;	und erkennen welche Tasten auf dem Controller gedr�ckt wurden.
;
;	Wenn er wei� was gedr�ckt wurde, schaltet er die zu den
;	entsprechenden Tasten geh�renden LED's ein bzw. aus.
;	
;	-> Verwendeter Baustein zur anzeige:	MAX 7219
;
;	Optional:
;			Kommunikation mit dem PC (RS232)
;			um einen PS-PC Konverter zu erm�glichen
;
; #############################################################################
;
;	D: Digitaler Controller (keine Joysticks)
;	A: Analoger Controller (2 Joysticks)
;
;RxByte	Type	Taste	Hex	Bin�r
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
;  Mehrere Buttons werden UND Verkn�pft...
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
;	sXXXXX	Register Verarbeitung ge�ndert
;	zaehler	Register Verarbeitung ge�ndert
;
;	main	programmpositions LED-Anzeige ge�ndert
; **************************************************************
; *			Changelog 0_7_5			*
; **************************************************************
;	Warteschleifen ge�ndert:
;
;		UP_wait_25us <- hinzugef�gt	CLOCK
;		UP_wait_50us <- hinzugef�gt	ATT
;
; **************************************************************
; *			Changelog 0_7_4			*
; **************************************************************
;	Empfangsabfrage zur�ck auf 0_7_2
;	Warteschleifen ge�ndert:
;
;		UP_wait_5us <- hinzugef�gt		CLOCK
;		UP_wait_20us <- hinzugef�gt	ATT
;
;		UP_wait_4us <- durch UP_wait_5us ersetzt
;		UP_wait_100us <- gel�scht
; **************************************************************
; *			Changelog 0_7_3			*
; **************************************************************
;	Empfangsabfrage ge�ndert...
; **************************************************************
; *			Changelog 0_7_2			*
; **************************************************************
;
;	UP_wait_100us hinzugef�gt (ausgetauscht mit UP_wait_4us)
;
;  	
; **************************************************************
; *			Changelog 0_7_1			*
; **************************************************************
;
;	UP_wait_05s hinzugef�gt
;
;	Anzeigeroutine folgender Register hinzugef�gt:
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
;* Bestimmung des Prozessortyps f�r den Assembler und das Programmierger�t *
;***************************************************************************

		LIST p=16F84A


;*******************************************************************
;* Includedatei f�r den 16F84A einbinden (vordef. Reg. und Konst.) *
;*******************************************************************

		#include <p16f84A.INC>

; Diese Datei enth�lt Vordefinitionen f�r wichtige Register und Konstanten.
; (Z.B. gibt es die Konstante PORTB mit der sich ohne Angabe der
; absoluten Adresse H'0006' der Port B des Prozessors ansprechen l�sst)


;*********************************************************
;* Konfigurationseinstellungen f�r IC-Prog vordefinieren *
;*********************************************************

		__CONFIG _PWRTE_ON & _CP_OFF & _HS_OSC & _WDT_OFF

; Hier werden verschiedene Prozessoreigenschaften festgelegt:
; _PWRTE_ON schaltet den Power Up Timer ein, d.h. der Prozessor wartet nach
;           dem Einschalten ca. 70ms mit dem Programmstart, um sicher zu sein,
;           dass alle angeschlossene Peripherie bereit ist.
; _CP_OFF schaltet die Code-Protection des Prozesors aus. Damit ist das im Prozessor
;        befindliche Programm jederzeit auslesbar und �berschreibbar.
; _HS_OSC spezifiziert einen Quarzoszillator (Highspeed) als Zeitbasis f�r den Prozessor.
; _WDT_OFF schaltet den Watchdog-Timer des Prozesors aus.


;***********************************
;* Register / Variablen  festlegen *
;***********************************
; hier werden Adressen von Registern / Variablen festgelegt. Diese werden beginnend
; mit der Adresse H'20' aufsteigend vergeben.


	CBLOCK	H'20'
	
;Register des PS2 Controller

		zaehler		;�bertragungsz�hler (Bits)

		sSTART		;START-Befehl     (00000001)
		;gSTART		;um sp�ter die PS2 Kommunikation per
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

		zaehler_bit	;Zaehler der einzelnen �bertragenene Bits
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
		
;Register f�r die Debugging funktionen.....
		
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
	MOVWF	TRISA		; RA0 Eingang (RA1 bis RA7 sind Ausg�nge)
	MOVLW	B'00000000'
	MOVWF	TRISB		; RB0 bis RB7 sind Ausg�nge
	
; Die Register TRISA und TRISB legen fest, welche Bits in den jeweiligen Ports Ein- bzw.
; Ausg�nge sind. Eine '1' an der entsprechenden Stelle setzt das Bit des Ports als Ein-
; gang eine '0' setzt das Bit als Ausgang.
	
	BCF	bank1		; wechsle zu Registerbank 0 (normaler Speicherbereich)
	
	CLRF	PORTA		; Port A l�schen
	CLRF	PORTB		; Port B l�schen


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

;PS2 - �bertragungsregister
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
;Ich haette auch alle (hab ich auch in einer fr�heren Programmversion)
;Initialisierungs Adressen/Befehle in Konstanten schreiben k�nnen. Da ich aber
;bei der Programmminimierung mir eine Senderoutine �berlegt habe, die mit einer
;dynamischen Tabelle die komplette �bertragung (Initialisierung + Anzeige) ab
;arbeitet verwende ich jetzt Register.

	MOVLW	B'00001011' 	; 0x0B Digitsanzahl Adresse
	MOVWF	m_DIGITS_adr
	MOVLW	B'00000100' 	; 0x01 Anzahl der aktivierten Digits 	->Digit 0 und 1<-
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
;K�nnte auch mit einem Zaehler gemacht werden, aber ich m�chte ausw�hlen
;wo welches Register angezeigt werden soll und auserdem ist es jetzt m�glich
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
	BSF	a_MAX_CLOCK	; ...�bertragungsmodus sein
;*****************
;* Hauptprogramm *
;*****************

main
	CALL	UP_wait_50us	;	
	BSF	a_ATT		; ATT auf HIGH, Controller wird abgew�hlt
				; (ignoriert alle Daten)
	CALL	UP_wait_25us
	BSF	a_CLOCK		; Clock HIGH
	BSF	a_COMMAND	; Command HIGH
	
	BCF	a_ATT		; ATT auf LOW das der Controller
				; die Daten annimmt
					
	CALL	UP_wait_50us	; Warteschlange bis Controller bereit ist
	
;#########		
;	BSF	a1;;;;;;;;;	;--------------------------------------------DEBUGGING
	CALL	UP_PSC_send_tabelle
	;CALL	UP_Start		;Senden:		H'01' Startbefehl
;	BCF	a1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########	
;	BSF	b1;;;;;;;;;	;--------------------------------------------DEBUGGING	
	;CALL	UP_Get_Type	;Senden:		H'42' Datenanfrage
 				;------------------------------------
				;Empfangen:	H'41'=Digital
 				;ODER		H'23'=NegCon
				;ODER		H'73'=Analogue Red LED
				;ODER		H'53'=Analogue Green LED
;	BCF	b1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	c1;;;;;;;;;	;--------------------------------------------DEBUGGING
	;CALL	UP_Get_Status	;Empfangen:  H'5A' - Status:READY
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	c1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	d1;;;;;;;;;	;--------------------------------------------DEBUGGING
	;CALL	UP_Get_L_btns	;Empfangen:  H'xx' - Status der linken Btns
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	d1;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	a2;;;;;;;;;	;--------------------------------------------DEBUGGING
	;CALL	UP_Get_R_btns	;Empfangen:  H'xx' - Status der rechten Btns
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	a2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	b2;;;;;;;;;	;--------------------------------------------DEBUGGING
	;CALL	UP_Get_R_Joy_X	;Empfangen:  H'xx' - rechtes Joystick, X-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	b2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	c2;;;;;;;;;	;--------------------------------------------DEBUGGING
	;CALL	UP_Get_R_Joy_Y	;Empfangen:  H'xx' - rechtes Joystick, Y-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	c2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	d2;;;;;;;;;	;--------------------------------------------DEBUGGING
	;CALL	UP_Get_L_Joy_X	;Empfangen:  H'xx' - linkes Joystick, X-Achse
				;------------------------------------
				;Senden:     H'00' - Idle-Modus
;	BCF	d2;;;;;;;;;	;--------------------------------------------DEBUGGING
;#########
;	BSF	c2;;;;;;;;;	;--------------------------------------------DEBUGGING
	;CALL	UP_Get_L_Joy_Y	;Empfangen:  H'xx' - linkes Joystick, Y-Achse
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
	 

GOTO	main			;Springe wieder an den Anfang zur�ck   

;******************
;* Unterprogramme *
;******************
;###############################################################################;###############################################################################
;###############################################################################;###############################################################################
UP_PSC_send_tabelle
	
	MOVLW	D'0'
	MOVWF	zaehler_tab
	
PSC_st1	MOVLW	D'8'
	MOVWF	zaehler_bit
	
	BCF      STATUS, IRP	; Bank 0 oder 1  
	
	MOVF	zaehler_tab,W	;wird mit dem PCL addiert
	
	CALL	tab_PSC		;�ffnet die "dynamische Tabelle"
				;Im Workregister steht jetzt die Adresse
    				;des Registers dessen Inhalt �bertragen werden soll
			     	
	MOVWF	FSR		;der Zeiger zeigt jetzt auf das Register
				;dessen Inhalt �bertragen werden soll
				
	MOVFW	INDF		;mit dem virtuellen Register INDF kann der
				;Inhalt des Registers ausgegeben werden,
    				;auf das der Zeiger FSR zeigt

	MOVWF	sPSC
	
	INCF	zaehler_tab	; n�chste Tabellenreihe
	
	MOVF	zaehler_tab,W	;wird mit dem PCL addiert
	CALL	tab_PSC		;�ffnet die "dynamische Tabelle"
				;Im Workregister steht jetzt die Adresse
    				;des Registers in das geschrieben wird
				    
	MOVWF	FSR		;der Zeiger zeigt jetzt auf das Register
				;dessen Inhalt �bertragen werden soll
				
	;mit dem virtuellen Register INDF kann der
	;Inhalt des Registers ge�ndert werden,
    	;auf das der Zeiger FSR zeigt				
					
PSC_1	RRF	sPSC		;verschiebe sende Register nach rechts...
	BTFSS	STATUS,C		;und pr�fe Wertigkeit des rausgeworfenen Bits
	GOTO	UP_sende_0	;(STATUS,C=0)-> �bertrage '0' an Controller...
	GOTO	UP_sende_1	;(STATUS,C=1)-> ansonsten �bertrage '1'	

PSC_2	DECF	zaehler_bit
	MOVF	zaehler_bit,F	; Z�hler ...
	BTFSS	STATUS,Z		; ... auf 0 pr�fen,
	GOTO	PSC_1		; <-- Z�hler != 0 --> n�chstes Bit �bertrag.
				; <-- Z�hler == 0
				 

	INCF	zaehler_tab
	MOVLW	D'20'		;PS2-Analog-Mode Controller
	SUBWF	zaehler_tab,W
	BTFSS	STATUS,Z		
	GOTO	PSC_st1		;zaehler_tab < 22
	RETURN			;zaehler_tab = 22
;###########################################################	
UP_sende_0
	BCF	a_COMMAND	;auf 0 setzten
	BCF	a_CLOCK		;negative Flanke (Controller lie�t a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 25�s !!!
	BTFSC	e_DATA		;e_DATA pr�fen
	GOTO	INDF_0_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	INDF_0_write_0	;empfangenes Bit in Carry-Flag setzen
INDF_0_next	
	RRF	INDF		;empfangenes Bit in Register hinzuf�gen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	PSC_2
;######################################	
INDF_0_write_1
	BSF	STATUS,C
	GOTO	INDF_0_next

INDF_0_write_0			;zur �bersicht, hier geschrieben!!!
	BCF	STATUS,C
	GOTO	INDF_0_next	
;###########################################################
UP_sende_1
	BSF	a_COMMAND	;auf 1 setzten
	BCF	a_CLOCK		;negative Flanke (Controller lie�t a_COMMAND)...
	CALL	UP_wait_25us	;aber erst nach 4�s !!!
	BTFSC	e_DATA		;e_DATA pr�fen
	GOTO	INDF_1_write_1	;empfangenes Bit in Carry-Flag setzen
	GOTO	INDF_1_write_0	;empfangenes Bit in Carry-Flag setzen
INDF_1_next	
	RRF	gTYPE		;empfangenes Bit in Register hinzuf�gen
	BSF	a_CLOCK
	CALL	UP_wait_25us
	GOTO	PSC_2
;######################################
INDF_1_write_1
	BSF	STATUS,C
	GOTO	INDF_1_next

INDF_1_write_0			;zur �bersicht, hier geschrieben!!!
	BCF	STATUS,C
	GOTO	INDF_1_next
;###############################################################################
;###############################################################################
UP_MAX_send_tabelle
	
	MOVLW	D'0'
	MOVWF	zaehler_tab	;Wenn zaehler_tab ungerade, 2.Byte gesendet
				;-> LOAD auf 1
	
MAX_st1	MOVLW	D'8'
	MOVWF	zaehler_bit
	
	BCF      STATUS, IRP	; Bank 0 oder 1  
	
	MOVF	zaehler_tab,W	;wird mit dem PCL addiert
	
	CALL	tab_MAX		;�ffnet die "dynamische Tabelle"
				;Im Workregister steht jetzt die Adresse
    				;des Registers dessen Inhalt �bertragen werden soll
			     	
	MOVWF	FSR		;der Zeiger zeigt jetzt auf das Register
				;dessen Inhalt �bertragen werden soll
				
	MOVFW	INDF		;mit dem virtuellen Register INDF kann der
				;Inhalt des Registers ausgegeben werden,
    				;auf das der Zeiger FSR zeigt
	;MOVWF	PORTB		; #############DEBUGGING#############
	;CALL	UP_wait_05s	; #############DEBUGGING#############
	MOVWF	sMAX
	
	BCF	a_MAX_LOAD	;Vor der �bertragung von 2 Bytes auf LOW
	
	
MAX_st2	RLF	sMAX		;MSB zuerst...
	BTFSC	STATUS,C
	GOTO	MAX_send_tabelle_1	;MAX-Datenleitung auf HIGH	(�bertrage 1)
	BCF	a_MAX_DATA		;MAX-Datenleitung auf LOW	(�bertrage 0)	
	
MAX_st3	BCF	a_MAX_CLOCK	;
	;CALL	UP_wait_05s	; #############DEBUGGING#############
	BSF	a_MAX_CLOCK	;Positive Flanke erzeugen
	BCF	a_MAX_CLOCK
	
	DECF	zaehler_bit
	MOVF	zaehler_bit,F	; Z�hler ...
	BTFSS	STATUS,Z		; ... auf 0 pr�fen,
	GOTO	MAX_st2		; <-- Z�hler != 0 --> n�chstes Bit �bertrag.
				; <-- Z�hler == 0
	
	BTFSC	zaehler_tab,0	; nach jedem 2. Byte LOAD auf 1 
	BSF	a_MAX_LOAD	; <-- Z�hler_tab == ungerade -> 2.Byte 
				; <-- Z�hler_tab == gerade -> 1.Byte
	INCF	zaehler_tab
	MOVLW	D'20'		;Steckplatine
	;MOVLW	D'22'		;sp�ter mit allen Digit anzeigen
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
;###########################      Warteschleifen     ###########################
;###############################################################################

;############################***********************############################
;###########################       MAX-Tabelle       ###########################

tab_MAX				;Tabellenl�nge: 22; -> zaehler_tab max. 22!
	BSF	PCLATH,0		;PCLATH auf ...
	BSF	PCLATH,1		;... 0x3 stellen
	MOVWF	PCL		;PCL ist jetzt 0x300 + zaehler_tab
	
	
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
; mit DT l�sst sich eine Wertetabelle aufbauen. Dabei steht jeder Wert f�r die Anweisung
; 'RETLW <wert>'. Die Tabelle l�sst sich also alternativ auch mit einer Liste von 'RETLW'-
; Anweisungen aufbauen.

END
