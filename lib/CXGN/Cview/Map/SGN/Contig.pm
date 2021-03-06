=head1 NAME

CXGN::Cview::Map::SGN::Contig - a class to generate maps of contigs aligned to the genome

=head1 SYNOPSYS

 my $map = CXGN::Cview::Map::SGN::Contig->new($dbh, $id);
 my $chr = $map->get_chromosome(1);
 # etc...

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class implements the following functions:

=cut

package CXGN::Cview::Map::SGN::Contig;
use strict;
use warnings;

use File::Spec;
use CXGN::Cview::MapFactory;
use CXGN::Cview::Map::SGN::Genetic;
use CXGN::Cview::Chromosome::Physical;
use CXGN::Cview::Marker::Physical;


use base qw | CXGN::Cview::Map::SGN::Genetic |;

=head2 function new

  Synopsis:
  Arguments:	a database handle (preferably generated through
                CXGN::DB::Connection) and a map id. Currently,
                only one map_id is supported, with the alpha-
                numeric id of "contig".
  Returns:
  Side effects:
  Description:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $args = shift;

    my $db_version_id = get_db_id($dbh, $id);
    my $self = $class->SUPER::new($dbh, $db_version_id);

    die "Failed to create object via parent class CXGN::Cview::Map::SGN::Genetic" unless $self;

    $self->set_preferred_chromosome_width(18);
    $self->set_short_name($args->{short_name});
    $self->set_long_name($args->{long_name});
    $self->{gbrowse_fpc} = $args->{gbrowse_fpc};
    $self->{temp_dir} = $args->{temp_dir} || '/tmp';
    $self->set_abstract($args->{abstract});
    $self->{marker_link} = $args->{marker_link};
    $self->set_id($id);

    return $self;
}


=head2 function get_chromosome()

  Synopsis:
  Arguments:
  Returns:
  Side effects:
  Description:

=cut

sub get_chromosome {
    my $self = shift;
    my $chr_nr = shift;

    my $map_factory = CXGN::Cview::MapFactory->new($self->get_dbh());
    my $id = get_db_id($self->get_dbh(), $self->get_id());
    my $genetic_map = $map_factory->create({map_version_id=>$id});
    my $genetic=$genetic_map->get_chromosome($chr_nr);
    my $chromosome = CXGN::Cview::Chromosome::Physical->new();

    my $largest_offset = 0;
    eval { 
	my (@gff) = $self->{gbrowse_fpc}->databases();
	if (@gff > 1) { die "Can't deal with multiple databases right now..."; }
	if (!@gff) {    die "No database found!"; }
	my ($gff) = @gff;
	
	for my $m ($genetic->get_markers()) {
	    $m->set_chromosome($chromosome);
	    $chromosome->add_marker($m);
	    my $offset = $m->get_offset();
	    if ($offset > $largest_offset) {
		$largest_offset=$offset;
	    }
	    $m->hide();
	    
	    my @gff_markers = $gff->features(-method => 'marker',
		       -attributes => { Name => $m->get_name() },
		);
	    my @contigs = ();
	    for my $gm (@gff_markers) {
		@contigs = $gm->refseq();
	    }
	    my $count = 0;
	    for my $c (@contigs) {
		my $contig = CXGN::Cview::Marker::Physical->new();
		$contig->set_chromosome($chromosome);
		$contig->set_name($c);
		
		#my $url = "/gbrowse/gbrowse/sanger_tomato_fpc/?name=$c";
		my $url = $self->{gbrowse_fpc}->view_url({ name => $c });
		$contig->set_marker_name($c);
		$contig->set_marker_type("contig");
		$contig->set_url($url);
		$contig->set_offset($m->get_offset());
		$contig->get_label()->set_name($c);
		$contig->get_label()->set_url($url);
		$contig->set_tooltip("Contig: $c. Anchored to: ".($m->get_name()).".");
		$chromosome -> add_marker($contig);
		$count++;
	    }
	}
    };
    $chromosome->set_length($largest_offset);
    $self->{chr}->[$chr_nr]=$chromosome;

    return $chromosome;

}

=head2 function get_overview_chromosome()

  Synopsis:
  Arguments:
  Returns:
  Side effects:
  Description:

=cut

sub get_overview_chromosome {
    my $self = shift;
    my $chr_nr = shift;

    my $bargraph = CXGN::Cview::Chromosome::BarGraph->new();

    my $largest_offset = 0;

    my $chromosome = $self->get_chromosome($chr_nr);

    eval { 
	for my $m ($chromosome->get_markers()) {
	    if ($m->get_marker_type() eq "contig") {
		my $offset = $m->get_offset();
		$bargraph -> add_association("manual", $offset, 1);
		if ($offset>$largest_offset) { $largest_offset = $offset; }
	    }
	}
    };
    if ($@) { 
	# avoid division by zero errors
	$bargraph->set_length(1);
	print STDERR "No data seem available for contig map.\n";
    }
    return $bargraph;
}

=head2 function get_chromosome_connections()
    
  Synopsis:
  Arguments:
  Returns:
  Side effects:
  Description:
    
=cut
    
sub get_chromosome_connections {
    my $self = shift;
    my $chr_nr = shift;
    my @list = ();
    # this map has no connections.!!!!
#    push @list, { map_version_id=>CXGN::Cview::Map::Tools::find_current_version($self->get_dbh(), CXGN::Cview::Map::Tools::current_tomato_map_id), lg_name=>$chr_nr, marker_count=>"?", short_name=>"F2-2000" };
    return @list;
}

sub get_db_id {
    my $dbh = shift;
    my $id = shift;
    my $db_id = $id;
    $db_id=~s/^.*(\d+)$/$1/;
    return CXGN::Cview::Map::Tools::find_current_version($dbh, $db_id);
}


sub can_zoom {
    return 0;
}

sub get_marker_link {
    my $self = shift;
    my $clone_id= shift;
    if ($clone_id) { return ""; }
    else { return ""; }
}

sub get_marker_count {
    my $self = shift;
    my $chr_nr = shift;

    my $tmp_file = "";

    my @lengths = $self->cache_marker_counts();
    return $lengths[$chr_nr-1];
}

sub cache_marker_counts {
    my $self = shift;

    my @lengths = ();
    my $temp_file = File::Spec->catfile($self->{temp_dir}, 'contig'.$self->get_id()."_marker_counts.txt");

    if (! -e ($temp_file)) {
	open(my $TEMP, '>', $temp_file) or die "Can't open $temp_file for writing: $!";
	for my $c (1..12) {
	    my $count = 0;
	    my $chr = $self->get_chromosome($c);
	    for my $m ($chr->get_markers()) {
		if ($m->get_marker_name()=~ /^ctg/) {
		    $count++;
		}
	    }
	    print $TEMP "$c\t$count\n";

	}
    }

    else {
	open(my $TEMP, '<', $temp_file) or die "Can't open $temp_file for reading: $!";
	while (<$TEMP>) {
	    chomp;
	    my ($c, $length) = split /\t/;
	    push @lengths, $length;
	}

    }
    return @lengths;
}

sub get_map_stats {
    my $self = shift;

    my $count = 0;
    for my $c (1..12) {
        $count += $self->get_marker_count($c);
    }

    return "$count contigs have been assigned to this map";
}

=head2 get_abstract

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

1;
