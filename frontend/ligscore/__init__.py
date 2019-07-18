from flask import render_template, request, send_from_directory
import saliweb.frontend
from saliweb.frontend import get_completed_job, Parameter, FileParameter
import os


parameters=[Parameter("name", "Job name", optional=True),
            FileParameter("recfile", "Protein coordinate file (PDB)"),
            FileParameter("ligfile", "Ligand coordinate file (mol2)"),
            Parameter("scoretype", 'Score type ("Pose" or "Rank")')]
app = saliweb.frontend.make_application(__name__, parameters)


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/help')
def help():
    return render_template('help.html')


@app.route('/about')
def about():
    return render_template('about.html')


@app.route('/links')
def links():
    return render_template('links.html')


@app.route('/job', methods=['GET', 'POST'])
def job():
    if request.method == 'GET':
        return saliweb.frontend.render_queue_page()
    else:
        pass  # todo


@app.route('/results.cgi/<name>')  # compatibility with old perl-CGI scripts
@app.route('/job/<name>')
def results(name):
    job = get_completed_job(name, request.args.get('passwd'))
    # todo


@app.route('/job/<name>/<path:fp>')
def results_file(name, fp):
    job = get_completed_job(name, request.args.get('passwd'))
    return send_from_directory(job.directory, fp)