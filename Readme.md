# OSM and OpenSeamap Offline Rendering Pipeline
There are dozens of methods to render offline tiles.
With this repo you just specify the parameters of the bbox you want to get rendered and the desired zoom levels and all tiles for OSM and seamap are generated.

From my experience, there is mostly outdated documentation and a huge setup burden before getting started with other tools and pipelines.
For openseamap support is even worse.

This repo tries to ease offline tile generation, especially for regions without prerendered packages.

This repo has DockerFiles for both, an offline OpenStreetMap rendering pipeline as well as an OpenSeamap tile rendering docker.
The "update_maps.sh" script can be configured to download a bbox from osm via the overpass api, build the containers, and render the tiles.
The resulting folders contain a manifest.json, such that the charts-plugin from signalk can provide the charts offline.

Alternatively you can comment out the lines to generate mbtiles.

# Usage

Adapt the parameters in "update_maps.sh" and execute it (tested with ubuntu 16.04).
You need docker, bzip2 and optionally squashfs.

The squashing is my method to have a single file and (hopefully) better performance compared to mbtiles/sqlite


# OpenSeaMap
This dockerfile creates a container with the openseamap rendering

This Repo can be used to compose to a kap also (other repo).

Usage:
docker build -t openseamap_renderer .

with a data.osm.bz2 file in /data/osm:
docker run -v /data/osm/seamap:/home/renderaccount/overpass_db  -v /data/osm:/data openseamap_renderer

Also have a look at:
https://github.com/KastB/openseamap_kap	

# Dockerfile for an OpenStreetMap Tile Server

This Dockerfile creates an OSM tile server based on the instructions from https://switch2osm.org/manually-building-a-tile-server-16-04-2-lts/.
Originally from https://github.com/rooch84/docker-osm-tile-server.git

## Building

```
git clone https://github.com/KastB/docker-osm-tile-server.git
cd docker-osm-tile-server
docker build -t osm .
```

## Running

To run the newly built container (and access the tile server from port 8008 for example), just run:

`docker run -p 8008:80 -v /data/:/data -e DATA="/data/osm/data.osm.bz2" osm`
 


Assuming the container is running locally, you can then test it works by pointing your browser at (you should see a single tile):

http://localhost:8008/hot/14/8595/5710.png

Make sure, that you adapt the filename of your *osm.bz2 and the folder it is sitting in (~/data)

