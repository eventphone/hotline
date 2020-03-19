#!/usr/bin/tclsh
package require ygi
package require uuid


#modified from bef
## stream soundfile(s) and wait for user input
proc play_getdigits {soundfile {maxdigits 1} {wait 10000} } {
	set digits [::ygi::play_getdigit file $soundfile]
	if {$digits ne ""} {incr maxdigits -1}
	
	if {$maxdigits} {
		append digits [::ygi::getdigits maxdigits $maxdigits digittimeout $wait]
	}
	
	return $digits
}


::ygi::start_ivr
::ygi::idle_timeout
set ::ygi::debug true


::ygi::set_dtmf_notify

::ygi::play_wait "yintro"

regsub -all {[^\d]} $ygi::env(caller) {} caller_id

set filename [concat [clock format [clock seconds] -format %G-%M-%dT%TZ -timezone UTC]_${caller_id}_[uuid::uuid generate]]
set filepath "/opt/corona/incoming/$filename"

set subject_file [open "$filepath.sbj" w]
puts $subject_file $caller_id
close $subject_file

::ygi::sleep 500

#Willkommen bei der Corona Nachbarschaftshilfe. Dies ist keine Notrufnummer. Bei Notfällen wählen Die bitte die 112.Nutzen Sie diese Hotline bitte nur, wenn jemand für Sie eine Aufgabe erledigen soll.
#Wenn SIe dagegen mit jemandem Sprechen möchten, ist das Silbernetz für Sie da. Die Nummer des Silbernetz ist: 0800 4708090.(Pause)Wir versuchen nun ihnen Menschen zu vermitteln, die in ihrer Nähe wolhnen und 
#bereit sind, Nachbarn zu helfen. Die Hilfe kann in Form von Besorgungen, Einkäufen oder das Finden von Ansprechpartnern für bestimmte Probleme erfolgen. Ihre Rufnummer wird jetzt an freiwilligen Netzwerke weitergeleitet.
# Die Menschen dort können Sie zurückrufen. Wir hoffen, dass so ein Kontakt zustande kommt. Ob und wann sie angerufen werden, können wir nicht beeinflussen.

#Bitte geben sie nun über die Tasten auf ihrem Telefon ihre Postleitzahl ein.
set plz [play_getdigits gdv/ansage_1_intro_plz.wav 5]
if {$plz eq ""} {
    set plz 00000
}
::ygi::clear_dtmfbuffer

#Bitte wählen Sie nun, womit wir Ihnen helfen können:
#1:Einkauf, 2:Hilfe mit Tieren, 3:Reparaturen, 4:Sonstiges
set help_id [play_getdigits gdv/ansage_2_auswahl_der_hilfe.wav]
::ygi::log "help_id: $help_id"
set mail_body "$plz\n$help_id"
set body_file [open "$filepath.bdy" w]
puts $body_file $mail_body
close $body_file

#Vielen Dank. Wir haben ihre Anfrage erhalten und versuchen für Sie eine passende Person in ihrer Nachbarschaft zu finden.
::ygi::play_force "gdv/ansage_4_vielen_dank.wav"
