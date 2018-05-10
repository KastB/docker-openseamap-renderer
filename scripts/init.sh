
DB_DIR="/home/renderaccount/overpass_db/"
EXEC_DIR="/home/renderaccount/opt/overpass/"
# Node 5569415244 used in way 582303753 not found. => these messages are normal if you dont import the whole planet
/home/renderaccount/opt/overpass/bin/init_osm3s.sh $DATA $DB_DIR $EXEC_DIR --meta

chmod 777 -R $DB_DIR 
sleep 1
/home/renderaccount/opt/overpass/bin/dispatcher --osm-base --meta &
cd  $DB_DIR 
chmod +x  osm3s_v0.7.54_osm_base
cd /home/renderaccount/src/renderer/work/
su renderaccount
/home/renderaccount/src/renderer/work/composed.sh 
cp -r /home/renderaccount/src/renderer/work/tiles /data
