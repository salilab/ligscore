import unittest
import ligscore
import saliweb.test
import saliweb.backend
import os


class JobTests(saliweb.test.TestCase):
    """Check custom ligscore Job class"""

    def test_run_ok(self):
        """Test successful run method"""
        j = self.make_test_job(ligscore.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            with open('input.txt', 'w') as fh:
                fh.write('test.pdb test.mol2 PoseScore')
            cls = j.run()
            self.assert_(isinstance(cls, saliweb.backend.SGERunner),
                         "SGERunner not returned")
            os.unlink('input.txt')


if __name__ == '__main__':
    unittest.main()
