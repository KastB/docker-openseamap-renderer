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

file="${data_dir}/data.osm.bz2"
# Check if the folder exists and the file exists within that folder
if [ -d "$data_dir" ] && [ -e "$file" ]; then
    echo "File $file exists. Continuing..."
else
    # If folder or file doesn't exist, execute the commands
    echo "Folder or file does not exist. Executing commands..."
	mkdir -p ${data_dir}
    wget -O ${data_dir}/data.osm https://overpass-api.de/api/map?bbox=${lonStart},${latEnde},${lonEnde},${latStart}
    bzip2 -z -c ${data_dir}/data.osm > ${data_dir}/data.osm.bz2
    rm "${data_dir}/data.osm"
fi

name_osm="OpenSeaMapOfflineLakeConstance"
name_seamap="OpenSeaMapOfflineLakeConstance"

# cleanup / build
# docker system prune -a -y
docker build -t seamap_renderer -f DockerfileSeamapRenderer .
docker build -t osm_renderer -f DockerfileOSMRenderer .


mkdir -p ${data_dir}/seamap_tiles/
echo """
{
        \"bounds\": [
        ${lonStart},
        ${latEnde},
        ${lonEnde},
        ${latStart}
        ],
        \"minzoom\": ${level_start},
        \"maxzoom\": ${level_end},
        \"name\": \"${name_seamap}\",
        \"description\": \"${name_seamap}\",
        \"format\": \"png\"
    }

""" > ${data_dir}/seamap_tiles/metadata.json

# OpenSeamap rendering
docker run --rm  --name seamap_renderer -v ${data_dir}:/data seamap_renderer &
# docker run --rm --name  osm_renderer -p 8008:80 -v ${data_dir}/:/data -e DATA="${data_dir}/data.osm.bz2" osm_renderer &

# either directory (possibly with squashfs compression)
sleep 300
echo "Start rendering"
python3 download_tiles.py ${level_start} ${level_end} ${latStart} ${lonStart} ${latEnde} ${lonEnde} "${name_osm}" "${data_dir}/osm_tiles"
cd ${data_dir}	
#mksquashfs seamap_tiles osm_tiles offline_tiles.squashfs -comp lz4
mksquashfs seamap_tiles osm_tiles offline_tiles.squashfs -comp lzo
echo "shutdown of docker containers necessary"
exit 0

# or mbtiles
# Openseamap mbtiles
cd ${data_dir}/seamap_tiles
python3 -m http.server 2> /dev/zero > /dev/zero &
docker run -v ${data_dir}/:/opt/app/data -e "APP_MODE=command" -e "TILESERVER_TYPE=osm" -e "TILESERVER_ENDPOINT=http://172.17.0.1:8000/{z}/{x}/{y}.png" -e "APP_TIMEOUT=3000" -e "APP_MINZOOM=9" -e "APP_MAXZOOM=18" -e "APP_MAXAREA=160000" mapsquare/mbtiles-generator-server /opt/app/app.sh --left=${lonStart} --bottom=${latEnde}  --top=${latStart} --right=${lonEnde}

# Openstreetmap mbtiles
docker run -v ${data_dir}/:/opt/app/data -e "APP_MODE=command" -e "TILESERVER_TYPE=osm" -e "TILESERVER_ENDPOINT=http://172.17.0.1:8008/hot/{z}/{x}/{y}.png" -e "APP_TIMEOUT=3000" -e "APP_MINZOOM=2" -e "APP_MAXZOOM=19" -e "APP_MAXAREA=160000" mapsquare/mbtiles-generator-server /opt/app/app.sh --left=${lonStart} --bottom=${latEnde}--top=${latStart} --right=${lonEnde}



