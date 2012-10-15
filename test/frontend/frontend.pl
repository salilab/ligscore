#!/usr/bin/perl -w

use saliweb::Test;
use Test::More 'no_plan';

BEGIN {
    use_ok('ligscore');
}

my $t = new saliweb::Test('ligscore');

# Test get_navigation_links
{
    my $self = $t->make_frontend();
    my $links = $self->get_navigation_links();
    isa_ok($links, 'ARRAY', 'navigation links');
    like($links->[0],
         qr#<a href="http://modbase/top/help.cgi\?type=about">About</a>#,
         'About link');
    like($links->[1],
         '/<a href="http:\/\/modbase\/top\/">Web Server<\/a>/', 'Index link');
}
