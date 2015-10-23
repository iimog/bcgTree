#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Log::Log4perl qw(:no_extra_logdie_message);
use FindBin;
use lib "$FindBin::RealBin/../lib";
use bcgTree;

my %options;

=head1 NAME

bcgTree.pl

=head1 DESCRIPTION

Wrapper to produce phylogenetic trees from the core genome (107 essential genes) of bacteria.

=head1 USAGE

  $ bcgTree.pl --proteome bac1=bacterium1.pep.fa --proteome bac2=bacterium2.faa [options]

=head1 OPTIONS

=over 25

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

$options{'help|?'} = \( my $opt_help );

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


=head1 CODE

=cut

GetOptions(%options) or pod2usage(1);
pod2usage(1) if ($opt_help);
pod2usage( -msg => "No proteome specified. Use --proteome name=file.fa", -verbose => 0 )  unless ( $opt_proteome );
pod2usage( -msg => 'hmmsearch not in $PATH and binary not specified use --hmmsearch-bin', -verbose => 0 ) unless ($opt_hmmsearch_bin);
pod2usage( -msg => 'muscle not in $PATH and binary not specified use --muscle-bin', -verbose => 0 ) unless ($opt_muscle_bin);
pod2usage( -msg => 'Gblocks not in $PATH and binary not specified use --gblocks-bin', -verbose => 0 ) unless ($opt_gblocks_bin);
pod2usage( -msg => 'raxmlHPC not in $PATH and binary not specified use --raxml-bin', -verbose => 0 ) unless ($opt_raxml_bin);

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
my $bcgTree = bcgTree->new({'proteome' => $opt_proteome, 'outdir' => $opt_outdir});
$bcgTree->check_existence_of_fasta_files();
$bcgTree->create_outdir_if_not_exists();
$bcgTree->rename_fasta_headers();

=head1 AUTHORS

=over

=item * Markus Ankenbrand, markus.ankenbrand@uni-wuerzburg.de

=item * Alexander Keller, a.keller@biozentrum.uni-wuerzburg.de

=back

