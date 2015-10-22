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

  $ bcgTree.pl --genome bac1=bacterium1.pep.fa --genome bac2=bacterium2.faa [options]

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

=back


=head1 CODE

=cut

GetOptions(%options) or pod2usage(1);
pod2usage(1) if ($opt_help);
pod2usage(1) unless ($opt_proteome);

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

