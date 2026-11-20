"""Windows source-ZIP delivery must fail closed on missing or stale DLLs."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import struct
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('windows_core', ROOT / 'scripts/windows-core.py')
core = importlib.util.module_from_spec(spec)
spec.loader.exec_module(core)

class WindowsCorePackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        names = [*core.INPUTS, core.MANIFEST, 'scripts/setup-godot.sh',
                 'licenses/godot-cpp-LICENSE.md', 'licenses/Godot-LICENSE.txt',
                 *(core.library(target) for target in core.TARGETS)]
        for name in names:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, path)

    def test_exact_dlls_and_safe_extract_layout(self):
        output = self.root / 'repair.zip'
        with contextlib.redirect_stdout(io.StringIO()): core.package(self.root, output)
        core.verify_archive(self.root, output)
        with zipfile.ZipFile(output) as archive:
            expected = {'bin/' + Path(core.library(target)).name for target in core.TARGETS}
            self.assertEqual(set(archive.namelist()), expected | {'bin/windows-core.json', 'WINDOWS-CORE-START-HERE.txt', 'licenses/godot-cpp-LICENSE.md', 'licenses/Godot-LICENSE.txt'})
            for target in core.TARGETS:
                path = core.library(target)
                self.assertEqual(archive.read('bin/' + Path(path).name), (ROOT / path).read_bytes())
            self.assertIn(b'project.godot', archive.read('WINDOWS-CORE-START-HERE.txt'))

    def test_stale_repair_download_is_detected(self):
        output = self.root / 'repair.zip'
        with contextlib.redirect_stdout(io.StringIO()): core.package(self.root, output)
        # A rebuilt source/DLL pair is valid on disk but its old download isn't.
        path = self.root / core.library('template_debug')
        path.write_bytes(path.read_bytes() + b'new-build')
        record = self.root / core.MANIFEST
        manifest = json.loads(record.read_text())
        manifest['libraries']['template_debug']['sha256'] = core.sha(path)
        record.write_text(json.dumps(manifest))
        core.verify(self.root)
        with self.assertRaisesRegex(ValueError, 'Repair ZIP is stale'): core.verify_archive(self.root, output)

    def test_release_library_cannot_replace_missing_editor_library(self):
        (self.root / core.library('template_debug')).unlink()
        with self.assertRaisesRegex(ValueError, 'Missing .*template_debug'): core.verify(self.root)

    def test_changed_compiled_input_prevents_packaging(self):
        path = self.root / 'core/fight.cpp'
        path.write_bytes(path.read_bytes() + b'\n// new combat change\n')
        output = self.root / 'repair.zip'
        with self.assertRaisesRegex(ValueError, 'stale'): core.package(self.root, output)
        self.assertFalse(output.exists())

    def test_dll_tampering_is_detected(self):
        path = self.root / core.library('template_debug')
        path.write_bytes(path.read_bytes() + b'changed')
        with self.assertRaisesRegex(ValueError, 'does not match'): core.verify(self.root)

    def test_wrong_architecture_is_detected(self):
        path = self.root / core.library('template_debug')
        data = bytearray(path.read_bytes())
        offset = struct.unpack_from('<I', data, 0x3c)[0]
        struct.pack_into('<H', data, offset+4, 0x014c)
        path.write_bytes(data)
        with self.assertRaisesRegex(ValueError, 'not a Windows x86-64'): core.verify(self.root)

    def test_wrong_core_version_is_detected(self):
        path = self.root / core.MANIFEST
        manifest = json.loads(path.read_text())
        manifest['libraries']['template_debug']['coreVersion'] -= 1
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, 'stale'): core.verify(self.root)

if __name__ == '__main__': unittest.main()
