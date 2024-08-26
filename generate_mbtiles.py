import sqlite3
import os
import argparse

def create_mbtiles_file(mbtiles_path):
    conn = sqlite3.connect(mbtiles_path)
    cursor = conn.cursor()

    # Create tables
    cursor.execute("CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);")
    cursor.execute("CREATE TABLE metadata (name TEXT, value TEXT);")
    cursor.execute("CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row);")

    conn.commit()
    return conn, cursor

def insert_metadata(cursor, name, description, format='png', typ='baselayer'):
    metadata = [
        ('name', name),
        ('type', typ),
        ('version', '1.0'),
        ('description', description),
        ('format', format),
    ]

    cursor.executemany("INSERT INTO metadata (name, value) VALUES (?, ?);", metadata)

def insert_tile(cursor, z, x, y, tile_path):
    with open(tile_path, 'rb') as f:
        tile_data = f.read()
    cursor.execute(
        "INSERT INTO tiles (zoom_level, tile_column, tile_row, tile_data) VALUES (?, ?, ?, ?)",
        (z, x, (2**z - 1 - y), tile_data)
    )

def process_tiles(cursor, tiles_dir):
    for z in os.listdir(tiles_dir):
        z_dir = os.path.join(tiles_dir, z)
        if os.path.isdir(z_dir):
            for x in os.listdir(z_dir):
                x_dir = os.path.join(z_dir, x)
                if os.path.isdir(x_dir):
                    for y in os.listdir(x_dir):
                        y_tile = os.path.join(x_dir, y)
                        y_tile_name, ext = os.path.splitext(y)
                        if ext == '.png':
                            insert_tile(cursor, int(z), int(x), int(y_tile_name), y_tile)

def main(tiles_dir, mbtiles_path, name, description, typ):
    # Step 1: Create the MBTiles file
    conn, cursor = create_mbtiles_file(mbtiles_path)
    
    try:
        # Step 2: Insert metadata
        insert_metadata(cursor, name, description, typ)
        
        # Step 3: Insert tiles
        process_tiles(cursor, tiles_dir)
        
        # Commit and close
        conn.commit()
        print(f"MBTiles file created successfully at {mbtiles_path}")
    finally:
        conn.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Generate an MBTiles file from a directory of tiles.")
    parser.add_argument('--tiles_dir', required=True, help='Directory containing the tile files (structured as {z}/{x}/{y}.png).')
    parser.add_argument('--mbtiles_path', required=True, help='Path where the output MBTiles file will be created.')
    parser.add_argument('--name', required=True, help='Name of the map for the metadata.')
    parser.add_argument('--description', required=True, help='Description of the map for the metadata.')
    parser.add_argument('--type', required=True, help='Type of the layer (baselayer or overlay.')

    args = parser.parse_args()

    main(args.tiles_dir, args.mbtiles_path, args.name, args.description, args.type)
