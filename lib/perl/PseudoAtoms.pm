package PseudoAtoms;

use strict;
use warnings;

use Exporter qw( import );
our @EXPORT_OK = qw( generate_pseudo );

use lib qw( ./ );
use CifParser qw( filter_atoms select_atom_data );
use Combinatorics qw( permutation );
use LinearAlgebra qw( evaluate_matrix matrix_product );
use LoadParams qw( rotatable_bonds );
use Measure qw( all_dihedral );
use SidechainModels qw( rotation_only );
use Data::Dumper;

my $parameter_file = "../../parameters/rotatable_bonds.csv";

# --------------------------- Generation of pseudo-atoms ---------------------- #

#
# Parameters.
#

my %ROTATABLE_BONDS = %{ rotatable_bonds( $parameter_file ) };

#
# Generates pseudo-atoms from side chain models that are written in equation
# form.
# Input  (3 arg): atom site data structure, hash of hashes for selecting atoms
#                 by attributes and hash of arrays that describe possible values
#                 of dihedral angles.
# Output (1 arg): atom site data structure with additional pseudo-atoms.
#
# Example of hash of arrays for describing dihedral angles.
# { "chi0" => [ 0, pi, 1.5 * $pi, 2 * $pi ],
#   "chi1" => [ 0, 2 * $pi ] }
#

sub generate_pseudo
{
    my ( $atom_site, $atom_selector, $defined_angles ) = @_;

    # Determines last id from set of atoms. It will be used for attaching id's
    # to generated pseudo-atoms.
    my $atom_ids = select_atom_data( [ "id" ], $atom_site );
    my @sorted_atom_ids = sort { $a <=> $b } map { $_->[0] } @{ $atom_ids };
    my $last_atom_id = $sorted_atom_ids[-1];

    # Generates model for selected atoms.
    $atom_site = rotation_only( $atom_site );

    my $target_atom_site = filter_atoms( $atom_selector, $atom_site );
    my $target_atom_ids = select_atom_data( [ "id" ], $target_atom_site );
    my @target_atom_ids = map { $_->[0] } @{ $target_atom_ids };

    for my $id ( @target_atom_ids ) {
	my @angle_names = sort( { $a cmp $b } keys %{ $defined_angles } );
	my @angle_values = (); # Temprorary sets of angles that angle
	                       # permutations will be generated from.

	# Calculates current dihedral angles of rotatable bonds. Will be used
	# for reseting dihedral angles to 0 degree angle.
	my $current_resi_id = $atom_site->{"data"}{"$id"}{"label_seq_id"};
	my %current_angles =
	    %{ all_dihedral( filter_atoms(
				 { "label_seq_id" => [ $current_resi_id ] },
				 $atom_site ) ) };

	# Iterates through combinations of angles and evaluates conformational
	# model.
	for my $angle_name ( @angle_names ) {
	    push( @angle_values,
		  [ map
		    { $_ - $current_angles{"$current_resi_id"}{"$angle_name"} }
		    @{ $defined_angles->{"$angle_name"} } ] );
	}

	my $angle_set_size = scalar( @angle_names );

	my %angle_values;
	my $conf_model = $atom_site->{"data"}{"$id"}{"conformation"};

	my $transf_atom_coord;

	for my $angle_comb (
	    @{ permutation( $angle_set_size, [], \@angle_values ) } ) {
	    %angle_values =
		map { $angle_names[$_], $angle_comb->[$_] } 0..$#angle_names;
	    # # TODO: get rid of matrix_product function.
	    $transf_atom_coord =
	    	evaluate_matrix( \%angle_values, matrix_product( $conf_model ) );
	    # Adds generated pseudo-atom to $atom_site.
	    $last_atom_id++;
	    %{ $atom_site->{"data"}{$last_atom_id} } =
	    	%{ $atom_site->{"data"}{$id} };
	    # Overwrites atom id.
	    $atom_site->{"data"}{$last_atom_id}{"id"} =
	    	$last_atom_id;
	    # Overwrites exsisting coordinate values.
	    $atom_site->{"data"}{$last_atom_id}{"Cartn_x"} =
	    	$transf_atom_coord->[0][0];
	    $atom_site->{"data"}{$last_atom_id}{"Cartn_y"} =
	    	$transf_atom_coord->[1][0];
	    $atom_site->{"data"}{$last_atom_id}{"Cartn_z"} =
	    	$transf_atom_coord->[2][0];
	    # Adds information about used dihedral angles.
	    $atom_site->{"data"}{$last_atom_id}{"dihedral_angles"} =
	    	\%angle_values;
	    # Adds additional pseudo-atom flag for future filtering.
	    $atom_site->{"data"}{$last_atom_id}{"is_pseudo_atom"} = 1;
	}
    }

    return $atom_site;
}

1;
