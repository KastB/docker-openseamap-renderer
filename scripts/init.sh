#!/bin/bash
DATA="/data/data.osm.bz2"
DB_DIR="/home/renderaccount/overpass_db/"
EXEC_DIR="/home/renderaccount/opt/overpass/"
# Node 5569415244 used in way 582303753 not found. => these messages are normal if you dont import the whole planet
# /home/renderaccount/opt/overpass/bin/init_osm3s.sh $DATA $DB_DIR $EXEC_DIR --meta
echo "bk: init done"
chmod 777 -R $DB_DIR 
/home/renderaccount/opt/overpass/bin/dispatcher --osm-base --meta &
sleep 1
cd  $DB_DIR 
#wget http://dev.overpass-api.de/releases/osm-3s_v0.7.56.7.tar.gz
#tar -zxvf osm-3s_v*.tar.gz
#cd osm-3s_v*
#./configure CXXFLAGS="-O2" --prefix=$EXEC_DIR
#make install

cd /home/renderaccount/src/renderer/work/

mkdir -p tmp cache tiles
echo "getworld"
echo "[timeout:3600];(rel['seamark:type'];>;way['seamark:type'];>;node['seamark:type'];);out meta;" | /home/renderaccount/opt/overpass/bin/osm3s_query --db-dir=/home/renderaccount/overpass_db/ > next.osm 2> errors.txt
echo "getworld - done"
cat errors.txt

touch world.osm
diff world.osm next.osm | grep id= | grep -v "<tag" > diffs
java -jar ../jsearch/jsearch.jar ./

#tilegen
echo "tilegen"
for file in $(ls tmp | grep "\.osm"); do
  tx=$(echo $file | cut -f 1 -d'-')
  ty=$(echo $file | cut -f 2 -d'-')
  z=$(echo $file | cut -f 3 -d'-')
  z=$(echo $z | cut -f 1 -d'.')
  if [ $z = 12 ]; then
	for k in {12..18}; do
	  ../searender/searender ../searender/symbols/symbols.defs $k >tmp/$tx-$ty-$k.svg <tmp/$file 2> /dev/zero
	done;
	fi
	../searender/searender ../searender/symbols/symbols.defs $z >tmp/$tx-$ty-$z.svg <tmp/$file 2> /dev/zero
	java -jar ../jtile/jtile.jar tmp/ tiles/ $z $tx $ty
	echo "$(date) rendering $z $tx $ty"
  rm tmp/$file  
done
echo "tilegen - done"


#tiler
echo "tiler"
for file in $(ls cache); do
	tile=$(echo $file | sed -e s?-?/?g)
	mkdir -p $(dirname $tile)
	mv -f cache/$file $tile
done

echo "tiler done"
cp -r /home/renderaccount/src/renderer/work/tiles /data
