#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::RealBin/../lib/Log-Log4perl-1.46/lib";
use lib "$FindBin::RealBin/../lib";
use Log::Log4perl qw(:no_extra_logdie_message);
use bcgTree;
use Getopt::ArgvFile;

my %options;

=head1 NAME

bcgTree.pl

=head1 DESCRIPTION

Wrapper to produce phylogenetic trees from the core genome (107 essential genes) of bacteria.

=head1 USAGE

  $ bcgTree.pl [@cofigfile] --proteome bac1=bacterium1.pep.fa --proteome bac2=bacterium2.faa [options]

=head1 OPTIONS

=over 25

=item [@configfile]

Optional path to a configfile with @ as prefix.
Config files consist of command line parameters and arguments just as passed on the command line.
Space and comment lines are allowed (and ignored).
Spreading over multiple lines is supported.

=cut

=item --proteome <ORGANISM>=<FASTA> [--proteome <ORGANISM>=<FASTA> ..]

Multiple pairs of organism and proteomes as fasta file paths

=cut

$options{'proteome|p=s%'} = \( my $opt_proteome );

=item [--outdir <STRING>]

output directory for the generated output files (default: bcgTree)

=cut

$options{'outdir=s'} = \( my $opt_outdir="bcgTree" );

=item [--help] 

show help

=cut

$options{'help|h|?'} = \( my $opt_help );

=item [--version] 

show version number of bcgTree and exit

=cut

$options{'version'} = \( my $opt_version );

=item [--hmmsearch-bin=<FILE>]

Path to hmmsearch binary file. Default tries if hmmsearch is in PATH;

=cut

$options{'hmmsearch-bin=s'} = \( my $opt_hmmsearch_bin = `which hmmsearch 2>/dev/null` );

=item [--muscle-bin=<FILE>]

Path to muscle binary file. Default tries if muscle is in PATH;

=cut

$options{'muscle-bin=s'} = \( my $opt_muscle_bin = `which muscle 2>/dev/null` );

=item [--gblocks-bin=<FILE>]

Path to the Gblocks binary file. Default tries if Gblocks is in PATH;

=cut

$options{'gblocks-bin=s'} = \( my $opt_gblocks_bin = `which Gblocks 2>/dev/null` );

=item [--raxml-bin=<FILE>]

Path to the raxml binary file. Default tries if raxmlHPC is in PATH;

=cut

$options{'raxml-bin=s'} = \( my $opt_raxml_bin = `which raxmlHPC 2>/dev/null` );

=back

=item [--threads=<INT>]

Number of threads to be used (currently only relevant for raxml). Default: 2
From the raxml man page:
PTHREADS VERSION ONLY! Specify the number of threads you want to run.  Make sure to set "-T" to at most the number of CPUs you have on your machine, otherwise, there will be a huge performance decrease!

=cut

$options{'threads=i'} = \( my $opt_threads = 2 );

=back

=item [--bootstraps=<INT>]

Number of bootstraps to be used (passed to raxml). Default: 10

=cut

$options{'bootstraps=i'} = \( my $opt_bootstraps = 10 );

=back

=item [--hmmfile=<PATH>]

Path to HMM file to be used for hmmsearch. Default: <bcgTreeDir>/data/essential.hmm

=cut

$options{'hmmfile=s'} = \( my $opt_hmmfile = "$FindBin::RealBin/../data/essential.hmm" );

=back

=item [--raxml-x-rapidBootstrapRandomNumberSeed=<INT>]

Random number seed for raxml (passed through as -x option to raxml).
Default: Random number in range 1..1000000 (see raxml command in log file to find out the actual value).
Note: you can abbreviate options (as long as they stay unique)
so --raxml-x=12345 is equivalent to --raxml-x-rapidBootstrapRandomNumberSeed=12345

=cut

$options{'raxml-x-rapidBootstrapRandomNumberSeed=i'} = \( my $opt_raxml_x = int(rand(1000000))+1 );

=back

=item [--raxml-p-parsimonyRandomSeed=<INT>]

Random number seed for raxml (passed through as -p option to raxml).
Default: Random number in range 1..1000000 (see raxml command in log file to find out the actual value).
Note: you can abbreviate options (as long as they stay unique)
so --raxml-p=12345 is equivalent to --raxml-p-parsimonyRandomSeed=12345

=cut

$options{'raxml-p-parsimonyRandomSeed=i'} = \( my $opt_raxml_p = int(rand(1000000))+1 );

=back

=head1 CODE

=cut

GetOptions(%options) or pod2usage(1);
if($opt_version){
    print "bcgTree version: ".$bcgTree::VERSION."\n";
    exit 0;
}
pod2usage(1) if ($opt_help);
pod2usage( -msg => "No proteome specified. Use --proteome name=file.fa", -verbose => 0, -exitval => 1 )  unless ( $opt_proteome );
pod2usage( -msg => 'hmmsearch not in $PATH and binary not specified use --hmmsearch-bin', -verbose => 0, -exitval => 1 ) unless ($opt_hmmsearch_bin);
pod2usage( -msg => 'muscle not in $PATH and binary not specified use --muscle-bin', -verbose => 0, -exitval => 1 ) unless ($opt_muscle_bin);
pod2usage( -msg => 'Gblocks not in $PATH and binary not specified use --gblocks-bin', -verbose => 0, -exitval => 1 ) unless ($opt_gblocks_bin);
pod2usage( -msg => 'raxmlHPC not in $PATH and binary not specified use --raxml-bin', -verbose => 0, -exitval => 1 ) unless ($opt_raxml_bin);
chomp($opt_hmmsearch_bin, $opt_muscle_bin, $opt_gblocks_bin, $opt_raxml_bin);

# init a root logger in exec mode
Log::Log4perl->init(
	\q(
                log4perl.rootLogger                     = DEBUG, Screen
                log4perl.appender.Screen                = Log::Log4perl::Appender::Screen
                log4perl.appender.Screen.stderr         = 1
                log4perl.appender.Screen.layout         = PatternLayout
                log4perl.appender.Screen.layout.ConversionPattern = [%d{MM-dd HH:mm:ss}] [%C] %m%n
        )
);

my $L = Log::Log4perl::get_logger();
my $bcgTree = bcgTree->new({
	'proteome' => $opt_proteome,
	'outdir' => $opt_outdir,
	'hmmsearch-bin' => $opt_hmmsearch_bin,
	'muscle-bin' => $opt_muscle_bin,
	'gblocks-bin' => $opt_gblocks_bin,
	'raxml-bin' => $opt_raxml_bin,
	'separator' => '_-_',
	'threads' => $opt_threads,
	'bootstraps' => $opt_bootstraps,
	'hmmfile' => $opt_hmmfile,
	'raxml-p' => $opt_raxml_p,
	'raxml-x' => $opt_raxml_x
});
$bcgTree->check_existence_of_fasta_files();
$bcgTree->rename_fasta_headers();
$bcgTree->run_hmmsearch();
$bcgTree->collect_best_hmm_hits();
$bcgTree->get_sequences_of_best_hmm_hits();
$bcgTree->run_muscle_and_gblocks();
$bcgTree->complete_and_concat_alignments();
$bcgTree->run_raxml();

sub logfile{
	return "$opt_outdir/bcgTree.log";
}

__END__

$bcgTree->remove_temporary_files();

=head1 AUTHORS

=over

=item * Markus Ankenbrand, markus.ankenbrand@uni-wuerzburg.de

=item * Alexander Keller, a.keller@biozentrum.uni-wuerzburg.de

=back

