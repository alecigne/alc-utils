import importlib.util
import io
import os
import tempfile
import unittest
from contextlib import contextmanager, redirect_stderr, redirect_stdout
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("keep-only.py")
SPEC = importlib.util.spec_from_file_location("keep_only", MODULE_PATH)
keep_only_module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(keep_only_module)


@contextmanager
def working_directory(path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)


class TestKeepOnly(unittest.TestCase):
    def test_deletes_files_that_are_not_specified(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            keep = root / "keep.txt"
            delete = root / "delete.txt"
            nested_keep = root / "nested" / "keep.md"
            nested_delete = root / "nested" / "delete.md"
            orphan = root / "orphan" / "old.txt"

            nested_keep.parent.mkdir()
            orphan.parent.mkdir()
            keep.write_text("keep")
            delete.write_text("delete")
            nested_keep.write_text("nested keep")
            nested_delete.write_text("nested delete")
            orphan.write_text("orphan")

            deleted = keep_only_module.keep_only(root, ["keep.txt", "nested/keep.md"])

            self.assertEqual(
                {path.relative_to(root) for path in deleted},
                {Path("delete.txt"), Path("nested/delete.md"), Path("orphan/old.txt")},
            )
            self.assertTrue(keep.exists())
            self.assertTrue(nested_keep.exists())
            self.assertFalse(delete.exists())
            self.assertFalse(nested_delete.exists())
            self.assertFalse(orphan.parent.exists())

    def test_dry_run_reports_deletions_without_deleting(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            keep = root / "keep.txt"
            delete = root / "delete.txt"
            keep.write_text("keep")
            delete.write_text("delete")

            deleted = keep_only_module.keep_only(root, ["keep.txt"], dry_run=True)

            self.assertEqual([path.relative_to(root) for path in deleted], [Path("delete.txt")])
            self.assertTrue(keep.exists())
            self.assertTrue(delete.exists())

    def test_missing_keep_path_stops_before_deleting_anything(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            delete = root / "delete.txt"
            delete.write_text("delete")

            with self.assertRaises(keep_only_module.KeepOnlyError):
                keep_only_module.keep_only(root, ["missing.txt"])

            self.assertTrue(delete.exists())

    def test_refuses_keep_path_outside_root(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            root = base / "root"
            outside = base / "outside.txt"
            inside = root / "inside.txt"
            root.mkdir()
            outside.write_text("outside")
            inside.write_text("inside")

            with self.assertRaises(keep_only_module.KeepOnlyError):
                keep_only_module.keep_only(root, ["../outside.txt"])

            self.assertTrue(inside.exists())
            self.assertTrue(outside.exists())

    def test_keeps_symlink_named_in_keep_paths(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            root = base / "root"
            outside = base / "outside.txt"
            symlink = root / "linked.txt"
            delete = root / "delete.txt"
            root.mkdir()
            outside.write_text("outside")
            symlink.symlink_to(outside)
            delete.write_text("delete")

            deleted = keep_only_module.keep_only(root, ["linked.txt"])

            self.assertEqual([path.relative_to(root) for path in deleted], [Path("delete.txt")])
            self.assertTrue(symlink.is_symlink())
            self.assertEqual(symlink.read_text(), "outside")
            self.assertTrue(outside.exists())
            self.assertFalse(delete.exists())

    def test_deletes_unkept_symlink_without_deleting_target(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            root = base / "root"
            outside = base / "outside.txt"
            keep = root / "keep.txt"
            symlink = root / "linked.txt"
            root.mkdir()
            outside.write_text("outside")
            keep.write_text("keep")
            symlink.symlink_to(outside)

            deleted = keep_only_module.keep_only(root, ["keep.txt"])

            self.assertEqual([path.relative_to(root) for path in deleted], [Path("linked.txt")])
            self.assertFalse(symlink.exists())
            self.assertFalse(symlink.is_symlink())
            self.assertTrue(outside.exists())
            self.assertTrue(keep.exists())

    def test_accepts_absolute_keep_path_inside_root(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            keep = root / "keep.txt"
            delete = root / "delete.txt"
            keep.write_text("keep")
            delete.write_text("delete")

            deleted = keep_only_module.keep_only(root, [str(keep)])

            self.assertEqual([path.relative_to(root) for path in deleted], [Path("delete.txt")])
            self.assertTrue(keep.exists())
            self.assertFalse(delete.exists())

    def test_keep_empty_dirs_preserves_empty_directories(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            keep = root / "keep.txt"
            empty = root / "empty"
            orphan = root / "orphan"
            keep.write_text("keep")
            empty.mkdir()
            orphan.mkdir()
            (orphan / "delete.txt").write_text("delete")

            keep_only_module.keep_only(root, ["keep.txt"], keep_empty_dirs=True)

            self.assertTrue(empty.exists())
            self.assertTrue(orphan.exists())
            self.assertFalse((orphan / "delete.txt").exists())

    def test_directory_keep_path_stops_before_deleting_anything(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            keep_directory = root / "keep-dir"
            delete = root / "delete.txt"
            keep_directory.mkdir()
            delete.write_text("delete")

            with self.assertRaises(keep_only_module.KeepOnlyError):
                keep_only_module.keep_only(root, ["keep-dir"])

            self.assertTrue(keep_directory.exists())
            self.assertTrue(delete.exists())

    def test_cli_dry_run_succeeds(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            (root / "keep.txt").write_text("keep")
            (root / "delete.txt").write_text("delete")

            with redirect_stdout(io.StringIO()):
                exit_code = keep_only_module.main(["--root", str(root), "--dry-run", "keep.txt"])

            self.assertEqual(exit_code, 0)
            self.assertTrue((root / "delete.txt").exists())

    def test_cli_error_returns_one_and_writes_to_stderr(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            delete = root / "delete.txt"
            delete.write_text("delete")
            stderr = io.StringIO()

            with redirect_stderr(stderr):
                exit_code = keep_only_module.main(["--root", str(root), "missing.txt"])

            self.assertEqual(exit_code, 1)
            self.assertIn("Keep path does not exist", stderr.getvalue())
            self.assertTrue(delete.exists())

    def test_cli_defaults_to_current_directory(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            keep = root / "keep.txt"
            delete = root / "delete.txt"
            keep.write_text("keep")
            delete.write_text("delete")

            with working_directory(root), redirect_stdout(io.StringIO()):
                exit_code = keep_only_module.main(["keep.txt"])

            self.assertEqual(exit_code, 0)
            self.assertTrue(keep.exists())
            self.assertFalse(delete.exists())


if __name__ == "__main__":
    unittest.main()
