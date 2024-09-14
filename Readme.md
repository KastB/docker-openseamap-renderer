# OSM and OpenSeamap Offline Rendering Pipeline
With this repo you just specify the parameters of the bbox you want to get rendered and the desired zoom levels and all tiles for OSM and seamap are generated.

The "update_maps.sh" script can be configured to download a bbox from osm via the overpass api, build the containers render the tiles, and compress them in the configured dataformat
The resulting folders contain a manifest.json, such that the charts-plugin from signalk can provide the charts offline.

THERE IS A WARMSTART. AFTER CHANGING PARAMETERS DELETE THE DATA FOLDER!

# Usage

Adapt the parameters in "update_maps.sh" and execute it (tested with ubuntu 22.04).
You need python3 docker bzip2 osmctools osmium-tool squashfs.

The squashing is my method to have a single file and (hopefully) better performance compared to mbtiles/sqlite


## OpenSeaMap
This dockerfile creates a container for openseamap rendering. It does not serve the tiles, but renders them to a folder

Usage:
docker build -t openseamap_renderer .

with a data.osm.bz2 file in /data/osm:
docker run -v /data/osm/seamap:/home/renderaccount/overpass_db  -v /data/osm:/data openseamap_renderer

Also have a look at:
https://github.com/KastB/openseamap_kap	

## OpenStreetMap Tile Server

Another docker docker container serves the tiles, which are then downloaded with a python script

## Compression
Depending on your choice, the downloaded / rendered tiles are compressed in squashfs or in two mbtiles files.


