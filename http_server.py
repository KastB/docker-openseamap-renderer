import os
import argparse
from http.server import SimpleHTTPRequestHandler, HTTPServer

class CustomHandler(SimpleHTTPRequestHandler):
    # Class variable to cache the empty.png content
    empty_png_data = None

    def send_error(self, code, message=None):
        if code == 404:
            # Serve the cached empty.png content when a 404 error occurs
            self.send_response(200)
            self.send_header('Content-type', 'image/png')
            self.end_headers()
            self.wfile.write(self.empty_png_data)
        else:
            # Handle other errors as usual
            super().send_error(code, message)

if __name__ == '__main__':
    # Set up command-line argument parsing
    parser = argparse.ArgumentParser(description="Simple HTTP Server with a fallback file")
    parser.add_argument('--directory', required=True, help='The directory to serve files from')
    parser.add_argument('--port', type=int, default=8000, help='The port to serve on (default: 8000)')
    
    args = parser.parse_args()

    # Cache the content of empty.png from the script's directory
    script_dir = os.path.dirname(os.path.realpath(__file__))
    empty_png_path = os.path.join(script_dir, 'empty.png')
    with open(empty_png_path, 'rb') as file:
        CustomHandler.empty_png_data = file.read()

    # Change directory to the specified directory
    data_dir = args.directory
    os.chdir(data_dir)

    # Create and start the server
    server_address = ('', args.port)
    httpd = HTTPServer(server_address, CustomHandler)
    print(f"Serving on port {args.port} from directory {data_dir}...")
    httpd.serve_forever()
