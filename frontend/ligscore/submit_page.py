from flask import request
import saliweb.frontend
from werkzeug.utils import secure_filename
import os


def handle_new_job():
    user_name = request.form.get("name")
    recfile = request.files.get("recfile")
    ligfile = request.files.get("ligfile")
    email = request.form.get("email")
    scoretype = request.form.get("scoretype")
    scoretype = {'Pose': 'PoseScore', 'Rank': 'RankScore'}.get(scoretype)

    saliweb.frontend.check_email(email, required=False)
    if not scoretype:
        raise saliweb.frontend.InputValidationError(
            "Error in the types of scoring; scoretype should be "
            "'Pose' or 'Rank'")

    job = saliweb.frontend.IncomingJob(user_name)
    recfile = upload_struc_file(recfile, "receptor", "PDB or mmCIF", job)
    ligfile = upload_struc_file(ligfile, "ligand", "mol2", job)

    with open(job.get_path('input.txt'), 'w') as fh:
        fh.write("%s %s %s\n" % (recfile, ligfile, scoretype))

    job.submit(email)
    return saliweb.frontend.redirect_to_results_page(job)


def upload_struc_file(fh, struc_type, file_type, job):
    if not fh:
        raise saliweb.frontend.InputValidationError(
            "Missing %s molecule input: please upload %s file in %s format"
            % (struc_type, struc_type, file_type))

    fname = secure_filename(fh.filename)
    full_fname = job.get_path(fname)
    fh.save(full_fname)
    if os.stat(full_fname).st_size == 0:
        raise saliweb.frontend.InputValidationError(
            "You have uploaded an empty file: %s" % fname)
    return fname
