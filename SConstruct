import saliweb.build

vars = Variables('config.py')
env = saliweb.build.Environment(vars, ['conf/live.conf'], service_module='ligscore')
Help(vars.GenerateHelpText(env))

env.InstallAdminTools()
env.InstallCGIScripts()

Export('env')
SConscript('backend/ligscore/SConscript')
SConscript('frontend/ligscore/SConscript')
SConscript('html/SConscript')
SConscript('lib/SConscript')
SConscript('txt/SConscript')
SConscript('test/SConscript')
