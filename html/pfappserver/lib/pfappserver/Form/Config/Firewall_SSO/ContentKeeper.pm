package pfappserver::Form::Config::Firewall_SSO::ContentKeeper;

=head1 NAME

pfappserver::Form::Config::Firewall_SSO::ContentKeeper - Web form to add a Content Keeperd firewall

=head1 DESCRIPTION

Form definition to create or update a ContentKeeper firewall.

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::Firewall_SSO';
with 'pfappserver::Base::Form::Role::Help';

use pf::config;
use pf::util;
use File::Find qw(find);

has_field '+port' =>
  (
   default => 1813,
  );
has_field 'type' =>
  (
   type => 'Hidden',
   default => 'ContentKeeper',
  );

has_block definition =>
  (
   render_list => [ qw(id type password port categories networks cache_updates cache_timeout username_format default_realm act_on_accounting_stop) ],
  );

=head1 COPYRIGHT

Copyright (C) 2005-2024 Inverse inc.

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

__PACKAGE__->meta->make_immutable unless $ENV{"PF_SKIP_MAKE_IMMUTABLE"};

1;
