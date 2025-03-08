#!/usr/bin/env python3

import datetime
import os
import sys
from pathlib import Path
from urllib.parse import urlparse

import requests

WALLHAVEN_API_URL = "https://wallhaven.cc/api/v1/search?q=id%3A37&sorting=random&order=desc&categories=100&purity=100&atleast=1920x1080&ratios=16x9"
TMP_DIR = "/tmp"
WALLPAPER_DIR = os.path.expanduser("~/.wallpapers/download")
SYMLINK_PATH = os.path.join(os.path.dirname(WALLPAPER_DIR), "current")


def fetch_wallpaper_url():
    """Fetch a wallpaper URL from the Wallhaven API."""
    try:
        response = requests.get(WALLHAVEN_API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        if "data" in data and len(data["data"]) > 0:
            return data["data"][0]["path"]
        else:
            print("No wallpapers found in response.", file=sys.stderr)
            return None
    except requests.exceptions.RequestException as e:
        print(f"Error fetching wallpaper: {e}", file=sys.stderr)
        return None


def download_wallpaper(url):
    """Download the wallpaper to the temporary location, replacing any previous file."""
    download_time = datetime.datetime.now()
    filename = generate_filename(url, download_time)
    tmp_path = os.path.join(TMP_DIR, filename)

    try:
        response = requests.get(url, stream=True, timeout=10)
        response.raise_for_status()
        clean_tmp_dir()
        with open(tmp_path, "wb") as file:
            for chunk in response.iter_content(1024):
                file.write(chunk)
        print(f"Downloaded wallpaper for preview: {tmp_path}")
        return tmp_path
    except requests.exceptions.RequestException as e:
        print(f"Error downloading wallpaper: {e}", file=sys.stderr)
        return None


def generate_filename(url, download_time: datetime):
    """Generate a filename from a wallpaper URL and a download time."""
    timestamp = download_time.strftime("%Y-%m-%dT%H:%M:%S")
    original_filename = os.path.basename(urlparse(url).path)
    return f"{timestamp}-{original_filename}"


def clean_tmp_dir():
    """Remove all wallpapers from the temporary location."""
    for file in Path(TMP_DIR).glob("*-wallhaven-*"):
        file.unlink()


def update_symlink(image_path):
    """Create or update a symlink to always point to the latest wallpaper."""
    if os.path.exists(SYMLINK_PATH) or os.path.islink(SYMLINK_PATH):
        os.remove(SYMLINK_PATH)
    os.symlink(image_path, SYMLINK_PATH)
    print(f"Symlink updated: {SYMLINK_PATH} -> {image_path}")


def set_wallpaper(wallpaper_path):
    """Set the wallpaper."""
    os.system(f"feh --bg-scale {wallpaper_path}")


def main():
    """TODO"""
    wallpaper_url = fetch_wallpaper_url()
    print(f"Wallpaper URL fetched: {wallpaper_url}")
    if wallpaper_url:
        image_path = download_wallpaper(wallpaper_url)
        print(f"Wallpaper downloaded: {image_path}")
        if image_path:
            set_wallpaper(image_path)
            print("Wallpaper updated successfully.")
        else:
            print("Failed to download wallpaper.", file=sys.stderr)
    else:
        print("Failed to retrieve wallpaper URL.", file=sys.stderr)


if __name__ == "__main__":
    main()
