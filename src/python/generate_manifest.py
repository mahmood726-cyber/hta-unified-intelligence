import os
import json
import hashlib
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "..", "..", "output")
MANIFEST_FILE = os.path.join(OUTPUT_DIR, "manifest.json")

def sha256_checksum(filename, block_size=65536):
    sha256 = hashlib.sha256()
    with open(filename, 'rb') as f:
        for block in iter(lambda: f.read(block_size), b''): sha256.update(block)
    return sha256.hexdigest()

def generate_manifest():
    manifest = {"timestamp": time.strftime("%Y-%m-%d %H:%M:%S"), "files": []}
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for file in files:
            if file == "manifest.json": continue
            filepath = os.path.join(root, file)
            relpath = os.path.relpath(filepath, OUTPUT_DIR)
            file_info = {"path": relpath, "size_bytes": os.path.getsize(filepath), "sha256": sha256_checksum(filepath)}
            manifest["files"].append(file_info)
    with open(MANIFEST_FILE, "w") as f: json.dump(manifest, f, indent=2)
    print(f"Manifest generated with {len(manifest['files'])} files verified.")

if __name__ == "__main__":
    if os.path.exists(OUTPUT_DIR): generate_manifest()
    else: print("Output directory not found.")
