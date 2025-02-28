#!/usr/bin/env python3

import os
import sys
from urllib.parse import urlparse

import requests

WALLHAVEN_API_URL = "https://wallhaven.cc/api/v1/search?q=id%3A37&sorting=random&order=desc&categories=100&purity=100&atleast=1920x1080&ratios=16x9"
WALLPAPER_DIR = os.path.expanduser("~/.wallpapers")
SYMLINK_PATH = os.path.join(WALLPAPER_DIR, "current")


def fetch_wallpaper_url():
    """Fetches the first wallpaper URL from Wallhaven API."""
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
    """Downloads the wallpaper and saves it with its original filename."""
    if not os.path.exists(WALLPAPER_DIR):
        os.makedirs(WALLPAPER_DIR)
    filename = os.path.basename(urlparse(url).path)
    wallpaper_path = os.path.join(WALLPAPER_DIR, filename)
    try:
        response = requests.get(url, stream=True, timeout=10)
        response.raise_for_status()
        with open(wallpaper_path, "wb") as file:
            for chunk in response.iter_content(1024):
                file.write(chunk)
        return wallpaper_path
    except requests.exceptions.RequestException as e:
        print(f"Error downloading wallpaper: {e}", file=sys.stderr)
        return None


def update_symlink(image_path):
    """Creates or updates a symlink to always point to the latest wallpaper."""
    if os.path.exists(SYMLINK_PATH) or os.path.islink(SYMLINK_PATH):
        os.remove(SYMLINK_PATH)
    os.symlink(image_path, SYMLINK_PATH)
    print(f"Symlink updated: {SYMLINK_PATH} -> {image_path}")


def set_wallpaper():
    """Sets the wallpaper using the symlink."""
    os.system(f"feh --bg-scale {SYMLINK_PATH}")


def main():
    """Main function to fetch, download, create symlink, and set wallpaper."""
    wallpaper_url = fetch_wallpaper_url()

    if wallpaper_url:
        print(f"Downloading wallpaper: {wallpaper_url}")
        image_path = download_wallpaper(wallpaper_url)

        if image_path:
            update_symlink(image_path)
            print(f"Setting wallpaper using symlink: {SYMLINK_PATH}")
            set_wallpaper()
            print("Wallpaper updated successfully.")
        else:
            print("Failed to download wallpaper.", file=sys.stderr)
    else:
        print("Failed to retrieve wallpaper URL.", file=sys.stderr)


if __name__ == "__main__":
    main()
