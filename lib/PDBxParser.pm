package PDBxParser;

use strict;
use warnings;

use Exporter qw( import );
our @EXPORT_OK = qw( create_pdbx_entry
                     filter
                     filter_by_unique_residue_key
                     identify_unique_residues
                     mark_selection
                     pdbx_loop_unique
                     pdbx_loop_to_csv
                     obtain_atom_site
                     obtain_pdbx_line
                     obtain_pdbx_loop
                     to_pdbx
                     unique_residue_key );

use List::MoreUtils qw( any
                        uniq );
use Version qw( $VERSION );

our $VERSION = $VERSION;

# --------------------------------- PDBx parser ------------------------------- #

#
# Obtains pdbx lines for a specified items.
# Input:
#     $pdbx_file - PDBx file path;
#     $items - list of desired items.
# Output:
#     %pdbx_line_data - hash of item values.
#

sub obtain_pdbx_line
{
    my ( $pdbx_file, $items ) = @_;

    my %pdbx_line_data;
    my %current_line_data;
    my $item_regexp = join q{|}, @{ $items };

    local $/ = '';
    local @ARGV = ( $pdbx_file );
    while( <> ) {
        my %single_line_matches = ( m/($item_regexp)\s+(?!;)(\S.+\S)/gx );
        my %multi_line_matches = ( m/($item_regexp)\s+(\n;[^;]+;)/gx );
        %current_line_data = ( %single_line_matches, %multi_line_matches );
    }

    for my $key ( sort { $a cmp $b } keys %current_line_data ) {
        my ( $category, $attribute ) = split '\\.', $key;
        $pdbx_line_data{$category}{$attribute} =
            $current_line_data{$key};
    }

    return \%pdbx_line_data;
}

#
# Obtains pdbx loops for a specified categories.
# Input:
#     $pdbx_file - PDBx file path;
#     $categories - list of specified categories.
# Output:
#     %pdbx_loop_data - data structure for loop data.
#

