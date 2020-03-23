package pf::config::builder::filter_engine;

=head1 NAME

pf::config::builder::filter_engine - Scoped Filter Engines builder

=cut

=head1 DESCRIPTION

Builds scoped filter engines from a pf::IniFiles

=cut

use strict;
use warnings;
use pf::log;
use List::MoreUtils qw(uniq);
use pf::factory::condition::access_filter;
use pf::filter;
use pf::util qw(expand_ordered_array);
use pf::action_spec;
use pf::factory::condition;
use pf::filter_engine;
use pf::condition_parser qw(parse_condition_string);
use base qw(pf::config::builder);

=head2 cleanupBuildData

Merge all conditions and filters to build the scoped filter engines

=cut

sub cleanupBuildData { 
    my ($self, $buildData) = @_;
    while ( my ( $scope, $filters ) = each %{ $buildData->{scopes} } ) {
        $buildData->{entries}{$scope} =
          pf::filter_engine->new( { filters => $filters } );
    }
}

=head2 buildEntry

Preprocess a rule

=cut

sub buildEntry {
    my ($self, $buildData, $id, $entry) = @_;
    my $logger = get_logger();
    $logger->info("Processing rule '$id'");
    my ($conditions, $err) = parse_condition_string($entry->{condition});
    unless ( defined $conditions ) {
        $self->_error($buildData, $id, "Error building rule", $err->{highlighted_error});
        return;
    }
    my $scopes = $entry->{scopes};
    unless (defined $scopes) {
        $self->_error($buildData, $id, "Error building rule", "no scopes defined");
        return;
    }
    $entry->{scopes} = $scopes = [split(/\s*,\s*/, $scopes)];
    $entry->{id} = $id;
    expand_ordered_array($entry, 'actions', 'action');
    $entry->{actions} = [
        map {
            my ( $err, $spec ) = pf::action_spec::parse_action_spec($_);
            $err ? () : ($spec)
        } @{ $entry->{actions} }
    ];
    $self->buildFilter($buildData, $conditions, $entry);
    return undef;
}

=head2 _error

Record and log an error

=cut

sub _error {
    my ($self, $build_data, $rule, $msg, $add_info) = @_;
    my $long_msg = $msg. (defined($add_info) ? " : $add_info" : '');
    $long_msg .= "\n" unless $long_msg =~ /\n\z/s;
    get_logger->error($long_msg);
    push @{$build_data->{errors}}, {rule => $rule, message => $long_msg};
}

=head2 buildFilter

build a filter

=cut

sub buildFilter {
    my ($self, $build_data, $parsed_conditions, $data) = @_;
    my $condition = eval { $self->buildCondition($build_data, $parsed_conditions) };
    if ($condition) {
        for my $scope (@{$data->{scopes}}) {
            push @{$build_data->{scopes}{$scope}}, pf::filter->new({
                answer    => $data,
                condition => $condition,
            });
        }
    } else {
        $self->_error($build_data, $data->{_rule}, "Error building rule", $@)
    }

}

our %LOGICAL_OPS = (
    AND => 'pf::condition::all',
    OR  => 'pf::condition::any'
);

our %BINARY_OP = (
    "==" => 'pf::condition::equals',
    "!=" => 'pf::condition::not_equals',
    "=~" => 'pf::condition::regex',
    "!~" => 'pf::condition::regex_not',
    ">"  => 'pf::condition::greater',
    ">=" => 'pf::condition::greater_equals',
    "<"  => 'pf::condition::lower',
    "<=" => 'pf::condition::lower_equals',
);

our %FUNC_OPS = (
    'includes'               => 'pf::condition::includes',
    'contains'               => 'pf::condition::matches',
    'not_contains'           => 'pf::condition::not_matches',
    'defined'                => 'pf::condition::is_defined',
    'not_defined'            => 'pf::condition::not_defined',
    'date_is_before'         => 'pf::condition::date_before',
    'date_is_after'          => 'pf::condition::date_after',
    'fingerbank_device_is_a' => 'pf::condition::fingerbank::device_is_a',
);

=head2 buildCondition

build a condition

=cut

sub buildCondition {
    my ($self, $build_data, $ast) = @_;
    if (ref $ast) {
        local $_;
        my ($op, @rest) = @$ast;
        if ($op eq 'NOT' ) {
            return pf::condition::not->new(
                {
                    condition => $self->buildCondition( $build_data, @rest)
                }
            );
        }

        if (exists $LOGICAL_OPS{$op}) {
            if (@rest == 1) {
                return $self->buildCondition( $build_data, @rest);
            }
            return $LOGICAL_OPS{$op}->new({conditions => [map { $self->buildCondition($build_data, $_) } @rest]});
        }

        if (exists $BINARY_OP{$op}) {
            my ($key, $val) = @rest;
            my $sub_condition = $BINARY_OP{$op}->new(value => $val);
            return pf::condition::key->new({
                key => $key,
                condition => $sub_condition,
            });
        }

        if ($op eq 'FUNC') {
            return $self->buildFuncCondition($build_data, @rest);
        }

        return $self->buildBinaryCondition($build_data, @rest);
    }

    die "condition '$ast' defined\n";
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2020 Inverse inc.

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
