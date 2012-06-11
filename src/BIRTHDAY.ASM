**********************************************************
* 		Mikroprozessor-Programmierung		*
*		Abschlussaufgabe WS 05/06		*
*		"Glueckwunschkarte"			*
*							*
*		Ruediger Klante				*
*		Alexander Bertram			*
**********************************************************
* happy bday: g',g',a',g',c'',h',g',g',a',g',d'',c'',g',g',g'',e''
* (g-dur)     c'',c'',h',a',f'',f'',e'',c'',d'',c''


		include simregs.inc
		include gptregs.inc


anaout		equ	$21001		; Analoger Ausgang (Multi I/O)
c		equ	264		; c' -> 264 Hz
d		equ	297		; d' -> 297 Hz
e		equ	334 		; e' -> 334 Hz
f		equ	356		; f' -> 356 Hz
g		equ	401		; g' -> 401 Hz
a		equ	440		; a' -> 440 Hz ("Kammerton" A)
h		equ	495		; h' -> 495 Hz
c1		equ	528		; c'' -> 528 Hz
de1		equ	594		; d'' -> 594 Hz
e1		equ	668		; e'' -> 668 Hz
f1		equ	713		; f'' -> 713 Hz
g1		equ	802		; g'' -> 802 Hz
achtel		equ	32		; Laenge fuer Achtelnote
viertel		equ	64		; Laenge fuer Viertelnote
halbe		equ	128		; Laenge fuer Halbe Note
ganze		equ	256		; Laenge fuer Ganze Note


		org	$10000
SSP		dc.l	$20000
Reset		dc.l	$10400


		org	$10100
		dc.l	Interrupt

		org	$11000
*		C-Dur Tonleiter zum freien Spiel
toene		dc.w	c,d,e,f,g,a,h,c1

*		Melodie "Happy Birthday" (in G-Dur)
happy		dc.w	g,g,a,g,c1,h,g,g,a,g,de1,c1,g
		dc.w	g,g1,e1,c1,c1,h,a,f1,f1,e1,c1,de1,c1

*		Tabelle mit Werten fuer Rechtecksignal
rechteck 	dc.b	255,255,255,255,255,255,255,255
		dc.b	255,255,255,255,255,255,255,255
		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	
*		Tabelle mit Werten fuer Saegezahnsignal	
saege		dc.b	128,136,144,152,160,168,176,184
		dc.b	192,200,208,216,224,232,240,248
		dc.b	0,8,16,24,32,40,48,56,64,72,80,88
		dc.b	96,104,112,120

*		Tabelle mit Werten fuer Sinussignal
sinus		dc.b	128,153,177,199,219,234,246,254,255
		dc.b	254,246,234,219,199,177,153,128
		dc.b	103,79,57,37,22,10,2,0
		dc.b	2,10,22,37,57,79,103
	
* 		Tabelle fuer den Takt der Melodie
laenge		dc.b	achtel,achtel,viertel,viertel,viertel,halbe
		dc.b	achtel,achtel,viertel,viertel,viertel,halbe
		dc.b	achtel,achtel,viertel,viertel,achtel,achtel
		dc.b	viertel,viertel,achtel,achtel,viertel,viertel
		dc.b	viertel,halbe		

*		Tabelle mit Tastencodes 0-9 und #,*		
tcode		dc.b	234,118,122,124,182,186,188,214,218,220,236,230

*		Stellencodes zum Multiplexen der Anzeige
stelle		dc.b	$70,$b0,$d0,$e0



		org	$14000
timer		ds.w	1		; Timer fuer Takt der Melodie
tontimer		ds.w	1		; Timer fuer Tonerzeugung
frequenz		ds.w	1		; Frequenz des aktuellen Tons
index		ds.b	1		; index in die Melodietabelle
bday		ds.b	1		; Melodie-Flag
stell_index	ds.b	1		; Stellenindex fuer Anzeige
ton		ds.b	1		; Tonindex
stop		ds.b	1		; Stop-Flag (Stoppen alles sounds)
tonpointer	ds.b	1		; Pointer fuer aktuellen Tontyp
notoggle		ds.b	1		; Flag, ob Tontyp gewechselt werden kann


**************************************************
* 	Start des Hauptprogramms		*
* 	   "Happy Birthday"			*
**************************************************
		org	$10400