sub obtain_pdbx_loop
{
    my ( $pdbx_file, $categories ) = @_;

    my @categories;
    my @attributes;
    my @data; # Will be used for storing atom data temporarily.

    my $category_regexp = join q{|}, @{ $categories };
    my $is_reading_lines = 0; # Starts/stops reading lines at certain flags.

    local @ARGV = ( $pdbx_file );
    while( <> ) {
        if( /($category_regexp)[.](.+)\n$/x ) {
            if( ! @categories || $categories[-1] ne $1 ) {
                push @categories, $1;
                push @attributes, [];
                push @data, [];
            }
            push @{ $attributes[-1] }, split q{ }, $2;
            $is_reading_lines = 1;
        } elsif( $is_reading_lines == 1 && /^_|loop_|#/ ) {
            if( $#categories eq $#{ $categories } ) { last; }
            $is_reading_lines = 0;
        } elsif( $is_reading_lines == 1 ) {
            push @{ $data[-1] }, split q{ }, $_;
        }
    }

    # Generates hash from three lists.
    my %pdbx_loop_data;
    for( my $i = 0; $i <= $#categories; $i++ ) {
        $pdbx_loop_data{$categories[$i]}{'attributes'} = $attributes[$i];
        $pdbx_loop_data{$categories[$i]}{'data'} = $data[$i];
    }

    return \%pdbx_loop_data;
}

#
# Takes PDBx loop and converts it to hash of hashes where the first key is
# unique.
# Input:
#     $pdbx_loop_data - data structure (from obtain_pdbx_loop);
#     $unique_keys - combination of attribute data that serves as unique key.
#     Ex.: [ 'id' ]
# Output:
#     %pdbx_loop_unique - special data structure.
#     Ex.: { 1 => { 'group_id' => 'ATOM',
#                   'id'       => 1,
#                   ... } }

sub pdbx_loop_unique
{
    my ( $pdbx_loop_data, $unique_keys ) = @_;

    $unique_keys //= [ 'id' ];

    my $category = [keys %{ $pdbx_loop_data }]->[0];

    my @attributes = @{ $pdbx_loop_data->{$category}{'attributes'} };
    my @data = @{ $pdbx_loop_data->{$category}{'data'} };

    # Creates special data structure.
    my %pdbx_loop_unique;
    my @data_row;
    my %data_row;

    my $attribute_count = scalar @attributes;
    my $data_count = scalar @data;

    # Determines the positions of unique keys in attribute list.
    my @attribute_pos;
    for my $unique_key ( @{ $unique_keys } ) {
        for( my $i = 0; $i <= $#attributes; $i++ ) {
            if( $attributes[$i] eq $unique_key ) {
                push @attribute_pos, $i;
                last;
            }
        }
    }

    for( my $pos = 0; $pos < $data_count - 1; $pos += $attribute_count ) {
        @data_row =
            @{ data[$pos..$pos+$attribute_count-1] };
        %data_row = ();
        for( my $col = 0; $col <= $#data_row; $col++ ) {
            $data_row{$attributes[$col]} = $data_row[$col];
        }

        my $unique_key = join q{,}, map { $data_row[$_] } @attribute_pos;
        if( ! exists $pdbx_loop_unique{$unique_key} ) {
            $pdbx_loop_unique{$unique_key} = { %data_row };
        } else {
            die 'Unique key supposed to be unique.';
        }
    }

    return \%pdbx_loop_unique;
}

#
# From PDBx file, obtains data only from _atom_site category and outputs special
# data structure that represents atom data.
# Input:
#     $pdbx_file - PDBx file.
# Output:
#     %atom_site - special data structure.
#     Ex.: { 1 => { 'group_id' => 'ATOM',
#                   'id'       => 1,
#                   ... } }
#

sub obtain_atom_site
{
    my ( $pdbx_file ) = @_;

    return pdbx_loop_unique( obtain_pdbx_loop( $pdbx_file, [ '_atom_site' ] ) );

}

#
# Filters atom data structure according to specified attributes with include,
# exclude options.
# Input:
#     $args->{'atom_site'} - atom data structure;
#     $args->{'include'} - attribute selector that includes atom data structure.
#     Ex.:
#         { 'label_atom_id' => [ 'N', 'CA', 'CB', 'CD' ],
#           'label_comp_id' => [ 'A' ] };
#     $args->{'exclude'} - attribute selector that excludes atom data structure.
#     Selector data structure is the same as $args->{include};
#     $args->{'is_list'} - makes array instead of array of arrays;
#     $args->{'data_with_id'} - takes atom data structure and treats it as a
#     value and atom id - as a key;
#     $args->{'group_id'} - assigns the value of described group id.
# Output:
#     \%filtered_atoms- filtered atom data structure;
#

sub filter
{
    my ( $args ) = @_;
    my $atom_site = $args->{'atom_site'};
    my $include = $args->{'include'};
    my $exclude = $args->{'exclude'};
    my $data = $args->{'data'};
    my $is_list = $args->{'is_list'};
    my $data_with_id = $args->{'data_with_id'};
    my $group_id = $args->{'group_id'};

    if( ! defined $atom_site ) { die 'No PDBx data structure was loaded '; }

    # Iterates through each atom in $atom_site and checks if atom specifiers
    # match up.
    my %filtered_atoms;

    # First, filters atoms that are described in $include specifier.
    if( defined $include && %{ $include } ) {
        for my $atom_id ( keys %{ $atom_site } ) {
            my $match_counter = 0; # Tracks if all matches occured.
            for my $attribute ( keys %{ $include } ) {
                if( exists $atom_site->{$atom_id}{$attribute} &&
                    any { $atom_site->{$atom_id}{$attribute} eq $_ }
                       @{ $include->{$attribute} } ) {
                    $match_counter += 1;
                } else {
                    last; # Terminates early if no match is found in specifier.
                }
            }
            if( $match_counter == scalar keys %{ $include } ) {
                $filtered_atoms{$atom_id} = $atom_site->{$atom_id};
            }
        }
    } else {
        %filtered_atoms = %{ $atom_site };
    }

    # Then filters out atoms that are in $exclude specifier.
    if( defined $exclude && %{ $exclude } ) {
        for my $atom_id ( keys %filtered_atoms ) {
            for my $attribute ( keys %{ $exclude } ) {
                if( exists $atom_site->{$atom_id}{$attribute} &&
                    any { $atom_site->{$atom_id}{$attribute} eq $_ }
                       @{ $exclude->{$attribute} } ) {
                    delete $filtered_atoms{$atom_id};
                    last;
                }
            }
        }
    }

    # TODO: again another iteration through atom data structure. Should look into
    # it how to reduce the quantity of iterations.
    if( defined $group_id ) {
        for my $atom_id ( keys %filtered_atoms ) {
            $filtered_atoms{$atom_id}{'[local]_selection_group'} = $group_id;
        }
    }

    # Extracts specific data, if defined.
    if( defined $data && @{ $data } ) {
        # Simply iterates through $atom_site keys and extracts data using data
        # specifier.
        my @atom_data;
        if( defined $data_with_id && $data_with_id ) {
            my %atom_data_with_id;

            # Simply iterates through $atom_site keys and extracts data using
            # data specifier and is asigned to atom id.
            for my $atom_id ( sort { $a <=> $b } keys %{ $atom_site } ) {
                $atom_data_with_id{$atom_id} =
                    [ map { $atom_site->{$atom_id}{$_} } @{ $data } ];
            }
            return \%atom_data_with_id;
        } else {
            for my $atom_id ( sort { $a <=> $b } keys %filtered_atoms ) {
                if( defined $is_list && $is_list ) {
                    push @atom_data,
                         map { $filtered_atoms{$atom_id}{$_} } @{ $data };
                } else {
                    push @atom_data,
                         [ map { $filtered_atoms{$atom_id}{$_} } @{ $data } ];
                }
            }
            return \@atom_data;
        }
    }

    return \%filtered_atoms;
}

#
# Adds T (target), S (surrounding or selected), I (ignored) char to
# '[local]_selection_state' attribute data.
# Input:
#     $atom_site - atom site data structure;
#     $options{'target'} - list of ids of the target atom;
#     $options{'select'} - list of ids of the selected atom;
#     $options{'ignore'} - list of ids of the ignored atom.
# Output:
#     adds markers to specified attribute field.
#

sub mark_selection
{
    my ( $atom_site, $options ) = @_;

    my ( $target_atom_ids, $selected_atom_ids ) =
        ( $options->{'target'}, $options->{'select'}, );

    for my $atom_id ( keys %{ $atom_site } ) {
        if( any { $atom_id eq $_  } @{ $target_atom_ids } ) {
            $atom_site->{$atom_id}{'[local]_selection_state'} = 'T';
        } elsif( any { $atom_id eq $_  } @{ $selected_atom_ids } ) {
            $atom_site->{$atom_id}{'[local]_selection_state'} = 'S';
        } else {
            $atom_site->{$atom_id}{'[local]_selection_state'} = 'I';
        }
    }

    return;
}

#
# Filters atom site data structure by unique residue key.
# Input:
#     $atom_site - atom data structure.
#     $unique_residue_key - a composite key that identifies residue uniquely.
#     Ex.: '18,A,1,.'.
# Output:
#     %filtered_atoms - filtered atom data structure.
#

sub filter_by_unique_residue_key
{
    my ( $atom_site, $unique_residue_key ) = @_;
    my ( $residue_id, $residue_chain, $residue_entity, $residue_alt ) =
        split /,/sxm, $unique_residue_key;
    my $filtered_atoms = filter( { 'atom_site' => $atom_site,
                                   'include' =>
                                   { 'label_seq_id' => [ $residue_id ],
                                     'label_asym_id' => [ $residue_chain ],
                                     'label_entity_id' => [ $residue_entity ],
                                     'label_alt_id' => [ $residue_alt ] } } );
    return $filtered_atoms;
}

#
# Create unique residue key that consists of '_atom_site.label_seq_id',
# '_atom_site.label_asym_id', '_atom_site.label_entity_id' and
# '_atom_site.label_alt_id'.
# Input:
#     $atom - atom data structure.
# Output:
#     $unique_residue_key - unique residue key.
#

sub unique_residue_key
{
    my ( $atom ) = @_;
    return join q{,},
           map { $atom->{$_} }
               ( 'label_seq_id',
                 'label_asym_id',
                 'label_entity_id',
                 'label_alt_id', );
}

#
# Identifies unique residues and generates hash of lists of unique residues and
# atom ids that belong to them.
# Input:
#     $atom_site - atom data structure.
# Output:
#     %unique_alt_residues - atom ids that belong to unique residues.
#

sub identify_unique_residues
{
    my ( $atom_site ) = @_;

    my %unique_residues;
    my %unique_alt_residues;

    # Separates main atom ids (with alt_id of ".") from alternative atom ids.
    for my $atom_id ( keys %{ $atom_site } ) {
        my $unique_residue_key = unique_residue_key( $atom_site->{$atom_id} );
        my ( $residue_id, $chain, $entity_id, $alt_id ) =
            split /,/sxm, $unique_residue_key;

        if( $alt_id eq q{.} ) {
            if( exists $unique_residues{$unique_residue_key} ) {
                push @{ $unique_residues{$unique_residue_key} }, $atom_id;
            } else {
                $unique_residues{$unique_residue_key} = [ $atom_id ];
            }
        } else {
            if( exists $unique_alt_residues{$unique_residue_key} ) {
                push @{ $unique_alt_residues{$unique_residue_key} }, $atom_id;
            } else {
                $unique_alt_residues{$unique_residue_key} = [ $atom_id ];
            }
        }
    }

    # Joins main and alt residues.
    for my $unique_alt_residue_key ( keys %unique_alt_residues ) {
        my ( $residue_id, $chain, $entity_id, $alt_id ) =
            split /,/sxm, $unique_alt_residue_key;
        # my @unique_residues = grep {} keys
        # for my $unique_alt_residue ( keys %unique_alt_residues ) {

        # }
    }
}

#
# Creates PDBx entry.
# Input:
#     $args - hash of all necessary attributes with corresponding values;
# Output:
#     PDBx STDOUT
#

sub create_pdbx_entry
{
    my ( $args ) = @_;
    my $atom_site = $args->{'atom_site'};
    my $atom_id = $args->{'id'};
    my $type_symbol = $args->{'type_symbol'};
    my $label_atom_id = $args->{'label_atom_id'};
    my $label_alt_id = $args->{'label_alt_id'};
    $label_alt_id //= q{.};
    my $label_comp_id = $args->{'label_comp_id'};
    my $label_asym_id = $args->{'label_asym_id'};
    my $label_entity_id = $args->{'label_entity_id'};
    $label_entity_id //= q{?};
    my $label_seq_id = $args->{'label_seq_id'};
    my $cartn_x = $args->{'cartn_x'};
    my $cartn_y = $args->{'cartn_y'};
    my $cartn_z = $args->{'cartn_z'};

    $atom_site->{$atom_id}{'group_PDB'} = 'ATOM';
    $atom_site->{$atom_id}{'id'} = $atom_id;
    $atom_site->{$atom_id}{'type_symbol'} = $type_symbol;
    $atom_site->{$atom_id}{'label_atom_id'} = $label_atom_id;
    $atom_site->{$atom_id}{'label_alt_id'} = $label_alt_id;
    $atom_site->{$atom_id}{'label_comp_id'} = $label_comp_id;
    $atom_site->{$atom_id}{'label_asym_id'} = $label_asym_id;
    $atom_site->{$atom_id}{'label_entity_id'} = $label_entity_id;
    $atom_site->{$atom_id}{'label_seq_id'} = $label_seq_id;
    $atom_site->{$atom_id}{'Cartn_x'} = $cartn_x;
    $atom_site->{$atom_id}{'Cartn_y'} = $cartn_y;
    $atom_site->{$atom_id}{'Cartn_z'} = $cartn_z;

    return;
}

# --------------------------- Data structure to STDOUT ------------------------ #

#
# Converts atom site data structure to PDBx.
# Input:
#     $args->{data_name} - data name of the PDBx;
#     $args->{pdbx_lines} - data structure of PDBx lines;
#     $args->{pdbx_loops} - data structure of pdbx_loops;
#     $args->{atom_site} - atom site data structure;
#     $args->{atom_attributes} - attribute list that should be included in the
#     output;
#     $args->{add_atom_attributes} - add list of attributes to existing data
#     structure;
#     $args->{fh} - file handler.
# Output:
#     PDBx STDOUT.
#

sub to_pdbx
{
    my ( $args ) = @_;
    my $data_name = $args->{'data_name'};
    my $pdbx_lines = $args->{'pdbx_lines'};
    my $pdbx_loops = $args->{'pdbx_loops'};
    my $atom_site = $args->{'atom_site'};
    my $atom_attributes = $args->{'atom_attributes'};
    my $add_atom_attributes = $args->{'add_atom_attributes'};
    my $fh = $args->{'fh'};

    $data_name //= 'testing';
    $fh //= \*STDOUT;

    print {$fh} "data_$data_name\n#\n";

    # Prints out pdbx lines if they are present.
    if( defined $pdbx_lines ) {
    for my $category  ( sort { $a cmp $b } keys %{ $pdbx_lines } ) {
    for my $attribute ( sort { $a cmp $b } keys %{ $pdbx_lines->{$category} } ) {
        printf {$fh} "%s.%s %s\n", $category, $attribute,
               $pdbx_lines->{$category}{$attribute};
    } print {$fh} "#\n"; } }

    # Prints out atom site structure if they are present.
    if( defined $atom_site ) {
        $atom_attributes //= [ 'group_PDB',
                               'id',
                               'type_symbol',
                               'label_atom_id',
                               'label_alt_id',
                               'label_comp_id',
                               'label_asym_id',
                               'label_entity_id',
                               'label_seq_id',
                               'Cartn_x',
                               'Cartn_y',
                               'Cartn_z' ];

        if( defined $add_atom_attributes ) {
            push @{ $atom_attributes }, @{ $add_atom_attributes };
        }

        print {$fh} "loop_\n";

        for my $attribute ( @{ $atom_attributes } ) {
            $attribute eq $atom_attributes->[-1] ?
                print {$fh} "_atom_site.$attribute":
                print {$fh} "_atom_site.$attribute\n";
        }

        for my $id ( sort { $a <=> $b } keys %{ $atom_site } ) {
        for( my $i = 0; $i <= $#{ $atom_attributes }; $i++ ) {
            if( $i % ( $#{ $atom_attributes } + 1) != 0 ) {
                if( exists $atom_site->{$id}{$atom_attributes->[$i]} ) {
                    print {$fh} q{ }, $atom_site->{$id}{$atom_attributes->[$i]};
                } else {
                    print {$fh} q{ ?};
                }
            } else {
                if( exists $atom_site->{$id}{$atom_attributes->[$i]} ) {
                    print {$fh} "\n", $atom_site->{$id}{$atom_attributes->[$i]};
                } else {
                    print {$fh} "\n";
                }
            }
        } }
        print {$fh} "\n#\n";
    }

    # Prints out pdbx loops if they are present.
    if( defined $pdbx_loops ) {
        for my $category ( sort keys %{ $pdbx_loops } ) {
            print {$fh} "loop_\n";

            foreach( @{ $pdbx_loops->{$category}{'attributes'} } ) {
                print {$fh} "$category.$_\n";
            }
            my $attribute_array_length =
                $#{ $pdbx_loops->{$category}{'attributes'} };
            my $data_array_length =
                $#{ $pdbx_loops->{$category}{'data'} };
            for( my $i = 0;
                 $i <= $data_array_length;
                 $i += $attribute_array_length + 1 ){
                print {$fh} join( q{ }, @{ $pdbx_loops->{$category}{'data'} }
                                  [$i..$i+$attribute_array_length] ), "\n" ;
            }

            print {$fh} "#\n";
        }
    }

    return;
}

#
# Converts pdbx loop data structure to csv table.
# Input:
#     $pdbx_loops - data structure of pdbx_loops;
#     $attributes - columns that should be displayed.
# Output:
#     csv STDOUT
#

sub pdbx_loop_to_csv
{
    my ( $pdbx_loop, $attributes ) = @_;

    $attributes //= $pdbx_loop->{'attributes'};

    if( defined $pdbx_loop ) {
        print {*STDOUT} join( ',', @{ $attributes } ), "\n";
    }

    my $attribute_array_length =
        $#{ $pdbx_loop->{'attributes'} };
    my $data_array_length =
        $#{ $pdbx_loop->{'data'} };

    for( my $i = 0; $i <= $data_array_length; $i += $attribute_array_length + 1){
        print {*STDOUT} join( q{,}, @{ $pdbx_loop->{'data'} }
                                    [ $i..$i+$attribute_array_length ] ), "\n" ;
    }

    return;
}

1;
