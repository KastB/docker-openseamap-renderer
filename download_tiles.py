# not /usr/bin/perl
import math
import os
import sys

from multiprocessing.dummy import Pool

if len(sys.argv) != 9:
    print("usage: python3 download_tiles.py level_start level_end latStart lonStart latEnde lonEnde map_name base_dir")
    exit(1)
"""
level_start = 2
level_end = 19
latStart = 47.82
lonStart = 8.86
latEnde = 47.47
lonEnde = 9.8
name = "OpenSeaMapOfflineLakeConstance"
base_dir = "/data/osm/osm_tiles" # "/".join(__file__.split("/")[:-1])
"""
print(sys.argv)
level_start = int(sys.argv[1])
level_end = int(sys.argv[2])
latStart = float(sys.argv[3])
lonStart = float(sys.argv[4])
latEnd  = float(sys.argv[5])
lonEnd = float(sys.argv[6])
map_name = sys.argv[7]
base_dir = sys.argv[8]


def deg2num(lat_deg, lon_deg, zoom):
    lat_rad = math.radians(lat_deg)
    n = 2.0 ** zoom
    xtile = int((lon_deg + 180.0) / 360.0 * n)
    ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
    return xtile, ytile


def num2deg(xtile, ytile, zoom):
    n = 2.0 ** zoom
    lon_deg = xtile / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
    lat_deg = math.degrees(lat_rad)
    return lat_deg, lon_deg


def retrieve(dat):
    import urllib.request
    (urlOSM, x, y, z) = dat
    out_file = '{}/{}/{}/{}.png'.format(base_dir, z, x, y)
    if os.path.isfile(out_file):
        return False
    try:
        urllib.request.urlretrieve(urlOSM.format(z, x, y), out_file)
    except:
        return False
    return True


urlOSM = "http://localhost:8008/hot/{}/{}/{}.png"
try:
    os.mkdir("{}".format(base_dir))
except OSError:
    pass

with open("{}/metadata.json".format(base_dir), "w") as fp:
    lines = """{{
        "bounds": [
        {},
        {},
        {},
        {}
        ],
        "minzoom": {},
        "maxzoom": {},
        "name": "{}",
        "description": "{}",
        "format": "png"
    }}""".format(lonStart, latEnd, lonEnd, latStart, level_start, level_end, map_name, map_name)

    fp.writelines(lines)
data = list()
for z in range(level_start, level_end + 1):
    try:
        os.mkdir("{}/{}".format(base_dir, z))
    except OSError:
        pass
    xstart, ystart = deg2num(latStart, lonStart, z)
    xende, yende = deg2num(latEnd, lonEnd, z)
    if xstart > 0:
        xstart -= 1
    if ystart > 0:
        ystart -= 1
    yende = yende + 1
    xende = xende + 1

    # Status anzeigen
    print("Level: {}".format(z))
    print("Anzahl x: {}".format(xende - xstart))
    print("Anzahl y: {}".format(yende - ystart))

    # Hauptschleife
    for x in range(xstart, xende):
        try:
            os.mkdir("{}/{}/{}".format(base_dir, z, x))
        except OSError:
            pass
        for y in range(ystart, yende):
            data.append((urlOSM, x, y, z))

p = Pool(processes=8)
while True:
	print("new_loop")
	ret = p.map(retrieve, data)
	if True not in ret:
		break
p.close()
