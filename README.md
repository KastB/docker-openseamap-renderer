# Dockerfile for an OpenStreetMap Tile Server

This Dockerfile creates an OSM tile server based on the instructions from https://switch2osm.org/manually-building-a-tile-server-16-04-2-lts/.
Originally from https://github.com/rooch84/docker-osm-tile-server.git

## Building

```
git clone https://github.com/KastB/docker-osm-tile-server.git
cd docker-osm-tile-server
docker build -t osm:bodensee .
```

## Running

To run the newly built container (and access the tile server from port 8008 for example), just run:

`docker run -p 8008:80 -v /data/:/data -e DATA="/data/osm/data.osm.bz2" osm:bodensee`
 


Assuming the container is running locally, you can then test it works by pointing your browser at (you should see a single tile):

http://localhost:8008/hot/14/8595/5710.png

Make sure, that you adapt the filename of your *osm.bz2 and the folder it is sitting in (~/data)

