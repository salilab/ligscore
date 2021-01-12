import unittest
import saliweb.test
import re

# Import the ligscore frontend with mocks
ligscore = saliweb.test.import_mocked_frontend("ligscore", __file__,
                                               '../../frontend')


class Tests(saliweb.test.TestCase):
    """Check results page"""

    def test_results_file(self):
        """Test download of results files"""
        with saliweb.test.make_frontend_job('testjob') as j:
            j.make_file('score.list')
            c = ligscore.app.test_client()
            # Good file
            rv = c.get('/job/testjob/score.list?passwd=%s' % j.passwd)
            self.assertEqual(rv.status_code, 200)

    def test_ok_job(self):
        """Test display of OK job"""
        with saliweb.test.make_frontend_job('testjob2') as j:
            j.make_file("input.txt", "test.pdb test.mol2 PoseScore.lib\n")
            j.make_file("score.list",
                        "mol1 -34.62\nmol2 -20.02\n"
                        "Score for mol3 is -25.75\n" * 10 + "\n\n")
            c = ligscore.app.test_client()

            # Test first page
            rv = c.get('/job/testjob2?passwd=%s' % j.passwd)
            r = re.compile(rb'Receptor.*Ligand.*Score Type.*test\.pdb.*'
                           rb'test\.mol2.*PoseScore\.lib.*<td>1</td>.*'
                           rb'<td>\-34\.62</td>.*</tr>.*\-20\.02.*\-25\.75.*'
                           rb'show next 20.*score\.list.*Download output file',
                           re.MULTILINE | re.DOTALL)
            self.assertRegexpMatches(rv.data, r)

            # Test last page
            rv = c.get('/job/testjob2?passwd=%s&from=25&to=45' % j.passwd)
            r = re.compile(rb'Receptor.*Ligand.*Score Type.*test\.pdb.*'
                           rb'test\.mol2.*PoseScore\.lib.*<td>25</td>.*'
                           rb'<td>\-34\.62</td>.*</tr>.*\-20\.02.*\-25\.75.*'
                           rb'show prev 20.*score\.list.*Download output file',
                           re.MULTILINE | re.DOTALL)
            self.assertRegexpMatches(rv.data, r)

    def test_failed_job(self):
        """Test display of failed job"""
        with saliweb.test.make_frontend_job('testjob3') as j:
            j.make_file("input.txt", "test.pdb test.mol2 PoseScore.lib\n")
            c = ligscore.app.test_client()
            rv = c.get('/job/testjob3?passwd=%s' % j.passwd)
            self.assertIn(b'No output file was produced', rv.data)


if __name__ == '__main__':
    unittest.main()
