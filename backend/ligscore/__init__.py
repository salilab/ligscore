import saliweb.backend


class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.WyntonSGERunner

    def run(self):
        libs = {'PoseScore': 'protein_ligand_pose_score.lib',
                'RankScore': 'protein_ligand_rank_score.lib'}
        with open('input.txt') as fh:
            pdb, mol2, lib = fh.readline().strip().split(' ')
        lib = libs[lib]
        script = """
module load Sali
module load imp
lib=`python -c "import IMP.atom; print IMP.atom.get_data_path('%s')"`
ligand_score %s %s "$lib" > score.list 2> score.log
""" % (lib, mol2, pdb)
        r = self.runnercls(script)
        r.set_sge_options('-l arch=lx-amd64 -l h_rt=00:10:00')
        return r


def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)
