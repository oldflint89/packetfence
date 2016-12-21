package pfconfig::namespaces::resource::passthroughs;

=head1 NAME

pfconfig::namespaces::resource::passthroughs

=cut

=head1 DESCRIPTION

pfconfig::namespaces::resource::passthroughs

=cut

use strict;
use warnings;

use base 'pfconfig::namespaces::resource';

sub init {
    my ($self) = @_;
    $self->{config}         = $self->{cache}->get_cache('config::Pf');
    $self->{authentication_sources} = $self->{cache}->get_cache('resource::authentication_sources');
}

sub build {
    my ($self) = @_;

    my @all_passthroughs = (
        @{$self->{config}->{trapping}->{passthroughs}}, 
        map{
            $_->isa("pf::Authentication::Source::OAuthSource") 
                ? split(/\s*,\s*/, $_->{domains})
                : () 
        } @{$self->{authentication_sources}},
    );

    my %passthroughs = (
        normal => {}, 
        wildcard => {},  
    );
    foreach my $passthrough (@all_passthroughs) {
        my ($domain, $ports) = $self->_new_passthrough($passthrough);
        my $ns = "normal";
        if($domain =~ /\*\.(.*)/) {
            $ns = "wildcard";
            $domain = $1;
        }
        if(defined($passthroughs{$ns}{$domain})) {
            push @{$passthroughs{$ns}{$domain}}, @$ports;
        }
        else {
            $passthroughs{$ns}{$domain} = $ports;
        }
    }

    return \%passthroughs;
}

sub _new_passthrough {
    my ($self, $passthrough) = @_;

    if($passthrough =~ /(.*):([0-9]+)/) {
        return ($1, [$2]);
    }
    else {
        return ($passthrough, [80, 443]);
    }
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:

