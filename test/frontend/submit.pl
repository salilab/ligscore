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

# Check removeSpecialChars
{
  my $out = ligscore::removeSpecialChars("/f2oo\@b,a^r#34.i;");
  is($out, "f2oobar34.i", "removeSpecialChars");
}


