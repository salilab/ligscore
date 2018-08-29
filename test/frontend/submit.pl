#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp;

BEGIN {
    use_ok('ligscore');
}

my $t = new saliweb::Test('ligscore');

# Check bad score type
{
    my $self = $t->make_frontend();
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "bad score type";
    like($@, qr/Error in the types of scoring/, "exception message");
}

# Check missing receptor file
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    $cgi->param('scoretype', 'Pose');
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "missing receptor file";
    like($@, qr/Missing receptor molecule input/, "exception message");
}

# Check empty receptor file
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    ok(mkdir("incoming"), "mkdir incoming");
    ok(mkdir("upload"), "mkdir upload");
    ok(open(FH, "> upload/test.pdb"), "Open test.pdb");
    ok(close(FH), "Close test.pdb");

    open(PDB, "upload/test.pdb");

    $cgi->param('scoretype', 'Pose');
    $cgi->param('recfile', \*PDB);
    throws_ok { $self->get_submit_page() }
              saliweb::frontend::InputValidationError,
              "empty receptor file";
    like($@, qr/uploaded an empty file/, "exception message");

    chdir('/') # Allow the temporary directory to be deleted
}

# Check OK pose submission
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    ok(mkdir("incoming"), "mkdir incoming");
    ok(mkdir("upload"), "mkdir upload");
    ok(open(FH, "> upload/test.pdb"), "Open test.pdb");
    print FH "foo";
    ok(close(FH), "Close test.pdb");

    ok(open(FH, "> upload/test.mol2"), "Open test.mol2");
    print FH "foo";
    ok(close(FH), "Close test.mol2");

    open(PDB, "upload/test.pdb");
    open(MOL, "upload/test.mol2");
    $cgi->param('scoretype', 'Pose');
    $cgi->param('recfile', \*PDB);
    $cgi->param('ligfile', \*MOL);

    my $ret = $self->get_submit_page();
    like($ret, qr/Your job has been submitted/,
         "submit page HTML");

    chdir('/') # Allow the temporary directory to be deleted
}

# Check OK rank submission
{
    my $self = $t->make_frontend();
    my $cgi = $self->cgi;

    my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
    ok(chdir($tmpdir), "chdir into tempdir");

    ok(mkdir("incoming"), "mkdir incoming");
    ok(mkdir("upload"), "mkdir upload");
    ok(open(FH, "> upload/test.pdb"), "Open test.pdb");
    print FH "foo";
    ok(close(FH), "Close test.pdb");

    ok(open(FH, "> upload/test.mol2"), "Open test.mol2");
    print FH "foo";
    ok(close(FH), "Close test.mol2");

    open(PDB, "upload/test.pdb");
    open(MOL, "upload/test.mol2");
    $cgi->param('scoretype', 'Rank');
    $cgi->param('email', 'foo@example.com');
    $cgi->param('recfile', \*PDB);
    $cgi->param('ligfile', \*MOL);

    my $ret = $self->get_submit_page();
    like($ret, qr/Your job has been submitted.*with results link/ms,
         "submit page HTML");

    chdir('/') # Allow the temporary directory to be deleted
}

# Check removeSpecialChars
{
  my $out = ligscore::removeSpecialChars("/f2oo\@b,a^r#34.i;");
  is($out, "f2oobar34.i", "removeSpecialChars");
}


