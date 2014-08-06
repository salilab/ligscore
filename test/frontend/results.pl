#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('ligscore');
}

my $t = new saliweb::Test('ligscore');

# Check no results
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    ok(open(FH, "> input.txt"), "Open input.txt");
    print FH "test.pdb test.mol2 PoseScore.lib";
    ok(close(FH), "Close input.txt");

    my $ret = $frontend->get_results_page($job);
    like($ret, '/No output file was produced/',
         'get_results_page (failed job)');

    chdir("/");
}

# Check OK results
{
    my $frontend = $t->make_frontend();
    my $job = new saliweb::frontend::CompletedJob($frontend,
                        {name=>'testjob', passwd=>'foo', directory=>'/foo/bar',
                         archive_time=>'2009-01-01 08:45:00'});
    my $tmpdir = tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    ok(open(FH, "> input.txt"), "Open input.txt");
    print FH "test.pdb test.mol2 PoseScore.lib";
    ok(close(FH), "Close input.txt");

    ok(open(FH, "> score.list"), "Open score.list");
    print FH "mol1 -34.62\nmol2 -20.02\nScore for mol3 is -25.75\n";
    ok(close(FH), "Close score.list");

    my $ret = $frontend->get_results_page($job);
    like($ret, '/Receptor.*Ligand.*Score Type.*test\.pdb.*test\.mol2.*' .
               'PoseScore\.lib.*<td>1</td><td>\-34\.62</td></tr>.*' .
               '\-20\.02.*\-25\.75.*score\.list.*Download output file/ms',
         'get_results_page (OK job)');

    chdir("/");
}
