#!/bin/bash
# https://www.openstreetmap.org/export#map=19/47.54412/9.68215&layers=N

# Function to run when Ctrl+C is pressed
function on_interrupt {
    echo "Ctrl+C pressed. Aborting..."
    # Your abort command here
    docker stop seamap_renderer
    docker stop osm_renderer
    exit 1  # Exit the script with an error status
}
# Trap SIGINT (Ctrl+C) and call the function on_interrupt
trap on_interrupt SIGINT
trap on_interrupt  INT

level_start=2
level_end=19
latStart=47.82
lonStart=8.86
latEnde=47.47
lonEnde=9.8
data_dir="./data"

name_osm="OpenSeaMapOfflineLakeConstance"
name_seamap="OpenSeaMapOfflineLakeConstance"

cd ${data_dir}/seamap_tiles
# python3 -m http.server 2> /dev/zero > /dev/zero &
docker run -v ${data_dir}/:/opt/app/data -e "APP_MODE=command" -e "TILESERVER_TYPE=osm" -e "TILESERVER_ENDPOINT=http://172.17.0.1:8000/{z}/{x}/{y}.png" -e "APP_TIMEOUT=3000" -e "APP_MINZOOM=9" -e "APP_MAXZOOM=18" -e "APP_MAXAREA=160000" ghcr.io/kastb/docker-openseamap-renderer
 /opt/app/app.sh --left=${lonStart} --bottom=${latEnde}  --top=${latStart} --right=${lonEnde}

echo "stop docker containers? [y/n]"
read choice
if [ "$choice" != "y"   ]; then
	docker stop seamap_renderer
	docker stop osm_renderer
fi
