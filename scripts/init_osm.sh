/etc/init.d/postgresql start
service apache2 start
echo -n "Waiting for postgres to start."
until `pg_isready -q`; do
  echo -n "."  
  sleep 1
done

echo -n "Filling Database"
echo $DATA
file=$(echo "$DATA" | sed "s/.*\///")
echo $file
chmod 777 $DATA

su - renderaccount -c "cd ~/src/openstreetmap-carto/ && ./scripts/get-external-data.py"
su renderaccount -c "osm2pgsql -d gis \
--create --slim  -G --hstore --tag-transform-script \
~/src/openstreetmap-carto/openstreetmap-carto.lua \
-C 4000  --number-processes 4 \
-S ~/src/openstreetmap-carto/openstreetmap-carto.style \
$DATA"

su - renderaccount -c "renderd -f -c /usr/local/etc/renderd.conf"
