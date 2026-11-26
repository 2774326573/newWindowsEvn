import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / 'config/yazi/plugins/devkit-office.yazi'
spec = importlib.util.spec_from_file_location('preview', PLUGIN / 'preview.py')
preview = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preview)


def odf(path, kind):
    body = {
        'text':'<office:text><text:p>Portable preview test</text:p></office:text>',
        'spreadsheet':'<office:spreadsheet><table:table table:name="Sheet1"><table:table-row><table:table-cell office:value-type="string"><text:p>Excel preview</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="42"><text:p>42</text:p></table:table-cell></table:table-row></table:table></office:spreadsheet>',
        'presentation':'<office:presentation><draw:page draw:name="Slide1"><draw:frame svg:x="1cm" svg:y="1cm" svg:width="15cm" svg:height="3cm"><draw:text-box><text:p>PowerPoint preview</text:p></draw:text-box></draw:frame></draw:page></office:presentation>',
    }[kind]
    namespaces = 'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"'
    mime = 'application/vnd.oasis.opendocument.' + kind
    with zipfile.ZipFile(path, 'w') as package:
        package.writestr('mimetype', mime)
        package.writestr('content.xml', '<?xml version="1.0"?><office:document-content ' + namespaces + ' office:version="1.2"><office:body>' + body + '</office:body></office:document-content>')
        package.writestr('META-INF/manifest.xml', '<?xml version="1.0"?><manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2"><manifest:file-entry manifest:full-path="/" manifest:media-type="' + mime + '"/><manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/></manifest:manifest>')


class PreviewTests(unittest.TestCase):
    def test_rejects_missing_file(self):
        with self.assertRaises(ValueError):
            preview.render('does-not-exist.xlsx', 'output.jpg', 1, {})

    def test_rejects_unknown_format(self):
        with tempfile.TemporaryDirectory() as temp:
            file = Path(temp) / 'program.exe'
            file.write_bytes(b'not a document')
            with self.assertRaises(ValueError):
                preview.render(file, Path(temp) / 'out.jpg', 1, {})

    def test_timeout_terminates_child(self):
        with self.assertRaises(subprocess.TimeoutExpired):
            preview.run([sys.executable, '-c', 'import time; time.sleep(10)'], timeout=0.1)
        self.assertIsNone(preview.ACTIVE)

    @unittest.skipUnless(os.environ.get('DEVKIT_INTEGRATION') == '1', 'Set DEVKIT_INTEGRATION=1 with LibreOffice/Poppler installed')
    def test_office_and_pdf_real_conversion(self):
        runtime_file = os.environ.get('DEVKIT_RUNTIME')
        runtime = json.loads(Path(runtime_file).read_text()) if runtime_file else {'soffice':shutil.which('soffice'), 'pdftoppm':shutil.which('pdftoppm')}
        self.assertTrue(runtime.get('soffice'))
        self.assertTrue(runtime.get('pdftoppm'))
        with tempfile.TemporaryDirectory(prefix='devkit test space ') as temp:
            temp = Path(temp)
            profile = (temp / 'export-profile').as_uri()
            for kind, extension, export in [('text','odt','docx'), ('spreadsheet','ods','xlsx'), ('presentation','odp','pptx')]:
                source = temp / ('test document.' + extension)
                odf(source, kind)
                preview.run([runtime['soffice'], '-env:UserInstallation=' + profile, '--headless', '--convert-to', export, '--outdir', temp, source])
                document = source.with_suffix('.' + export)
                self.assertTrue(document.is_file(), str(document))
                image = temp / (export + '.jpg')
                self.assertIsNone(preview.render(document, image, 1, runtime))
                self.assertEqual(image.read_bytes()[:2], b'\xff\xd8')
            source = temp / 'test document.odt'
            preview.run([runtime['soffice'], '-env:UserInstallation=' + profile, '--headless', '--convert-to', 'pdf', '--outdir', temp, source])
            pdf = source.with_suffix('.pdf')
            self.assertIsNone(preview.render(pdf, temp / 'pdf.jpg', 1, runtime))
            self.assertEqual(preview.render(pdf, temp / 'end.jpg', 9999, runtime), 1)
            # Exercise the deployed helper CLI, including Windows process-job isolation.
            helper = temp / 'preview.py'
            shutil.copyfile(PLUGIN / 'preview.py', helper)
            (temp / 'runtime.json').write_text(json.dumps(runtime))
            result = subprocess.run([sys.executable, str(helper), str(pdf), str(temp / 'cli.jpg'), '1'], capture_output=True, text=True, timeout=45)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((temp / 'cli.jpg').read_bytes()[:2], b'\xff\xd8')


if __name__ == '__main__':
    unittest.main()
