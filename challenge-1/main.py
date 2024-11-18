"""
Note: the HTTPserver docs are saying it's not secure and should not be used in production
"""
import http.server
import socketserver
import argparse

class HelloWorldHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        # the message
        message = "Hello world!"
        # sonnet says it should be like that, it means he knows what he's doing :D as opposed to me, no time for docs of that thing
        self.wfile.write(bytes(message, "utf8"))
        return

def start_server(port):
    try:
        with socketserver.TCPServer(("", port), HelloWorldHandler) as httpd:
            print(f"Server started at port {port}")
            httpd.serve_forever()
    except OSError as e:
        print(f"Error: Could not start server on port {port}")
        print(f"Error message: {e}")
    except KeyboardInterrupt:
        print("\nServer stopped by user")

def main():
    parser = argparse.ArgumentParser(description='Start a simple HTTP server')
    parser.add_argument('-p', '--port', 
                        type=int, 
                        default=8000,
                        help='Port to run the server on (default: 8000)')

    args = parser.parse_args()
    
    start_server(args.port)

if __name__ == "__main__":
    main()