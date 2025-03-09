#!/usr/bin/env python3

import argparse
import datetime
import os
import shutil
import sys
from pathlib import Path
from urllib.parse import urlparse

import requests

WALLHAVEN_API_URL = "https://wallhaven.cc/api/v1/search?q=id%3A37&sorting=random&order=desc&categories=100&purity=100&atleast=1920x1080&ratios=16x9"
TMP_DIR = Path("/tmp")
WALLPAPER_DIR = Path.home() / ".wallpapers/download"
SYMLINK_PATH = WALLPAPER_DIR.parent / "current"


# Previewing a wallpaper (--preview)

def fetch_wallpaper_url() -> str:
    """Fetch a wallpaper URL from the Wallhaven API."""
    try:
        response = requests.get(WALLHAVEN_API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        if "data" in data and len(data["data"]) > 0:
            wallpaper_url = data["data"][0]["path"]
            print(f"Wallpaper URL fetched: {wallpaper_url}")
            return wallpaper_url
        else:
            print("No wallpapers found in response.", file=sys.stderr)
            sys.exit(1)
    except requests.exceptions.RequestException as e:
        print(f"Error fetching wallpaper URL: {e}", file=sys.stderr)
        sys.exit(1)


def generate_filename(url: str, download_time: datetime.datetime):
    """Generate a filename from a wallpaper URL and a download time."""
    timestamp = download_time.strftime("%Y-%m-%dT%H:%M:%S")
    original_filename = Path(urlparse(url).path).name
    return f"{timestamp}-{original_filename}"


def clean_tmp_dir() -> None:
    """Remove all wallpapers from the temporary location."""
    for file in TMP_DIR.glob("*-wallhaven-*"):
        file.unlink()
    print("Temporary wallpapers cleaned.")


def download_wallpaper(url: str) -> Path:
    """Download the wallpaper to a temporary location, replacing any previous file."""
    download_time = datetime.datetime.now()
    filename = generate_filename(url, download_time)
    tmp_path = TMP_DIR / filename

    try:
        response = requests.get(url, stream=True, timeout=10)
        response.raise_for_status()
        clean_tmp_dir()
        with tmp_path.open("wb") as file:
            for chunk in response.iter_content(1024):
                file.write(chunk)
        print(f"Wallpaper downloaded to {tmp_path}")
        return tmp_path
    except requests.exceptions.RequestException as e:
        print(f"Error downloading wallpaper: {e}", file=sys.stderr)
        sys.exit(1)


def display_wallpaper(wallpaper_path: Path) -> None:
    """Display the wallpaper using feh, if available."""
    if shutil.which("feh") is None:
        print("Error: 'feh' is not installed. Cannot set wallpaper.", file=sys.stderr)
        sys.exit(1)
    os.system(f"feh --bg-scale {wallpaper_path}")
    print(f"Wallpaper {wallpaper_path} displayed.")


def preview_wallpaper() -> None:
    """Fetch a wallpaper URL, download the wallpaper to a temporary location, and display it."""
    wallpaper_url = fetch_wallpaper_url()
    image_path = download_wallpaper(wallpaper_url)
    display_wallpaper(image_path)
    print("Preview in place. Take a look :)")


# Stashing a wallpaper (--stash)

def stash_wallpaper() -> Path:
    """Stash the last previewed wallpaper to the wallpapers directory."""
    tmp_wallpapers = sorted(TMP_DIR.glob("*-wallhaven-*"), key=lambda f: f.stat().st_mtime, reverse=True)

    if not tmp_wallpapers:
        print("No wallpaper to stash. Use --preview first!", file=sys.stderr)
        sys.exit(1)

    latest_tmp_wallpaper = tmp_wallpapers[0]
    saved_path = WALLPAPER_DIR / latest_tmp_wallpaper.name
    WALLPAPER_DIR.mkdir(parents=True, exist_ok=True)
    shutil.move(str(latest_tmp_wallpaper), str(saved_path))
    print(f"Wallpaper stashed to {saved_path}")
    return saved_path


# Applying a wallpaper (--apply)

def update_symlink(image_path) -> None:
    """Create or update the wallpaper symlink to a given wallpaper path."""
    if SYMLINK_PATH.exists() or SYMLINK_PATH.is_symlink():
        SYMLINK_PATH.unlink()
    SYMLINK_PATH.symlink_to(image_path)
    print(f"Symlink updated: {SYMLINK_PATH} -> {image_path}")


def apply_wallpaper() -> None:
    """Stash the last previewed wallpaper, display it and update the wallpapers symlink."""
    saved_path = stash_wallpaper()
    display_wallpaper(saved_path)
    update_symlink(saved_path)
    print(f"Last previewed wallpaper saved to {saved_path} and applied! It is now current.")


# Restoring current wallpaper (--restore)

def restore_current() -> None:
    """Restore the currently selected wallpaper."""
    if not SYMLINK_PATH.exists():
        print("Error: no wallpaper is currently set.", file=sys.stderr)
        sys.exit(1)
    clean_tmp_dir()
    target_path = SYMLINK_PATH.resolve()
    display_wallpaper(target_path)
    print(f"Wallpaper {target_path} restored.")


# Main

def main() -> None:
    """Main function handling command-line arguments."""
    parser = argparse.ArgumentParser(description="Wallhaven wallpaper manager")
    parser.add_argument("--preview", action="store_true", help="Download and preview a new wallpaper")
    parser.add_argument("--stash", action="store_true", help="Save the last previewed wallpaper")
    parser.add_argument("--apply", action="store_true", help="Save wallpaper and set it as current")
    parser.add_argument("--restore", action="store_true", help="Restore the currently selected wallpaper")
    args = parser.parse_args()

    actions = {
        "preview": preview_wallpaper,
        "stash": stash_wallpaper,
        "apply": apply_wallpaper,
        "restore": restore_current,
    }

    action = next((key for key, value in vars(args).items() if value), None)

    if action in actions:
        actions[action]()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
