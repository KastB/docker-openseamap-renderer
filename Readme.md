This dockerfile creates a container with the openseamap rendering

This Repo can be used combined with the openstreetmap rendering container and the repository for tile retrieval and composition to kap.

Usage:
docker build -t openseamap .

with a data.osm.bz2 file in /data/osm:
docker run -v /data/osm/seamap:/home/renderaccount/overpass_db  -v /data/osm:/data openseamap

https://github.com/KastB/openseamap_kap	

https://github.com/KastB/docker-osm-tile-server
