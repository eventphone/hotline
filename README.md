# minimal hotline setup

This is an example of a minimal [yate](https://docs.yate.ro/wiki/Main_Page) setup, which registers via an upstream SIP trunk and answers all calls with script.

## How to

### get the source

``` sh
git clone https://github.com/eventphone/hotline
cd hotline
git submodule update --init --recursive
```

### modify SIP settings

Update [accfile.conf](config/accfile.conf) with your SIP Account credentials. If you don't have a SIP Account, you may use an [EPVPN Account](https://eventphone.de/doku/epvpn) for __testing__ purposes.

### script your hotline

We've currently 4 example hotlines:

- [hotline.tcl](hotline/hotline.tcl) - the famous PoC Service Hotline as heard on many CCC Events
- [corona.tcl](hotline/corona.tcl) - the latest version of the gemeinschaft.online hotline
  - ask for zipcode (via DTMF)
  - ask for topic (via DTMF)
  - send HTTP API Request with caller number, zip code and topic to REST Endpoint
  - if anything goes wrong save the request to the filesystem for manual inspection
- [corona.py](hotline/corona.py) - python version of the gemeinschaft.online hotline
- [api.tcl](hotline/api.tcl) - minimal HTTP API Example, which sends the caller number to an HTTP endpoint and plays success or failed messages

More examples can be found in the [yate-tcl](https://github.com/bef/yate-tcl) repository.

If you want to use custom audio files, place them in the [sounds](sounds) directory

### convert your audio files

You can use the following sox command to convert your mp3 or wav files to slin:

```sh
sox input.mp3 -t raw -r 8000 -c 1 output.slin
```

You may need to install the sox format handler:

```sh
apt install libsox-fmt-mp3
```

### configure your hotline

Update [regexroute.conf](config/regexroute.conf) to point to your custom hotline script. You can also route to different scripts depending on the caller or dialed number. Details can be found in the [Yate WIKI](https://docs.yate.ro/wiki/Regular_expressions#The_regexroute_configuration_file).

### build your custom docker container

``` sh
docker build -t your_fancy_hotline .
```

### run

``` sh
docker run -it your_fancy_hotline
```

## Help

If you need any additional help, you may contact us via our [support](https://guru3.eventphone.de/support/).
