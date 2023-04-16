import glob
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
import shutil
import subprocess
import threading
import time

FILE_PATTERN = "/tmp/*.metrics"
COPY_INTERVAL = 5  # seconds
COPY_PATH = "/tmp/final"
SCRIPT_PATTERN = "/app/scripts/*.sh"
SCRIPT_INTERVAL = 30  # seconds
SCRIPT_TIMEOUT = 30  # seconds

def copy_files():
    while True:
        with open(COPY_PATH, "wb") as outfile:
            for f in glob.glob(FILE_PATTERN):
                with open(f, "rb") as infile:
                    shutil.copyfileobj(infile, outfile)
        time.sleep(COPY_INTERVAL)

def execute_scripts():
    while True:
        for script in glob.glob(SCRIPT_PATTERN):
            try:
                output = subprocess.check_output(
                    ["bash", script], stderr=subprocess.STDOUT, timeout=SCRIPT_TIMEOUT
                )
                print(f"Script {script} executed successfully:\n{output.decode()}")
            except subprocess.TimeoutExpired as e:
                print(f"Script {script} timed out after {SCRIPT_TIMEOUT} seconds:\n{e.output.decode()}")
            except subprocess.CalledProcessError as e:
                print(f"Script {script} failed with exit code {e.returncode}:\n{e.output.decode()}")
        time.sleep(SCRIPT_INTERVAL)

class FileHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        with open(COPY_PATH, "rb") as f:
            self.wfile.write(f.read())

if __name__ == "__main__":
    copy_thread = threading.Thread(target=copy_files)
    copy_thread.start()

    script_thread = threading.Thread(target=execute_scripts)
    script_thread.start()

    server_address = ("0.0.0.0", 9010)
    httpd = HTTPServer(server_address, FileHandler)
    httpd.serve_forever()
