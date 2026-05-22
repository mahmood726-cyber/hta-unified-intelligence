import os
import sys

import requests

ASSET_URLS = {
    "jquery.min.js": "https://code.jquery.com/jquery-3.6.0.min.js",
    "jquery.dataTables.min.js": "https://cdn.datatables.net/1.11.5/js/jquery.dataTables.min.js",
    "jquery.dataTables.min.css": "https://cdn.datatables.net/1.11.5/css/jquery.dataTables.min.css",
    "dataTables.buttons.min.js": "https://cdn.datatables.net/buttons/2.2.2/js/dataTables.buttons.min.js",
    "buttons.dataTables.min.css": "https://cdn.datatables.net/buttons/2.2.2/css/buttons.dataTables.min.css",
    "jszip.min.js": "https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js",
    "pdfmake.min.js": "https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/pdfmake.min.js",
    "vfs_fonts.js": "https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/vfs_fonts.js",
    "buttons.html5.min.js": "https://cdn.datatables.net/buttons/2.2.2/js/buttons.html5.min.js",
    "mermaid.min.js": "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js",
    "chart.min.js": "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.7.0/chart.min.js",
    "dataTables.rowGroup.min.js": "https://cdn.datatables.net/rowgroup/1.1.4/js/dataTables.rowGroup.min.js",
    "rowGroup.dataTables.min.css": "https://cdn.datatables.net/rowgroup/1.1.4/css/rowGroup.dataTables.min.css",
}


def download(asset_dir=None, urls=None, timeout=30):
    asset_dir = asset_dir or os.path.join("output", "assets")
    urls = urls or ASSET_URLS
    os.makedirs(asset_dir, exist_ok=True)

    failures = []
    print(f"Downloading {len(urls)} assets to {asset_dir}...")
    for name, url in urls.items():
        try:
            response = requests.get(url, timeout=timeout)
            response.raise_for_status()
            with open(os.path.join(asset_dir, name), "wb") as f:
                f.write(response.content)
            print(f"OK   {name}")
        except Exception as e:
            failures.append(name)
            print(f"FAIL {name}: {e}")
    print("Offline assets updated.")
    return failures


if __name__ == "__main__":
    sys.exit(1 if download() else 0)
