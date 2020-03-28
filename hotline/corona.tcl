#!/usr/bin/tclsh
package require ygi
package require uuid
package require http
package require tls
package require json::write

#set ::ygi::debug true
::http::register https 443 ::tls::socket

#modified from bef
## stream soundfile(s) and wait for user input
proc play_getdigits {soundfile {maxdigits 1} {wait 10000} } {
	set digits [::ygi::play_getdigit file $soundfile]
	if {$digits ne ""} {incr maxdigits -1}

	if {$maxdigits} {
		append digits [::ygi::getdigits maxdigits $maxdigits digittimeout $wait enddigit ""]
	}

	return $digits
}


::ygi::start_ivr
::ygi::idle_timeout
::ygi::set_dtmf_notify

::ygi::play_wait "yintro"

regsub -all {[^\d]} $ygi::env(caller) {} caller_id
regsub {^\+} $caller_id {00} caller_id
::ygi::log "in_line: $ygi::env(in_line)"

if {$ygi::env(in_line) eq "epvpn" } {
    set url "https://hookb.in/yDL1djMbXZUeWb73yzkg"
    set token "<private non public secure token>"
} else {
    set url "https://<redacted>/api/requests"
    set token "<redacted>"
}

::ygi::sleep 500

#Willkommen bei der Corona Nachbarschaftshilfe. Dies ist keine Notrufnummer. Bei Notfällen wählen Die bitte die 112.Nutzen Sie diese Hotline bitte nur, wenn jemand für Sie eine Aufgabe erledigen soll.
#Wenn SIe dagegen mit jemandem Sprechen möchten, ist das Silbernetz für Sie da. Die Nummer des Silbernetz ist: 0800 4708090.(Pause)Wir versuchen nun ihnen Menschen zu vermitteln, die in ihrer Nähe wolhnen und
#bereit sind, Nachbarn zu helfen. Die Hilfe kann in Form von Besorgungen, Einkäufen oder das Finden von Ansprechpartnern für bestimmte Probleme erfolgen. Ihre Rufnummer wird jetzt an freiwilligen Netzwerke weitergeleitet.
# Die Menschen dort können Sie zurückrufen. Wir hoffen, dass so ein Kontakt zustande kommt. Ob und wann sie angerufen werden, können wir nicht beeinflussen.

#Bitte geben sie nun über die Tasten auf ihrem Telefon ihre Postleitzahl ein.
set plz [play_getdigits gdv/ansage_1_intro_plz.slin 5]
if {$plz eq ""} {
    set plz 00000
}
::ygi::log "plz: $plz"
::ygi::clear_dtmfbuffer

::ygi::play_getdigit file gdv/ansage_2_intro_hilfe.slin stopdigits {#}
::ygi::clear_dtmfbuffer
#Bitte wählen Sie nun, womit wir Ihnen helfen können:
#1:Einkauf, 2:Hilfe mit Tieren, 3:Reparaturen, 4:Sonstiges
for {set i 0} {$i < 3} {incr i} {
    set help_id [play_getdigits gdv/ansage_3_auswahl_der_hilfe.slin 1 5000]
    if {$help_id ne ""} {break}
}

::ygi::log "help_id: $help_id"
if {$help_id eq 5} {
	::ygi::log "redirecting..."
    if {$ygi::env(in_line) eq "epvpn"} {
        # Test environment
        set callto sip/2089
        set line epvpn
    } else {
        set callto sip/08004708090
        set line easybell
    }
    set success [::ygi::msg chan.masquerade id $ygi::env(id) message call.execute callto $callto line $line callername $caller_id osip_From "<sip:004971729340048@easybell.de>"]
    if {!$success} {
        ::ygi::log "fail"
        ::ygi::play_force gdv/ansage_sibernetz_fail.slin
    }
} else {

    set filename [concat [clock format [clock seconds] -format %G-%m-%dT%TZ -timezone UTC]_${caller_id}_[uuid::uuid generate]]
    set filepath "/opt/corona/incoming/$filename"

    regsub {[^\d]|^$} $help_id {-1} help_id_cleaned
    set query [ ::json::write object "token" [::json::write string $token] "phone" [::json::write string $caller_id] "zip" [::json::write string $plz] "request" [::json::write string $help_id_cleaned]]
    set header [list "Content-Type" "application/json"]
    if { [ catch { set response [ ::http::geturl $url -query $query -headers $header ] } err ] } {
        set subject_file [open "$filepath.connection.sbj" w]
        puts $subject_file $query
        close $subject_file
    } else {
        ::ygi::log "response $response"
        set response_code [::http::ncode $response]
        ::ygi::log "response code: $response_code"

        if {$response_code ne 200} {
            set subject_file [open "$filepath.response.sbj" w]
            puts $subject_file $query
            close $subject_file
        }
    }

    #Vielen Dank. Wir haben ihre Anfrage erhalten und versuchen für Sie eine passende Person in ihrer Nachbarschaft zu finden.
    ::ygi::play_force "gdv/ansage_4_vielen_dank.slin"
    ::ygi::sleep 500
}

