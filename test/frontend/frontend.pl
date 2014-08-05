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

# Test get_lab_navigation_links
{
    my $self = $t->make_frontend();
    my $links = $self->get_lab_navigation_links();
    isa_ok($links, 'ARRAY', 'lab navigation links');
    like($links->[0],
         qr#<a href="http.*">Sali Lab Home</a>#, 'Lab link');
    like($links->[9],
         '/<a href="http:\/\/shoichetlab.*">Shoichet Lab<\/a>/',
         'Shoichet link');
}

# Test get_project_menu
{
    my $self = $t->make_frontend();
    my $menu = $self->get_project_menu();
    is($menu, "", "Project menu");
}

# Test get_header_page_title
{
    my $self = $t->make_frontend();
    my $header = $self->get_header_page_title();
    like($header, qr#a web server for scoring#, "header page title");
}

# Test get_footer
{
    my $self = $t->make_frontend();
    my $footer = $self->get_footer();
    like($footer, qr#Statistical Potential for Modeling#, "footer");
}

# Test get_index_page
{
    my $self = $t->make_frontend();
    my $txt = $self->get_index_page();
    like($txt, '/Email address.*Score type/ms',
         "get_index_page");
}
