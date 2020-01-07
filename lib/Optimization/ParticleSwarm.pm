package ParticleSwarm;

use strict;
use warnings;

use Optimization::Particle;

# ------------------------- Constructors/Destructors -------------------------- #

sub new
{
    my ( $class, $parameters, $particle_num, $options ) = @_;
    my ( $seed ) = $options->{'seed'};

    $seed //= 23;

    srand( $seed );

    my $self = { 'particles' => undef,
                 'cost_function' => undef,
                 'optimal_value' => undef,
                 'optimal_parameters' => undef };
    for my $i ( 0..$particle_num-1 ) {
        my $id = $i + 1;
        my $particle = Particle->new( $parameters );
        if( $particle->no_values ) {
            for my $name ( keys %{ $particle->{'parameters'} } ) {
                my $parameter = $particle->{'parameters'}{$name};
                my $min = $parameter->min;
                my $max = $parameter->max;
                $parameter->value( $min + rand( $max - $min ) );
            }
        }
        $self->{'particles'}{$id} = $particle;
    }

    return bless $self, $class;
}

# ----------------------------- Setters/Getters ------------------------------- #

sub set_cost_function
{
    my ( $self, $cost_function ) = @_;
    $self->{'cost_function'} = $cost_function;
}

sub optimal_value
{
    my ( $self ) = @_;
    return $self->{'optimal_value'};
}

sub optimal_parameters
{
    my ( $self ) = @_;
    return $self->{'optimal_parameters'};
}

# --------------------------------- Methods ----------------------------------- #

sub optimize
{
    my ( $self, $iterations, $options ) = @_;

    my $cost_function = $self->{'cost_function'};
    if( ! defined $cost_function ) {
        die "'cost_function' value for Optimization::ParticleSwarm is " .
            "mandatory.\n";
    }

    my $particles = $self->{'particles'};
    for my $i ( 0..$iterations-1 ) {
        for my $id ( sort keys %{ $particles } ) {
            my $particle = $particles->{$id};
            my $parameters = $particle->{'parameters'};

            if( ! defined $particle->speed ) {
                my %speed = ();
                for my $key ( keys %{ $parameters } ) {
                    $speed{$key} =
                        rand( 1 ) *
                        ( $parameters->{$key}->uniform() -
                          $parameters->{$key}->value );
                }
                $particle->speed( \%speed );
            }

            if( defined $particle->speed ) {
                for my $key ( keys %{ $parameters } ) {
                    my $parameter_value = $parameters->{$key}->value;
                    $parameters->{$key}->value(
                        $parameter_value + $particle->speed->{$key}
                    );
                }
            }

            $particle->value( $cost_function->( $parameters ) );

            if( ! defined $self->{'optimal_value'} ||
                $particle->value < $self->{'optimal_value'} ) {
                $self->{'optimal_value'} = $particle->value;
                $self->{'optimal_parameters'} = $parameters;
            }
        }

        # Sets speed for next iteration.
        for my $id ( keys %{ $particles } ) {
            my $particle = $particles->{$id};
            my $parameters = $particle->{'parameters'};
            my %updated_speed = ();
            for my $key ( keys %{ $parameters } ) {
                my $parameter = $parameters->{$key};
                my $optimal_parameter = $self->{'optimal_parameters'}{$key};
                $updated_speed{$key} =
                    $optimal_parameter->value-$parameter->value;
            }
            $particle->speed( \%updated_speed );
        }
    }
}

1;
