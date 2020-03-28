# minimal hotline setup

This is an example of a minimal [yate](https://docs.yate.ro/wiki/Main_Page) setup, which registers via an upstream SIP trunk and answers all calls with script. A similar setup is used for the hotline of https://gemeinschaft.online.

## How to

### get the source

``` sh
git clone https://github.com/eventphone/hotline
```

### modify SIP settings

Update [accfile.conf](config/accfile.conf) with your SIP Account credentials. If you don't have a SIP Account, you may use an [EPVPN Account](https://eventphone.de/doku/epvpn) for testing purposes.

### script your hotline

We've currently 3 example hotlines:

- [hotline.tcl](hotline/hotline.tcl) - the famous PoC Service Hotline as heard on many CCC Events
- [corona.tcl](hotline/corona.tcl) - the latest version of the gemeinschaft.online hotline
  - ask for zipcode (via DTMF)
  - ask for topic (via DTMF)
  - send HTTP API Request containing caller number, zip code and topic to REST Endpoint
- [corona.py](hotline/corona.py) - python version of the gemeinschaft.online hotline

More examples can be found in the [yate-tcl](https://github.com/bef/yate-tcl) repository.

If you want to use custom audio files, place them in the [sounds](sounds) directory

### build your custom docker container

``` sh
docker build -t your_fancy_hotline .
```

### run

``` sh
docker run -it your_fancy_hotline
```
