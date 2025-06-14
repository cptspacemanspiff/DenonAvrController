# get current state:
curl http://192.168.1.129/goform/formMainZone_MainZoneXml.xml

# mute
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutVolumeMute/on"

# unmute
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutVolumeMute/off"

# Volume decrement
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutMasterVolumeBtn/<"

# Volume increment
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutMasterVolumeBtn/>"

# set volume
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutMasterVolumeSet/-45.0"

# set source (we hid all other sources so it does not work...)
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutZone_InputFunction/USB/IPOD"

# Power Off
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutZone_OnOff/OFF"

# Power On
curl -X POST http://192.168.1.129/MainZone/index.put.asp -d "cmd0=PutZone_OnOff/ON"
