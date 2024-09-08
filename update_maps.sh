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


docker stop seamap_renderer
docker stop osm_renderer

level_start=2
level_end=19
latStart=47.82
lonStart=8.86
latEnde=47.47
lonEnde=9.8
data_dir=`pwd`"/data"
name_osm="OpenStreetMapOfflineLakeConstance"
name_seamap="OpenSeaMapOfflineLakeConstance"


# Prompt the user with a default answer
read -p "Do you want to rebuild the seamap_renderer container? [y/N] " rebuild_seamap
rebuild_seamap=${rebuild_seamap:-n}

# Rebuild the seamap_renderer container if the user said yes
if [[ $rebuild_seamap =~ ^[Yy]$ ]]; then
  echo "Rebuilding seamap_renderer container..."
  docker build -t seamap_renderer -f DockerfileSeamapRenderer .
else
  echo "Skipping seamap_renderer rebuild."
fi

# Prompt the user with a default answer for the second container
read -p "Do you want to rebuild the osm_renderer container? [y/N] " rebuild_osm
rebuild_osm=${rebuild_osm:-n}

# Rebuild the osm_renderer container if the user said yes
if [[ $rebuild_osm =~ ^[Yy]$ ]]; then
  echo "Rebuilding osm_renderer container..."
  docker build -t osm_renderer -f DockerfileOSMRenderer .
else
  echo "Skipping osm_renderer rebuild."
fi

# Message to display
message="Make your choice: 'm' for mbtiles 's' for squashfs. Afterwards there are two parallel processes: the OSM pipeline is startet and the download of the tiles begins. At the same time the seamap tiles are generated and packed as soon as the container is finished."

# Loop until a valid choice is made
while true; do
    echo "$message"
    read -t 120 -p "Enter your choice: " choice
    if [[ "$choice" == "s" || "$choice" == "m" ]]; then
        break
    else
        echo "Invalid choice. Please enter 'm' for mbtiles or 's' for squashfs."
    fi
done

file="${data_dir}/data.osm.bz2"
# Check if the folder exists and the file exists within that folder
if [ -d "$data_dir" ] && [ -e "$file" ]; then
    echo "File $file exists. Continuing..."
else
    # If folder or file doesn't exist, execute the commands
    echo "Folder or file does not exist. Downloading and preparing data..."
	mkdir -p ${data_dir}
    wget -O ${data_dir}/data.osm https://overpass-api.de/api/map?bbox=${lonStart},${latEnde},${lonEnde},${latStart}
    bzip2 -z -c ${data_dir}/data.osm > ${data_dir}/data.osm.bz2
    osmconvert ${data_dir}/data.osm -o=${data_dir}/data2.osm.pbf
    osmium merge-changes -s   ${data_dir}/data2.osm.pbf -o  ${data_dir}/data.osm.pbf
    rm ${data_dir}/data2.osm.pbf 
    rm "${data_dir}/data.osm"
fi

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

echo "Import OSM Data"
mkdir -p ${data_dir}/osm_data
docker run \
    -v ${data_dir}/data.osm.pbf:/data/region.osm.pbf \
    -v  ${data_dir}/osm_data:/data/database/ \
    overv/openstreetmap-tile-server \
    import
echo "Starting the OSM Server"
docker run \
     --rm \
    -p 8008:80 \
    -v ${data_dir}/osm_data:/data/database/ \
     --name osm_renderer \
    -d \
    overv/openstreetmap-tile-server \
    run

# OpenSeamap rendering
docker run --rm  -d --name seamap_renderer -v ${data_dir}:/data seamap_renderer 

while ! nc -z 127.0.0.1 8008; do
  echo "Waiting for the OSM server to be up..."
  sleep 30
done
echo "OSM Server is up!"

echo "Start rendering Openstreetmap"
sleep 60
python3 download_tiles.py ${level_start} ${level_end} ${latStart} ${lonStart} ${latEnde} ${lonEnde} "${name_osm}" "${data_dir}/osm_tiles"

while [ "$(docker ps -q -f name=seamap_renderer)" ]; do
  echo "Waiting for seamap_renderer container to finish... :"
  echo "$(date) - $(find ${data_dir}/seamap_work/tmp/ -name '*-12.osm' | wc -l) files remaining: ${data_dir}/seamap_work/tmp/"
  sleep 60
done
echo "seamap_renderer container has finished."

docker stop seamap_renderer > /dev/null 2>&1
docker stop osm_renderer > /dev/null 2>&1
echo "generating tiles is completed"

if [ "$choice" = "s"   ]; then
	echo "compressing"
	cd ${data_dir}
  rm offline_tiles.squashfs
	mksquashfs seamap_tiles osm_tiles offline_tiles.squashfs -comp lzo
fi

if [ "$choice" = "m" ]; then
	echo "generating mbtiles"
  rm ${data_dir}/osm.mbtiles
  rm ${data_dir}/seamap.mbtiles
	python3 generate_mbtiles.py --tiles_dir ${data_dir}/osm_tiles --mbtiles_path ${data_dir}/osm.mbtiles --name ${name_osm}  --description ${name_osm} --type baselayer
	python3 generate_mbtiles.py --tiles_dir ${data_dir}/seamap_tiles --mbtiles_path ${data_dir}/seamap.mbtiles --name ${name_seamap}  --description ${name_seamap} --type overlay
fi

echo "ALL DONE!"
