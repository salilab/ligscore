import saliweb.backend

class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner

    def run(self):
        libs = {'PoseScore': 'protein_ligand_pose_score.lib',
                'RankScore': 'protein_ligand_rank_score.lib'}
        pdb, mol2, lib = open('input.txt').readline().strip().split(' ')
        lib = libs[lib]
        script = """
module load imp
lib=`python -c "import IMP.atom; print IMP.atom.get_data_path('%s')"`
ligand_score %s %s "$lib" > score.list 2> score.log
""" % (lib, mol2, pdb)
        r = self.runnercls(script)
        r.set_sge_options('-l arch=linux-x64')
        return r

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)

