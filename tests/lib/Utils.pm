package Utils;

use Exporter qw( import );
@EXPORT_OK = qw( angle_permutation select_atom_data );

use strict;
use warnings;

use lib "../../lib/perl";
use CifParser qw( filter_atoms
                  obtain_atom_site );
use Data::Dumper;
sub select_atom_data
{
    my $attribute_selector = shift;
    my $data_selector = shift;
    my @cif = @_;

    # Parses selector argument from string  to proper array.
    my %attribute_selector = ( map { $_->[0] => [ split( ",", @$_[1] ) ] }
                               map { [ split( " ", $_ ) ] }
                               split( "&", $attribute_selector ) );
    my @data_selector = split( ",", $data_selector );

    # Selects atoms for further analysis.
    my @selected_atom_data =
	@{ CifParser::select_atom_data(
	       \@data_selector,
	       &filter_atoms(
		   \%attribute_selector,
		   &obtain_atom_site( @_ ) ) ) };

    return \@selected_atom_data;
}

sub angle_permutation {
    my %angle = @_;
}

1;
