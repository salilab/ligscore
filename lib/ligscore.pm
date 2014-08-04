package ligscore;
use saliweb::frontend;

use strict;

our @ISA = "saliweb::frontend";

sub get_help_page {
  my ($self, $display_type) = @_;
  my $file;
  if ($display_type eq "contact") {
    $file = "contact.txt";
  } elsif ($display_type eq "about") {
    $file = "about.txt";
  } elsif ($display_type eq "FAQ") {
    $file = "FAQ.txt";
  } elsif ($display_type eq "links") {
    $file = "links.txt";
  } else {
    $file = "help.txt";
  }
  return $self->get_text_file($file);
}

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

sub get_lab_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    my $links = $self->SUPER::get_lab_navigation_links();
    push @$links, $q->a({-href=>'http://shoichetlab.compbio.ucsf.edu/'},
                        'Shoichet Lab');
    return $links;
}

sub get_navigation_links {
    my $self = shift;
    my $q = $self->cgi;
    return [
        $q->a({-href=>$self->about_url}, "About"),
        $q->a({-href=>$self->index_url}, "Web Server"),
        $q->a({-href=>$self->help_url}, "Help"),
        $q->a({-href=>$self->queue_url}, "Current queue"),
        $q->a({-href=>$self->links_url}, "Links")
        ];
}

sub get_project_menu {
  # no menu
  return "";
}

sub get_header_page_title {
  return "<table> <tbody> <tr> <td halign='left'>
  <table><tr><td><img src=\"http://salilab.org/ligscore/html/img/logo.jpg\" align = 'center' height = '60'></td>
             <td><img src=\"http://salilab.org/ligscore/html/img/logo2.png\" align = 'left' height = '48'></td></tr>
         <tr><td><h3>Pose &amp; Rank - a web server for scoring protein-ligand complexes.</h3> </td></tr></table>
      <td width='20'></td> <td halign='right'><img src=\"http://salilab.org/ligscore/html/img/logo3.png\" height = '80'></td></tr>
  </tbody>
  </table>";
}

