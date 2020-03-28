#!/usr/bin/python3
import asyncio
import datetime
import logging
import os
import re
import uuid

import requests
from yate.protocol import MessageRequest
from yate.ivr import YateIVR

LOG_FILE = "/tmp/corona-ivr.log"

SOUNDS_PATH = "/opt/sounds"
URL = "https://hookb.in/yDL1djMbXZUeWb73yzkg"
API_TOKEN = "12345"
FORWARD_PHONE_ADDRESS = "sip/2001"
LINE = "test_line"
SIP_FROM_HEADER = "<sip:1234@eventphone>"

FALLBACK_FILES_DIR = "/opt/corona/incoming"


async def main(ivr: YateIVR):
    caller_id = ivr.call_params.get("caller", "")
    caller_id = re.sub("[^\\d]", "", caller_id)
    caller_id = re.sub("^\\+", "00", caller_id)

    await ivr.play_soundfile(os.path.join(SOUNDS_PATH, "yintro.slin"), complete=True)
    await asyncio.sleep(0.5)

    await ivr.play_soundfile(os.path.join(SOUNDS_PATH, "ansage_1_intro_plz.slin"))
    plz = await ivr.read_dtmf_symbols(5)
    if len(plz) != 5:
        plz = "00000"
    await ivr.play_soundfile(os.path.join(SOUNDS_PATH, "ansage_2_intro_hilfe.slin"), complete=True)

    for _ in range(3):
        await ivr.play_soundfile(os.path.join(SOUNDS_PATH, "ansage_3_auswahl_der_hilfe.slin"))
        help_id = await ivr.read_dtmf_symbols(1, 34)
        if help_id in ["1", "2", "3", "4", "5"]:
            break
    if help_id == "":
        help_id = "5"

    if help_id == "5":
        call_msg = MessageRequest("chan.masquerade", {
            "message": "call.execute",
            "id": ivr.call_id,
            "callto": FORWARD_PHONE_ADDRESS,
            "line": LINE,
            "oconnection_id": "external_udp",
            "osip_From": SIP_FROM_HEADER,
        })
        result = await ivr.send_message_async(call_msg)
        if not result.processed:
            await ivr.play_soundfile(os.path.join(SOUNDS_PATH, "ansage_sibernetz_fail.slin"), complete=True)
    else:
        query = {
            "token": API_TOKEN,
            "phone": caller_id,
            "zip": plz,
            "request": help_id,
        }
        success = True
        error_message = ""
        try:
            api_result = requests.get(URL, query)
        except requests.exceptions.RequestException as e:
            success = False
            error_message = str(e)

        if success and api_result.status_code != 200:
            success = False
            error_message = "HTTP error: " + str(api_result.status_code)

        if not success:
            fallback_filename = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-") + uuid.uuid4().hex + "response.sbj"
            fallback_file = os.path.join(FALLBACK_FILES_DIR, fallback_filename)
            with open(fallback_file, "w") as f:
                f.write(error_message + "\n")
                f.write(repr(query))
        else:
            await ivr.play_soundfile(os.path.join(SOUNDS_PATH, "ansage_4_vielen_dank.slin"), complete=True)
            await asyncio.sleep(0.5)


logging.basicConfig(filename=LOG_FILE, filemode="a+")
app = YateIVR()
app.run(main)
