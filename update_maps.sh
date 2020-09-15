#!/bin/bash
# https://www.openstreetmap.org/export#map=19/47.54412/9.68215&layers=N
echo "expecting a new ${data_dir}/data.osm.bz2"
data_dir="/data/osm"
#!/bin/bash
level_start=2
level_end=19
latStart=47.82
lonStart=8.86
latEnde=47.47
lonEnde=9.8

#curl -v -v -d @changeset.osm -H "X_HTTP_METHOD_OVERRIDE: PUT" "https://api.openstreetmap.org/api/0.6/map?bbox=${latEnde},${lonEnde},${latEnde},${lonStart}"
#https://api.openstreetmap.org/api/0.6/map?bbox=47.47,8.86,47.47,9.8
#wget -O ${data_dir}/data.osm https://overpass-api.de/api/map?bbox=${lonStart},${latEnde},${lonEnde},${latStart}
#bzip2 -z -c ${data_dir}/data.osm > ${data_dir}/data.osm.bz2
#rm data.osm

name_osm="OpenSeaMapOfflineLakeConstance"
name_seamap="OpenSeaMapOfflineLakeConstance"

# cleanup / build
# docker system prune -a -y
docker build -t seamap_renderer -f DockerfileSeamapRenderer .
docker build -t osm_renderer -f DockerfileOSMRenderer .

# OpenSeamap rendering
mkdir -p ${data_dir}/seamap_tiles/
docker run -v ${data_dir}:/data seamap_renderer
echo """
{
        "bounds": [
        ${lonStart},
        ${latEnde},
        ${lonEnde},
        ${latStart}
        ],
        "minzoom": ${level_start},
        "maxzoom": ${level_end},
        "name": "${name_seamap}",
        "description": "${name_seamap}",
        "format": "png"
    }

""" > ${data_dir}/seamap_tiles/manifest.json


docker run -p 8008:80 -v /data/:/data -e DATA="${data_dir}/data.osm.bz2" osm_renderer &

# either directory (possibly with squashfs compression)
sleep 300
python3 download_tiles.py level_start level_end latStart lonStart latEnde lonEnde "${name_osm}" "${data_dir}/osm_tiles"
mksquashfs seamap_tiles osm_tiles offline_tiles.squashfs -comp lz4
echo "shutdown of docker containers necessary"
exit(0)

# or mbtiles
# Openseamap mbtiles
cd ${data_dir}/seamap_tiles
python -m SimpleHTTPServer 2> /dev/zero > /dev/zero &
docker run -v ${data_dir}/:/opt/app/data -e "APP_MODE=command" -e "TILESERVER_TYPE=osm" -e "TILESERVER_ENDPOINT=http://172.17.0.1:8000/{z}/{x}/{y}.png" -e "APP_TIMEOUT=3000" -e "APP_MINZOOM=9" -e "APP_MAXZOOM=18" -e "APP_MAXAREA=160000" mapsquare/mbtiles-generator-server /opt/app/app.sh --left=8.86 --bottom=47.42 --top=47.82 --right=9.8 

# Openstreetmap mbtiles
docker run -v ${data_dir}/:/opt/app/data -e "APP_MODE=command" -e "TILESERVER_TYPE=osm" -e "TILESERVER_ENDPOINT=http://172.17.0.1:8008/hot/{z}/{x}/{y}.png" -e "APP_TIMEOUT=3000" -e "APP_MINZOOM=2" -e "APP_MAXZOOM=19" -e "APP_MAXAREA=160000" mapsquare/mbtiles-generator-server /opt/app/app.sh --left=8.86 --bottom=47.42 --top=47.82 --right=9.8 