start		move.w	#1,pitr     ; Interruptrate = 8 kHz
		move.w	#$0140,picr ; IRQ-Level 1 , Vektor 64
		move.b	#$FF,ddrgp  ; Initialisierung
		move.b	#$00,portgp ; der Sieben-Segment
		move.b	#$F0,ddrf   ; Anzeige
		move.b	#$FF,portf	
			
		clr.l	d0		; Loeschen aller 
		clr.l	d1		; Register und
		clr.l	d2		; Variablen
		clr.l	d3
		clr.l	d4
		clr.l	d5
		clr.l	d6
		clr.l	d7
		clr.w	frequenz
		clr.b	index
		clr.b	timer
		clr.b	bday
		clr.b	stell_index
		clr.b	ton
		clr.b	stop
		clr.w	tontimer
		clr.b	tonpointer
		
		lea	happy,a0		; Initialisierung
		move.b	0(a0),frequenz		; der Variablen
		lea	laenge,a1
		move.b	0(a1),d2
		asl.l	#5,d2
		move.w	d2,timer

		move.b	#0,bday			
		move.b	#1,stop			
		move.b	#4,stell_index
		move.b	#1,tonpointer
		move	$2000,SR
	
endlos		bra	endlos

*************************************************
* Subroutine zur Erzeugung der Melodie		*
* "Happy Birthday"				*
*************************************************
happybday	movem.l	d0-d2/a0/a1,-(a7)	;Register auf Stack
		clr.l	d0			;Leeren
		clr.l	d1			;der
		clr.l	d2			;Datenregister

		lea	happy,a0	; Laden der Tabellen Melodie
		lea	laenge,a1	; und Laenge
		subi.w	#1,timer	; Decrement Timer Tonlaenge
		bne	go				
	
		addi.b	#1,index	; Increment Index in Melodietabelle
		move.b	index,d1	; Index -> d1
			
		cmp.b	#26,d1		; Melodie Zuende?
		bne	gogo
		move.b	#0,bday		; Stoppen der Melodie
		move.b	#1,stop		; Alle Toene aus
		clr.w	timer		; Ruecksetzen timer
		clr.b	index		; Ruecksetzen index
		clr.l	d1
		
gogo		lsl.b	#1,d1			; Index an Word-Tabelle anpassen
		move.w	0(a0,d1.w),frequenz	; Tonfrequenz laden			
		move.b	index,d1		
		move.b	0(a1,d1.w),d2		; Tonlaenge
		asl.w	#6,d2			; laden
		move.w	d2,timer		; und anpassen
go		bsr makethesound		; -> Tonerzeugung

		clr.l	d1
		move.b	index,d1
		
		lsl.b	#1,d1			; Index an Word-Tabelle anpassen
		move.w	0(a0,d1.w),frequenz	; Laden der Frequenz
		

weiter		movem.l	(a7)+,d0-d2/a0/a1	;Register vom Stack			
		rts
		

***************************************************
* Subroutine zur Tonerzeugung			 *
* Hier wird die jeweilige Signalkurve durchlaufen *
***************************************************
makethesound	movem.l d0/d1/a0/a1,-(a7)
		clr.l	d0		; Register Loeschen
		clr.l	d1
		move.w	frequenz,d1	; Tonfrequenz laden
		add.w	d1,tontimer	; Zaehler + Tonfrequenz
		move.w	tontimer,d0	
		and.w	#%1111111100000000,d0	; Auslesen
		lsr.w	#8,d0			; Signifikanter Stellen
		and.b	#%00011111,d0		; des Tontimers
		clr.l	d1
		move.b	tonpointer,d1		; Auswahl des
		cmp.b	#1,d1			; Tontyps
		beq	loadsinus		; fuer Wiedergabe
		cmp.b	#2,d1
		beq	loadsaege
		lea	rechteck,a1		; Rechteck laden
		bra	endmts
	
loadsinus	lea	sinus,a1		; Sinus laden
		bra	endmts
loadsaege	lea	saege,a1		; Saegezahn laden

endmts		move.b	0(a1,d0.w),anaout	; Tonausgabe
		movem.l (a7)+,d0/d1/a0/a1
		rts


**************************************************
* Subroutine zum Umschalten der Tonform		*
* Ein Tonpointer wird gesetzt, wobei		*
* 1 = sinus ; 2 = saegezahn ; 3 = rechteck	*
**************************************************		
toggle_sounds	movem.l	d0,-(a7)	
		move.b	tonpointer,d0		; Setzen des
		cmp.b	#1,d0			; Tonpointers
		beq	setsaege		; in Abhaengigkeit
		cmp.b	#2,d0			; von aktueller
		beq	setrechteck		; Tonform
		move.b	#1,tonpointer		; 1 = Sinus
		bra	endtoggle
