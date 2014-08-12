package ligscore;
use saliweb::frontend;

use strict;

our @ISA = "saliweb::frontend";

sub new {
    return saliweb::frontend::new(@_, @CONFIG@);
}

# Add our own CSS to the page header
sub get_start_html_parameters {
    my ($self, $style) = @_;
    my %param = $self->SUPER::get_start_html_parameters($style);
    push @{$param{-style}->{'-src'}}, $self->htmlroot . '/css/ligscore.css';
    return %param;
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
    my $self = shift;
    my $index = $self->index_url;
    return "<table> <tbody> <tr> <td>
  <table><tr><td><a href=\"http://www.ucsf.edu/\"><img src=\"//salilab.org/ligscore/html/img/logo.jpg\" height = '60' alt=\"UCSF\" /></a></td>
             <td><a href=\"$index\"><img src=\"//salilab.org/ligscore/html/img/logo2.png\" height = '48' alt=\"Pose &amp; Rank logo\" /></a></td></tr>
         <tr><td><h3>Pose &amp; Rank - a web server for scoring protein-ligand complexes.</h3> </td></tr></table>
      </td><td width='20'></td> <td><img src=\"//salilab.org/ligscore/html/img/logo3.png\" height = '80' alt=\"Docking example\"/></td></tr>
  </tbody>
  </table>";
}

sub get_footer {
  return "<hr size='2' width=\"80%\" /><div id='address'><p>Fan H, Schneidman-Duhovny D, Irwin J, Dong GQ, Shoichet B, Sali A. Statistical Potential for Modeling and Ranking of Protein-Ligand Interactions. J Chem Inf Model. 2011, 51:3078-92. [<a href=\"http://pubs.acs.org/doi/abs/10.1021/ci200377u\" > Abstract </a>] </p>
    <p>Contact: <script type='text/javascript'>escramble(\"poserank\",\"salilab.org\")</script></p></div>\n";
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
               $q->Tr($q->td("Upload protein coordinate file (pdb)", $q->br),
                      $q->td($q->filefield({-name=>"recfile"})),
                      $q->td("<a href=\"html/examples/1G9V.pdb".
                             "\">sample protein input</a>")) . 
               $q->Tr($q->td("Upload ligand coordinate file (mol2)", $q->br),
                      $q->td($q->filefield({-name=>"ligfile"})),
                      $q->td("<a href=\"html/examples/1G9V_ligand.mol2".
                             "\">sample ligand input</a>")) . 
               $q->Tr($q->td("Name your job (optional)", $q->br),
                      $q->td($q->textfield({-name=>"name",
                                            -value=>"job"})),
                      $q->td("<a href=\"html/examples/1G9V_PoseScore.list".
                             "\">sample output</a>")) .
               $q->Tr($q->td("Score type", $q->br),
                      $q->td($q->popup_menu("scoretype", $ScoreTypeValues))) .
               $q->Tr($q->td({-colspan=>"2"},
                             "<center>" .
                             $q->input({-type=>"submit", -value=>"Submit"}) .
                             $q->input({-type=>"reset", -value=>"Reset"}) .
                             "</center><p>&nbsp;</p>"))) .
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

sub upload_struc_file {
    my ($self, $fname, $param, $struc_type, $file_type, $q, $jobdir) = @_;

    if (length $fname > 0) {
        $fname =~ s/.*[\/\\](.*)/$1/;
        $fname = removeSpecialChars($fname);
        my $rupload_filehandle = $q->upload($param);
        open UPLOADFILE, ">$jobdir/$fname"
            or die "Cannot open $jobdir/$fname: $!";
        while ( <$rupload_filehandle> ) { print UPLOADFILE; }
        close UPLOADFILE;
        my $filesize = -s "$jobdir/$fname";
        if ($filesize == 0) {
            throw saliweb::frontend::InputValidationError(
                           "You have uploaded an empty file: $fname");
        }
        return $fname;
    } else {
        throw saliweb::frontend::InputValidationError(
                 "Missing $struc_type molecule input: please upload " .
                 "$struc_type file in $file_type format");
    }
}

sub get_submit_page {
  my $self = shift;
  my $q = $self->cgi;
  my $user_name = $q->param('name')||""; # user-provided job name
  my $recfile = $q->param("recfile")||"";
  my $ligfile = $q->param("ligfile")||"";
  my $email = $q->param('email');
 
  check_optional_email($email);

  my $scoretype = $q->param("scoretype")||"";

  if($scoretype eq "Pose") { $scoretype = "PoseScore"; }
  elsif($scoretype eq "Rank") { $scoretype = "RankScore"; }
  else {
      throw saliweb::frontend::InputValidationError("Error in the types of scoring; scoretype should be 'Pose' or 'Rank'");
  }

  my $job = $self->make_job($user_name);
  my $jobdir = $job->directory;

  #receptor molecule
  $recfile = $self->upload_struc_file($recfile, "recfile", "receptor",
                                      "PDB", $q, $jobdir);
  $ligfile = $self->upload_struc_file($ligfile, "ligfile", "ligand",
                                      "mol2", $q, $jobdir);

  my $input_line = $jobdir . "/input.txt";
  open(INFILE, "> $input_line")
    or throw saliweb::frontend::InternalError("Cannot open $input_line: $!");
  print INFILE "$recfile $ligfile $scoretype\n";

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
  my $from = $q->param('from')||"";
  my $to = $q->param('to')||"";
  if(length $from == 0) { $from = 1; $to = 20; }

  $return .= print_input_data($job);
  if(-s 'score.list') {
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

  $return .= "<hr size='2' width='90%' />";
  $return .= print_table_header();

  open(DATA, "score.list");
  my $ligandPdb = "";
  my $receptorPdb = "";
  my $transNum = 0;
  my @classes=("even","odd");
  while(<DATA>) {
    chomp;
    my @tmp=split;
    if($#tmp>0) {
      $transNum++;
      if($transNum >= $first and $transNum <= $last) {
        my $score = sprintf("%.2f", $tmp[$#tmp]);

        my $cls = $classes[$transNum % 2];
        $return .= "<tr class=\"$cls\"><td>$transNum</td>"
                   . "<td>$score</td></tr>\n";
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
    my $prev_page_url = $joburl . "&amp;from=$prev_from&amp;to=$prev_to";
    $return .= "<a href=\"" . $prev_page_url . "\">&laquo;&laquo; show prev 20 </a>";
  }
  $return .= "</td><td></td><td></td><td></td><td></td><td>";
  if($last < $transNum) {
    my $next_from = $first + 20;
    my $next_to = $last + 20;
    my $next_page_url = $joburl . "&amp;from=$next_from&amp;to=$next_to";
    $return .= "<a href=\"" . $next_page_url . "\">&raquo;&raquo; show next 20 </a>";
  }
  $return .= "</td></tr></table>";
  return $return;
}

sub print_table_header() {
return "
<table cellspacing=\"0\" cellpadding=\"0\" width=\"90%\" align=\"center\">
<tr>
<td><b>Model No</b></td>
<td><b>Score</b></td>
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
<td><span class=\"fieldname\">Receptor</span></td>
<td><span class=\"fieldname\">Ligand</span></td>
<td><span class=\"fieldname\">Score Type</span></td>
</tr>";

  $return .= "<tr><td><a href=\"". $receptor_url . "\">  $data[0] </a> </td> " .
    " <td><a href=\"". $ligand_url . "\"> $data[1] </a> </td> " ." <td>$data[2]</td></tr></table> ";
  return $return;
}

sub removeSpecialChars {
  my $str = shift;
  $str =~ s/[^\w\d\.]//g;
  return $str;
}

1;
