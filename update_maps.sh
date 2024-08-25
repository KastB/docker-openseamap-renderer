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
    osmconvert ${data_dir}/data.osm -o=${data_dir}/data2.osm.pbf
    osmium merge-changes -s   ${data_dir}/data2.osm.pbf -o  ${data_dir}/data.osm.pbf
    rm "${data_dir}/data.osm"
fi

name_osm="OpenSeaMapOfflineLakeConstance"
name_seamap="OpenSeaMapOfflineLakeConstance"

# cleanup / build
# docker system prune -a -y
#docker build -t seamap_renderer -f DockerfileSeamapRenderer .
#docker build -t osm_renderer -f DockerfileOSMRenderer .


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
     -rm \
    -p 8008:80 \
    -v ${data_dir}/osm_data:/data/database/ \
     --name osm_renderer \
    -d overv/openstreetmap-tile-server \
    run
# old command
# docker run --entrypoint=/bin/bash --rm --name  osm_renderer -p 8008:80 -v ${data_dir}/:/data -e DATA="/data/data.osm.bz2" osm_renderer /bin/init.sh &

# OpenSeamap rendering
docker run --rm  --name seamap_renderer -v ${data_dir}:/data seamap_renderer &


# Message to display
message="starting up the server takes ages. During this process, there is a download, decompressing, and several 'import complete' messages. Wait till all servers are up, check localhost:8008 for connection, and only then make your choice: 'm' for mbtiles 's' for squashfs"

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

if [ "$choice" = "s"   ]; then
	echo "Start rendering"
	# https://hub.docker.com/r/overv/openstreetmap-tile-server/
	python3 download_tiles.py ${level_start} ${level_end} ${latStart} ${lonStart} ${latEnde} ${lonEnde} "${name_osm}" "${data_dir}/osm_tiles"
	cd ${data_dir}	
	#mksquashfs seamap_tiles osm_tiles offline_tiles.squashfs -comp lz4
	# Loop until a valid choice is made
	message="Is  all rendering is complete? Probably when you see two multiple messeges without any output in between - check for running java jtile.jar processes to be sure for the seamap renderer [y]"
	while true; do
		echo "$message"
		read -t 120 -p "Enter your choice: " choice
		if [[ "$choice" == "y" ]]; then
			break
		fi
	done
	mksquashfs seamap_tiles osm_tiles offline_tiles.squashfs -comp lzo
	echo "shutdown of docker containers necessary"
elif [ "$choice" = "m" ]; then
	# or mbtiles
	# Openseamap mbtiles
	python3 -m http.server --directory ${data_dir}/seamap_tiles 2> /dev/zero > /dev/zero &
	docker run -v ${data_dir}/:/opt/app/data -e "APP_MODE=command" -e "TILESERVER_TYPE=osm" -e "TILESERVER_ENDPOINT=http://172.17.0.1:8000/{z}/{x}/{y}.png" -e "APP_TIMEOUT=3000" -e "APP_MINZOOM=9" -e "APP_MAXZOOM=18" -e "APP_MAXAREA=160000" ghcr.io/kastb/docker-openseamap-renderer /opt/app/app.sh --left=${lonStart} --bottom=${latEnde}  --top=${latStart} --right=${lonEnde}

	# Openstreetmap mbtiles
	docker run -v ${data_dir}/:/opt/app/data -e "APP_MODE=command" -e "TILESERVER_TYPE=osm" -e "TILESERVER_ENDPOINT=http://172.17.0.1:8008/tiles/{z}/{x}/{y}.png" -e "APP_TIMEOUT=3000" -e "APP_MINZOOM=2" -e "APP_MAXZOOM=19" -e "APP_MAXAREA=160000" ghcr.io/kastb/docker-openseamap-renderer /opt/app/app.sh --left=${lonStart} --bottom=${latEnde} --top=${latStart} --right=${lonEnde}
else
	echo "Invalid choice"
fi

echo "stop docker containers? [y/n]"
read choice
if [ "$choice" != "y"   ]; then
	docker stop seamap_renderer
	docker stop osm_renderer
fi