setsaege		move.b	#2,tonpointer		; 2 = Saegezahn
		bra	endtoggle
setrechteck	move.b	#3,tonpointer		; 3 = Rechteck

endtoggle	movem.l	(a7)+,d0
		rts
		
**************************************************
* Interrupt-Routine				*
* Multiplexing der Anzeige			*
* Tastenabfrage					*
**************************************************
Interrupt	movem.l	d0-d7/a0-a2,-(a7)	;Register auf Stack
		clr.l	d0		;Leeren
		clr.l	d1		;der
		clr.l	d2		;Daten-
		clr.l	d3		;Register
		clr.l	d4
		clr.l	d5
		clr.l	d6
		clr.l	d7

		move.b	bday,d3		; Pruefen des Birthday-Flags
		beq	anzeige		; wenn nicht gesetzt, ueberspringen

		bsr	happybday	; Wiedergabe "Happy Birthday"

*		Multiplexen der Anzeige (zur Tastenerkennung)
anzeige		clr.l	d0
		lea	stelle,a2		; Ansteuern
		move.b	stell_index,d7		; des Stellentreibers
		move.b	-1(a2,d7.w),portf	; zum Lesen der Tastatur

		sub.b	#1,stell_index		; letzte Stelle erreicht?
		bne	weiter2
		move.b	#4,stell_index		; Index zuruecksetzen

*		keine taste gedrueckt?		
weiter2		move.b	portf,d5		; Pruefen ob keine Taste
		and.b	#%00001110,d5		; gedrueckt
		cmp.b	#14,d5			; wenn ja
		beq	weiter1			; direkt weiter 
						
		move.b	portf,d5	
		and.b	#%11111110,d5	; loeschen bit 0
*					; -> nicht signifikant

		lea	tcode,a1
		clr.l	d6
		cmp.b	11(a1),d5	; wurde * gedrueckt?
		beq	starpressed	; -> starpressed
		cmp.b	10(a1),d5	; wurde # gedrueckt?
		beq	rautepressed	; -> rautepressed
		cmp.b	(a1)+,d5	; wurde 0 gedrueckt?
		beq	nullpressed	; -> nullpressed
	
		
tloop		add.b	#1,d6		; Erkennung gedrueckter Taste
		cmp.b	(a1)+,d5	; mit Erzeugung von Index
		beq	continue	; in Tastentabelle
		cmp.b	#8,d6
		bne	tloop
		bra	weiter1		; Taste 9 verhaelt sich wie 0

nullpressed	move.b	#1,stop         ; bei gedrueckter 0
		move.b	#0,bday		; -> Stoppen des Tons bzw
		clr.b	notoggle	; notoggle flag zuruecksetzen
		bra	weiter1		; der Melodie

rautepressed	move.b	#1,bday		; bei gedrueckter #
		move.b	#0,index	; starten der Melodie "Happy Birthday"
		move.b	#1,notoggle	; notoggle flag setzen
		bra	weiter1	

starpressed	clr.l	d0		
		move.b	notoggle,d0	; wenn notoggle gesetzt
		bne	weiter1		; weiter, NICHT togglen
		bsr	toggle_sounds	; -> Ton umschalten
		move.b	#1,notoggle	; notoggle flag setzen
		move.b	#1,stop		; Ton wird gestoppt
		bra	weiter1
			
continue		lea	toene,a1	
		move.b	d6,ton 		 ; Sichern des Tonindexes
		sub.b	#1,d6		 ; Anpassung des Tastenindexes
		lsl.b	#1,d6		 ; an Word-Tabelle
		move.w	0(a1,d6.w),frequenz  ; Laden entsprechender Frequenz
		move.b	#0,bday		   ; Stoppen der Melodie
		move.b	#0,stop		   ; loeschen Stop-Flag
		clr.b	notoggle

weiter1		move.b	bday,d0		   ; soll Melodie gespielt werden?
		bne	fertig
		move.b	stop,d0		   ; soll nichts gespielt werden?
		bne	fertig
		bsr	makethesound	   ; -> Ton erzeugen
		lea	toene,a1	     
		move.b	ton,d6		   ; Laden des aktuellen Tons
		sub.b   #1,d6		   ; und Anpassen des Indexes	
		lsl.b	#1,d6		   ; an Word-Tabelle  	
		move.w	0(a1,d6.w),frequenz  ; Laden Frequenz aktuellen Tons

			
fertig		movem.l	(a7)+,d0-d7/a0-a2	;Register vom Stack			
	 	rte

		end	start