import saliweb.backend

class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner

    def run(self):
        par = open('input.txt', 'r')
        input_line = par.readline().strip()

        script = """
export Score=/netapp/sali/haofan/kbp/server/
perl $Score/runScoreServer.pl %s >& score.log
""" % (input_line) 

        r = self.runnercls(script)
        r.set_sge_options('-l arch=lx24-amd64')
        return r

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)