sub get_footer {
  return "<hr size='2' width=\"80%\"><div id='address'> Fan H, Schneidman-Duhovny D, Irwin J, Dong GQ, Shoichet B, Sali A. Statistical Potential for Modeling and Ranking of Protein-Ligand Interactions. J Chem Inf Model. 2011, 51:3078-92. [<a href=\"http://pubs.acs.org/doi/abs/10.1021/ci200377u\" > Abstract </a>] <br>
    <p> <p>Contact: <script>escramble(\"poserank\",\"salilab.org\")</script></p></p></div>\n";
}

sub get_index_page {
    my $self = shift;
    my $q = $self->cgi;

    my $ScoreTypeValues = ['Pose', 'Rank'];
    return "<div id=\"resulttable\">\n" .
#           $q->h2(" Protein-Ligand Score: Scoring of Protein-ligand Complex Structures") .
           $q->start_form({-name=>"ligscoreform", -method=>"post",
                           -action=>$self->submit_url}) .
           $q->table(
#               $q->Tr($q->td($q->h3("General information",
#                                    $self->help_link("general")))) .
               $q->Tr($q->td("Email address (optional)"), 
                      $q->td($q->textfield({-name=>"email",
                                            -value=>$self->email}))) .
               $q->Tr($q->td("Upload protein coordinate file (pdb)",
                             $q->br), $q->td($q->filefield({-name=>"recfile"}), $q->td("<a href=\"html/examples/1G9V.pdb". "\">sample protein input</a>"))) . 
               $q->Tr($q->td("Upload ligand coordinate file (mol2)",
                             $q->br), $q->td($q->filefield({-name=>"ligfile"}), $q->td("<a href=\"html/examples/1G9V_ligand.mol2". "\">sample ligand input</a>"))) . 
               $q->Tr($q->td("Name your job (optional)",
                             $q->br), $q->td($q->textfield({-name=>"name",
                                            -value=>"job"}), $q->td("<a href=\"html/examples/1G9V_PoseScore.list". "\">sample output</a>"))) .
               $q->Tr($q->td("Score type",
                             $q->br), $q->td($q->popup_menu("scoretype", $ScoreTypeValues))) .
               $q->Tr($q->td({-colspan=>"2"},
                             "<center>" .
                             $q->input({-type=>"submit", -value=>"Submit"}) .
                             $q->input({-type=>"reset", -value=>"Reset"}) .
                             "</center><p>&nbsp;</p>"))) .
#               $q->Tr($q->td("The server is under maintainance during Feb. 27-29, 2012", $q->br)).
           $q->end_form .
           "</div>\n"; 
}

sub get_submit_parameter_help {
    my $self = shift;
    return [
        $self->parameter("name", "Job name", 1),
        $self->file_parameter("recfile", "Protein coordinate file (PDB)"),
        $self->file_parameter("ligfile", "Ligand coordinate file (mol2)"),
        $self->parameter("scoretype", 'Score type ("Pose" or "Rank")')
    ];
}

sub get_submit_page {
  my $self = shift;
  my $q = $self->cgi;
  my $user_name = $q->param('name')||""; # user-provided job name
  my $recfile = $q->param("recfile");
  my $ligfile = $q->param("ligfile");
  my $email = $q->param('email');
 
  check_optional_email($email);

  my $scoretype = $q->param("scoretype");

  if($scoretype eq "Pose") { $scoretype = "PoseScore.lib"; }
  else {
    if($scoretype eq "Rank") { $scoretype = "RankScore.lib"; }
    else {
        throw saliweb::frontend::InputValidationError("Error in the types of scoring<p>");
    }
  }

  my $job = $self->make_job($user_name);
  my $jobdir = $job->directory;

  my $recFileUsed = 0;
  my $ligFileUsed = 0;

  my $receptorFileName = "";
  my $ligandFileName = "";

  #receptor molecule
  if(length $recfile > 0) {
    $recFileUsed = 1;
    $recfile =~ s/.*[\/\\](.*)/$1/;
    $recfile = removeSpecialChars($recfile);
    my $rupload_filehandle = $q->upload("recfile");
    open UPLOADFILE, ">$jobdir/$recfile";
    while ( <$rupload_filehandle> ) { print UPLOADFILE; }
    close UPLOADFILE;
    my $filesize = -s "$jobdir/$recfile";
    if($filesize == 0) {
      throw saliweb::frontend::InputValidationError("You have uploaded an empty file: $recfile");
    }
    $receptorFileName = $recfile;
  } else {
    throw saliweb::frontend::InputValidationError("Error in receptor molecule input: please upload receptor PDB file as *.pdb");
  }

  #ligand molecule
  if(length $ligfile > 0) {
    $ligFileUsed = 1;
    $ligfile =~ s/.*[\/\\](.*)/$1/;
    $ligfile = removeSpecialChars($ligfile);
    my $lupload_filehandle = $q->upload("ligfile");
    open UPLOADFILE, ">$jobdir/$ligfile";
    while ( <$lupload_filehandle> ) { print UPLOADFILE; }
    close UPLOADFILE;
    my $filesize = -s "$jobdir/$ligfile";
    if($filesize == 0) {
      throw saliweb::frontend::InputValidationError("You have uploaded an empty file: $ligfile");
    }
    $ligandFileName = $ligfile;
  } else {
    throw saliweb::frontend::InputValidationError("Error in ligand molecule input: please specify PDB code or upload file");
  }

  my $input_line = $jobdir . "/input.txt";
  open(INFILE, "> $input_line")
    or throw saliweb::frontend::InternalError("Cannot open $input_line: $!");
  print INFILE "$receptorFileName $ligandFileName $scoretype\n";

  $job->submit($email);

  # Inform the user of the job name and results URL
  my $ret = $q->p("Your job has been submitted with job ID " . $job->name) .
    $q->p("Results will be found at <a href=\"" . $job->results_url . "\">this link</a>.");
  if ($email) {
    $ret .= $q->p("You will receive an e-mail with results link once the job has finished");
  }
  return $ret;
}

sub get_results_page {
  my ($self, $job) = @_;
  my $q = $self->cgi;

  my $return = '';
  my $jobname = $job->name;
  my $joburl = $job->results_url;
#  my $passwd = $q->param('passwd');
  my $from = $q->param('from');
  my $to = $q->param('to');
  if(length $from == 0) { $from = 1; $to = 20; }

  $return .= print_input_data($job);
  if(-f 'score.list') {
    $return .= display_output_table($joburl, $from, $to);
    $return .= $q->p("<a href=\"" . $job->get_results_file_url('score.list') . "\">Download output file</a>.");
  } else {
    $return .= $q->p("No output file was produced. Please inspect the log files to determine the problem.");
    $return .= $q->p("<a href=\"" . $job->get_results_file_url('score.log') . "\">View score log file</a>.");
  }
  $return .= $job->get_results_available_time();
  return $return; 
}

sub display_output_table {
  #my ($self, $job) = @_;
  my $joburl = shift;
  my $first = shift;
  my $last = shift;
  my $return = "";

  $return .= "<hr size=2 width=90%>";
  $return .= print_table_header();

  open(DATA, "score.list");
  my $ligandPdb = "";
  my $receptorPdb = "";
  my $transNum = 0;
  my @colors=("#cccccc","#efefef");
  while(<DATA>) {
    chomp;
    my @tmp=split;
    if($#tmp>0) {
      $transNum++;
      if($transNum >= $first and $transNum <= $last) {
        my $score = sprintf("%.2f", $tmp[1]);

        my $color = $colors[$transNum % 2];
        $return .= "<tr bgcolor=$color><td>$transNum</td>
                                <td>$score</td>";
        # generate PDB link
        # my $pdb_joburl = $joburl;
        # $pdb_joburl =~ s/results/model/;
        # my $pdb_url = $pdb_joburl . "&from=$transNum&to=$transNum";
        # $return .= "<td> <a href=\"" . $pdb_url . "\"> result$transNum.pdb </a></td>";
        # generate link to model page
        # my $model_url = $pdb_url;
        # $model_url =~ s/model/model2/;
        # $return .= "<td> <a href=\"" . $model_url . "\"> view </a></td>";
        # $return .= "</tr>";
      }
    }
  }

  # links to previous and next twenty results
  $return .= "<tr><td>";
 if($first > 20) {
    my $prev_from = $first - 20;
    my $prev_to = $last - 20;
    my $prev_page_url = $joburl . "&from=$prev_from&to=$prev_to";
    $return .= "<a href=\"" . $prev_page_url . "\">&laquo;&laquo; show prev 20 </a>";
  }
  $return .= "</td><td></td><td></td><td></td><td></td><td>";
  if($last < $transNum) {
    my $next_from = $first + 20;
    my $next_to = $last + 20;
    my $next_page_url = $joburl . "&from=$next_from&to=$next_to";
    $return .= "<a href=\"" . $next_page_url . "\">&raquo;&raquo; show next 20 </a>";
  }
  $return .= "</td></tr></table>";
  return $return;
}

sub print_table_header() {
return "
<table cellspacing=\"0\" cellpadding=\"0\" width=\"90%\" align=center>
<tr>
<td><font color=blue><b>Model No</b></td>
<td><font color=blue><b>Score</b></td>
</tr>
";
}

sub print_input_data() {
  my $job = shift;
    
  my $filename = "input.txt";
  open FILE, "<$filename" or die "Can't open file: $filename";
  my @dataFile = <FILE>;
  my $dataLine = $dataFile[0];
  chomp($dataLine);
  my @data = split(' ',$dataLine);
  
  my $receptor_url = $job->get_results_file_url($data[0]);
  my $ligand_url = $job->get_results_file_url($data[1]);
    
  my $return = "<table width=\"90%\"><tr>
<td><font color=blue>Receptor</td>
<td><font color=blue>Ligand</td>
<td><font color=blue>Score Type</td>
</tr>";

  $return .= "<tr><td><a href=\"". $receptor_url . "\">  $data[0] </a> </td> " .
    " <td><a href=\"". $ligand_url . "\"> $data[1] </a> </td> " ." <td>$data[2]</td> ";
  return $return;
}

sub removeSpecialChars {
  my $str = shift;
  $str =~ s/[^\w,^\d,^\.]//g;
  return $str;
}

1;
