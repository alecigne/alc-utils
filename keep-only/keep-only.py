#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


class KeepOnlyError(Exception):
    """Raised when keep-only cannot safely apply the requested operation."""


def path_under_root(path: Path, root: Path) -> Path:
    """Return a normalized path if it is inside root."""
    normalized_path = Path(os.path.normpath(path))
    normalized_root = Path(os.path.normpath(root))

    try:
        normalized_path.relative_to(normalized_root)
    except ValueError as error:
        raise KeepOnlyError(f"Refusing to keep path outside root: {path}") from error

    return normalized_path


def normalize_keep_path(root: Path, keep_path: str) -> Path:
    """Normalize and validate one path that should be kept."""
    raw_path = Path(keep_path)
    candidate = raw_path if raw_path.is_absolute() else root / raw_path
    candidate = path_under_root(candidate, root)

    try:
        candidate.lstat()
    except FileNotFoundError as error:
        raise KeepOnlyError(f"Keep path does not exist: {keep_path}") from error

    if candidate.is_dir() and not candidate.is_symlink():
        raise KeepOnlyError(f"Keep path is a directory, not a file: {keep_path}")

    return Path(os.path.normpath(candidate))


def discover_deletions(root: Path, keep_paths: set[Path]) -> list[Path]:
    """Find regular files and symlinks under root that are not in keep_paths."""
    deletions = []

    for path in root.rglob("*"):
        normalized_path = Path(os.path.normpath(path))
        if normalized_path in keep_paths:
            continue
        if path.is_symlink() or path.is_file():
            deletions.append(normalized_path)

    return sorted(deletions)


def remove_empty_dirs(root: Path) -> list[Path]:
    """Remove empty directories under root, deepest first."""
    removed = []
    directories = [path for path in root.rglob("*") if path.is_dir() and not path.is_symlink()]

    for directory in sorted(directories, key=lambda path: len(path.parts), reverse=True):
        try:
            directory.rmdir()
        except OSError:
            continue
        removed.append(Path(os.path.normpath(directory)))

    return removed


def keep_only(root: Path, keep_files: list[str], dry_run: bool = False, keep_empty_dirs: bool = False) -> list[Path]:
    """Delete files under root except the files named in keep_files."""
    root = Path(os.path.normpath(root)).resolve(strict=True)
    if not root.is_dir():
        raise KeepOnlyError(f"Root is not a directory: {root}")

    keep_paths = {normalize_keep_path(root, keep_file) for keep_file in keep_files}
    deletions = discover_deletions(root, keep_paths)

    if dry_run:
        return deletions

    for path in deletions:
        path.unlink()

    if not keep_empty_dirs:
        remove_empty_dirs(root)

    return deletions


def format_relative(path: Path, root: Path) -> str:
    """Format a path relative to root when possible."""
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Keep only the specified files under a directory and delete the other files."
    )
    parser.add_argument("files", nargs="+", help="Files to keep, relative to --root unless absolute")
    parser.add_argument("--root", default=".", type=Path, help="Directory to prune (default: current directory)")
    parser.add_argument("--dry-run", action="store_true", help="Print files that would be deleted without deleting them")
    parser.add_argument("--keep-empty-dirs", action="store_true", help="Do not remove directories left empty")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)

    try:
        root = args.root.resolve(strict=True)
        deletions = keep_only(
            root=root,
            keep_files=args.files,
            dry_run=args.dry_run,
            keep_empty_dirs=args.keep_empty_dirs,
        )
    except KeepOnlyError as error:
        print(f"keep-only: error: {error}", file=sys.stderr)
        return 1
    except FileNotFoundError:
        print(f"keep-only: error: Root does not exist: {args.root}", file=sys.stderr)
        return 1

    action = "Would delete" if args.dry_run else "Deleted"
    for path in deletions:
        print(f"{action}: {format_relative(path, root)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
