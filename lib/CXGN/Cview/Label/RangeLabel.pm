
use strict;

use CXGN::Cview::Label;

package CXGN::Cview::Label::RangeLabel;

use base qw / CXGN::Cview::Label /;


=head2 function new()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # set some interesting defaults
    #
    $self->set_align_side("left");
    $self->set_label_spacer(20);
    $self->set_vertical_stacking_spacing(0);

    return $self;
}


=head2 function render_line()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub render_line {
    my $self = shift;
    my $image = shift;

    my $line_color = $image->colorResolve($self->get_line_color());

    $image -> setAntiAliased($line_color);
    my $width = 0;

    # calculate the point that the line should connect to 
    # on the label
    #
    my ($x, $y, $a, $b) = $self->get_enclosing_rect();
    my ($connection_x, $connection_y) = (0, 0);

    if ($self->get_align_side() eq "right") { 

	$connection_x = $a;
	$connection_y = $y + CXGN::Cview::ImageObject::round(($b - $y ) /2);

	my $horizontal = ($self->get_reference_point())[0]-$self->get_stacking_level()*$self->get_stacking_height();

 	$image->line($connection_x, $connection_y,  
  		     $horizontal, ($self->get_reference_point())[1], 
  		     $line_color 
 		     #$image->colorResolve(255,0,0)
  		     );

	# draw the lines for the northern range
	#
	$image->line($horizontal, $self->get_north_position(),
		     $horizontal, $self->get_south_position(), $line_color);

	# northern tick
	#
	$image->line($horizontal, $self->get_north_position(), $horizontal+$self->get_stacking_level()* $self->get_stacking_height(), $self->get_north_position(), $line_color);

	# draw the line for the southern range tick
	#
	$image->line($horizontal, $self->get_south_position(), $horizontal + $self->get_stacking_level()*$self->get_stacking_height(), $self->get_south_position(), $line_color);

    }
    if ($self->get_align_side() eq "left") { 
	
	$connection_x = $x;
	$connection_y = $y + CXGN::Cview::ImageObject::round(($b - $y)/2);

	my $horizontal = ($self->get_reference_point())[0]+$self->get_stacking_level()*$self->get_stacking_height();

	# draw the line from the text box to the chromosome
	#
	$image->line($connection_x, $connection_y,  
		     $horizontal, ($self->get_reference_point())[1], $line_color );

	# draw the line of the region
	#
	$image->line($horizontal, $self->get_north_position(), $horizontal, $self->get_south_position(), $line_color);

	# draw the lines for the northern range
	#
	$image->line($horizontal, $self->get_north_position(), $horizontal-$self->get_stacking_level()*$self->get_stacking_height(), $self->get_north_position(), $line_color);

	# draw the line for the southern range
	#
	$image->line($horizontal, $self->get_south_position(), $horizontal-$self->get_stacking_level()*$self->get_stacking_height(), $self->get_south_position(), $line_color);
    }
    #$image->rectangle($self->get_enclosing_rect(), $line_color);
}

=head2 function get_stacking_height

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_stacking_height { 
    my $self=shift;
    return $self->{stacking_height} || 3;
}

=head2 function set_stacking_height

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_stacking_height { 
    my $self=shift;
    $self->{stacking_height}=shift;
}



1;
