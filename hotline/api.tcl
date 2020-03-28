#!/usr/bin/tclsh
package require ygi
package require http
package require tls
package require json::write

set ::ygi::debug true
::http::register https 443 ::tls::socket

::ygi::start_ivr

::ygi::play_wait yintro.slin
::ygi::sleep 500

# request can be examined at https://hookbin.com/mZJqNOXaoXsBVLpJXYE0
set url "https://hookb.in/mZJqNOXaoXsBVLpJXYE0"
set caller_id $ygi::env(caller)

::ygi::play_wait api/intro.slin

set query [ ::json::write object "phone" [::json::write string $caller_id]]
set header [list "Content-Type" "application/json"]
if { [ catch { set response [ ::http::geturl $url -query $query -headers $header ] } err ] } {
    ::ygi::play_wait api/failed.slin
} else {
    ::ygi::log "response $response"
    set response_code [::http::ncode $response]
    ::ygi::log "response code: $response_code"

    if {$response_code ne 200} {
        ::ygi::play_wait api/failed.slin
    } else {
        ::ygi::play_wait api/success.slin
    }
}

::ygi::sleep 500