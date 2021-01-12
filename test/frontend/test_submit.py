import unittest
import saliweb.test
import os
import re
from werkzeug.datastructures import FileStorage


# Import the ligscore frontend with mocks
ligscore = saliweb.test.import_mocked_frontend("ligscore", __file__,
                                               '../../frontend')


class Tests(saliweb.test.TestCase):
    """Check submit page"""

    def test_submit_page(self):
        """Test submit page"""
        incoming = saliweb.test.TempDir()
        ligscore.app.config['DIRECTORIES_INCOMING'] = incoming.tmpdir
        c = ligscore.app.test_client()
        rv = c.post('/job')
        self.assertEqual(rv.status_code, 400)  # no score type

        data = {'scoretype': 'Pose'}
        rv = c.post('/job', data=data)
        self.assertEqual(rv.status_code, 400)  # no pdb/mol2 files

        t = saliweb.test.TempDir()
        pdbf = os.path.join(t.tmpdir, 'test.pdb')
        molf = os.path.join(t.tmpdir, 'test.mol2')
        for fname in pdbf, molf:
            with open(fname, 'w') as fh:
                fh.write("mock")

        # Successful submission (no email)
        data['recfile'] = open(pdbf, 'rb')
        data['ligfile'] = open(molf, 'rb')
        rv = c.post('/job', data=data, follow_redirects=True)
        self.assertEqual(rv.status_code, 503)
        r = re.compile(b'Your job has been submitted.*results will be found',
                       re.MULTILINE | re.DOTALL)
        self.assertRegex(rv.data, r)

        # Successful submission (with email)
        data['email'] = 'test@test.com'
        data['recfile'] = open(pdbf, 'rb')
        data['ligfile'] = open(molf, 'rb')
        rv = c.post('/job', data=data, follow_redirects=True)
        self.assertEqual(rv.status_code, 503)
        r = re.compile(b'Your job has been submitted.*results will be found.*'
                       b'You will receive an e-mail', re.MULTILINE | re.DOTALL)
        self.assertRegex(rv.data, r)

    def test_upload_struc_file(self):
        """Test upload_struc_file()"""
        incoming = saliweb.test.TempDir()
        ligscore.app.config['DIRECTORIES_INCOMING'] = incoming.tmpdir

        # Missing file
        self.assertRaises(
            saliweb.frontend.InputValidationError,
            ligscore.submit_page.upload_struc_file, None, "receptor", "PDB",
            None)

        with ligscore.app.app_context():
            # Real but empty file
            job = saliweb.frontend.IncomingJob()
            infile = job.get_path('infile')
            with open(infile, 'w') as fh:
                pass  # make empty file
            fh = FileStorage(stream=open(infile, 'rb'), filename='outfile')
            self.assertRaises(
                saliweb.frontend.InputValidationError,
                ligscore.submit_page.upload_struc_file, fh, "receptor", "PDB",
                job)

            # Real non-empty file
            with open(infile, 'w') as fh:
                fh.write('foo')
            fh = FileStorage(stream=open(infile, 'rb'),
                             filename='../../../outfile')
            fname = ligscore.submit_page.upload_struc_file(fh, "receptor",
                                                           "PDB", job)
            self.assertEqual(fname, 'outfile')


if __name__ == '__main__':
    unittest.main()
