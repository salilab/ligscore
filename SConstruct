import saliweb.build

vars = Variables('config.py')
env = saliweb.build.Environment(vars, ['conf/live.conf'], service_module='ligscore')
Help(vars.GenerateHelpText(env))

env.InstallAdminTools()

Export('env')
SConscript('backend/ligscore/SConscript')
SConscript('frontend/ligscore/SConscript')
SConscript('html/SConscript')
SConscript('test/SConscript')
