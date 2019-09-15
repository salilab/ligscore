import unittest
import saliweb.test

# Import the ligscore frontend with mocks
ligscore = saliweb.test.import_mocked_frontend("ligscore", __file__,
                                               '../../frontend')


class Tests(saliweb.test.TestCase):

    def test_index(self):
        """Test index page"""
        c = ligscore.app.test_client()
        rv = c.get('/')
        self.assertIn(b'Upload protein coordinate file',
                      rv.data)

    def test_about(self):
        """Test about page"""
        c = ligscore.app.test_client()
        rv = c.get('/about')
        self.assertIn(b'PoseScore ranks a native/near-native binding pose',
                      rv.data)

    def test_help(self):
        """Test help page"""
        c = ligscore.app.test_client()
        rv = c.get('/help')
        self.assertIn(b'To generate scores for large numbers of complexes',
                      rv.data)

    def test_links(self):
        """Test links page"""
        c = ligscore.app.test_client()
        rv = c.get('/links')
        self.assertIn(b'DOCK Blaster', rv.data)

    def test_queue(self):
        """Test queue page"""
        c = ligscore.app.test_client()
        rv = c.get('/job')
        self.assertIn(b'No pending or running jobs', rv.data)


if __name__ == '__main__':
    unittest.main()
