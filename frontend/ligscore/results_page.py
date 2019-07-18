from flask import request, abort
import saliweb.frontend
import collections

Transform = collections.namedtuple('Transform', ['number', 'score'])


def show_results_page(job):
    show_from = get_int('from', 1)
    show_to = get_int('to', 20)
    with open(job.get_path('input.txt')) as fh:
        receptor, ligand, scoretype = fh.readline().rstrip('\r\n').split(' ')

    num_transforms = 0
    transforms = []
    with open(job.get_path('score.list')) as fh:
        for line in fh:
            spl = line.rstrip('\r\n').split()
            if len(spl) > 0:
                num_transforms += 1
                if num_transforms >= show_from and num_transforms <= show_to:
                    transforms.append(Transform(number=num_transforms,
                                                score="%.2f" % float(spl[-1])))
    return saliweb.frontend.render_results_template("results_ok.html",
        receptor=receptor, ligand=ligand, scoretype=scoretype,
        transforms=transforms, show_from=show_from, show_to=show_to,
        num_transforms=num_transforms, job=job)


def get_int(name, default):
    try:
        return int(request.args.get(name, ""))
    except ValueError:
        return default
