#!/usr/bin/tclsh
package require ygi
package require uuid
package require http
package require tls
package require json::write

::http::register https 443 ::tls::socket

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

set url "https://hookb.in/yDL1djMbXZUeWb73yzkg"
set token "<private non public secure token>"

::ygi::start_ivr
::ygi::idle_timeout
set ::ygi::debug true


::ygi::set_dtmf_notify

::ygi::play_wait "yintro"

regsub -all {[^\d]} $ygi::env(caller) {} caller_id

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
if {$help_id eq ""} {
     set help_id -1
}
if {$help_id eq "*"} {
     set help_id -1
}
if {$help_id eq "#"} {
     set help_id -1
}

set query [ ::json::write object "token" [::json::write string $token] "phone" [::json::write string $caller_id] "zip" [::json::write string $plz] "request" [::json::write string $help_id]]
set header [list "Content-Type" "application/json"]
set response [ ::http::geturl $url -query $query -headers $header ]
::ygi::log "response $response"
set response_code [::http::ncode $response]
::ygi::log "response code: $response_code"

#Vielen Dank. Wir haben ihre Anfrage erhalten und versuchen für Sie eine passende Person in ihrer Nachbarschaft zu finden.
::ygi::play_force "gdv/ansage_4_vielen_dank.wav"
