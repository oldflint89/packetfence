package pf::cmd::pf::service;
=head1 NAME

pf::cmd::pf::service add documentation

=head1 SYNOPSIS

 pfcmd service <service> [start|stop|restart|status|watch]

stop/stop/restart specified service
status returns PID of specified PF daemon or 0 if not running
watch acts as a service watcher which can send email/restart the services

Services managed by PacketFence:
  dhcpd            | dhcpd daemon
  httpd.webservices| Apache Webservices
  httpd.admin      | Apache Web admin
  httpd.portal     | Apache Captive Portal
  httpd.proxy      | Apache Proxy Interception
  pf               | all services that should be running based on your config
  pfdetect         | PF snort alert parser
  pfdhcplistener   | PF DHCP monitoring daemon
  pfdns            | DNS daemon
  pfmon            | PF ARP monitoring daemon
  pfsetvlan        | PF VLAN isolation daemon
  radiusd          | FreeRADIUS daemon
  snmptrapd        | SNMP trap receiver daemon
  snort            | Sourcefire Snort IDS
  suricata         | Suricata IDS

watch
Watch performs services checks to make sure that everything is fine. It's
behavior is controlled by servicewatch configuration parameters. watch is
typically best called from cron with something like:
*/5 * * * * /usr/local/pf/bin/pfcmd service pf watch

=head1 DESCRIPTION

pf::cmd::pf::service

=cut

use strict;
use warnings;
use base qw(pf::cmd);
use IO::Interactive qw(is_interactive);
use Term::ANSIColor;
our ($SERVICE_HEADER, $IS_INTERACTIVE);
our ($RESET_COLOR, $WARNING_COLOR, $ERROR_COLOR, $SUCCESS_COLOR);
use pf::log;
use pf::file_paths;
use pf::config;
use pf::util;
use pf::constants;
use pf::services;
use List::MoreUtils qw(part any true all);
use constant {
    JUST_MANAGED       => 1,
    INCLUDE_DEPENDS_ON => 2,
};
my $logger = get_logger();

our %ACTION_MAP = (
    status  => \&statusOfService,
    start   => \&startService,
    stop    => \&stopService,
    watch   => \&watchService,
    restart => \&restartService,
);

sub parseArgs {
    my ($self) = @_;
    my ($service, $action) = $self->args;
    return 0 unless defined $service && defined $action && exists $ACTION_MAP{$action};
    my @services;
    if ($service eq 'pf') {
        @services = @pf::services::ALL_SERVICES;
    }
    else {
        @services = ($service);
    }
    $self->{service}  = $service;
    $self->{services} = \@services;
    $self->{action}   = $action;
    return 1;
}

sub _run {
    my ($self) = @_;
    my $service = $self->{service};
    my $services = $self->{services};
    my $action = $self->{action};
    $SERVICE_HEADER ="service|command\n";
    $IS_INTERACTIVE = is_interactive();
    $RESET_COLOR =  $IS_INTERACTIVE ? color 'reset' : '';
    $WARNING_COLOR =  $IS_INTERACTIVE ? color $Config{advanced}{pfcmd_warning_color} : '';
    $ERROR_COLOR =  $IS_INTERACTIVE ? color $Config{advanced}{pfcmd_error_color} : '';
    $SUCCESS_COLOR =  $IS_INTERACTIVE ? color $Config{advanced}{pfcmd_success_color} : '';
    my $actionHandler;
    $action =~ /^(.*)$/;
    $action = $1;
    $actionHandler = $ACTION_MAP{$action};
    $service =~ /^(.*)$/;
    $service = $1;
    return $actionHandler->($service,@$services);
}

sub postPfStartService {
    my ($managers) = @_;
    my $count = true {$_->status ne '0'} @$managers;
    configreload('hard') unless $count;
}

sub configreload {
    require pf::violation_config;
    require pf::authentication;
    require pf::admin_roles;
    require pf::ConfigStore::AdminRoles;
    require pf::ConfigStore::Authentication;
    require pf::ConfigStore::FloatingDevice;
    require pf::ConfigStore::Interface;
    require pf::ConfigStore::Provisioning;
    require pf::ConfigStore::Network;
    require pf::ConfigStore::Pf;
    require pf::ConfigStore::Profile;
    require pf::ConfigStore::Switch;
    require pf::ConfigStore::Violations;
    require pf::ConfigStore::Wrix;
    require pf::web::filter;
    require pf::vlan::filter;
    pf::config::cached::updateCacheControl();
    pf::config::cached::ReloadConfigs(1);

    # reload pfconfig's config
    require pfconfig::manager;
    my $manager = pfconfig::manager->new;
    $manager->expire_all;

    # reload violations into DB
    require pf::violation_config;
    pf::violation_config::loadViolationsIntoDb();

}

sub startService {
    my ($service,@services) = @_;
    my @managers = getManagers(\@services,INCLUDE_DEPENDS_ON | JUST_MANAGED);
    print $SERVICE_HEADER;
    my $count = 0;
    postPfStartService(\@managers) if $service eq 'pf';

    my ($noCheckupManagers,$checkupManagers) = part { $_->shouldCheckup } @managers;

    if($noCheckupManagers && @$noCheckupManagers) {
        foreach my $manager (@$noCheckupManagers) {
            _doStart($manager);
        }
    }
    if($checkupManagers && @$checkupManagers) {
        checkup( map {$_->name} @$checkupManagers);
        foreach my $manager (@$checkupManagers) {
            _doStart($manager);
        }
    }
    return 0;
}

sub checkup {
    require pf::services;
    require pf::pfcmd::checkup;
    no warnings "once"; #avoids only used once warnings generated by the access of pf::pfcmd::checkup namespace
    my @services;
    if(@_) {
        @services = @_;
    } else {
        @services = @pf::services::ALL_SERVICES;
    }

    my @problems = pf::pfcmd::checkup::sanity_check(pf::services::service_list(@services));
    foreach my $entry (@problems) {
        chomp $entry->{$pf::pfcmd::checkup::MESSAGE};
        print $entry->{$pf::pfcmd::checkup::SEVERITY}  . " - " . $entry->{$pf::pfcmd::checkup::MESSAGE} . "\n";
    }

    # if there is a fatal problem, exit with status 255
    foreach my $entry (@problems) {
        if ($entry->{$pf::pfcmd::checkup::SEVERITY} eq $pf::pfcmd::checkup::FATAL) {
            exit(255);
        }
    }

    if (@problems) {
        return $TRUE;
    } else {
        return $FALSE;
    }
}

sub _doStart {
    my ($manager) = @_;
    my $command;
    my $color = '';
    if($manager->status ne '0') {
        $color =  $WARNING_COLOR;
        $command = 'already started';
    } else {
        if($manager->start) {
            $command = 'start';
            $color =  $SUCCESS_COLOR;
        } else {
            $command = 'not started';
            $color =  $ERROR_COLOR;
        }
    }
    print $manager->name,"|${color}${command}${RESET_COLOR}\n";
}

sub getManagers {
    my ($services,$flags) = @_;
    $flags = 0 unless defined $flags;
    my %seen;
    my $includeDependsOn = $flags & INCLUDE_DEPENDS_ON;
    my $justManaged      = $flags & JUST_MANAGED;
    my @temp = grep { defined $_ } map { pf::services::get_service_manager($_) } @$services;
    my @serviceManagers;
    foreach my $m (@temp) {
        next if $seen{$m->name} || ( $justManaged && !$m->isManaged );
        my @managers;
        #Get dependencies
        if ($includeDependsOn) {
            @managers = grep { defined $_ } map { pf::services::get_service_manager($_) } @{$m->dependsOnServices}
        }
        if($m->isa("pf::services::manager::submanager")) {
            push @managers,$m->managers;
        } else {
            push @managers,$m;
        }
        #filter out managers already seen
        @managers = grep { !$seen{$_->name}++ } @managers;
        $seen{$m->name}++;
        push @serviceManagers,@managers;
    }
    return @serviceManagers;
}

sub getIptablesTechnique {
    require pf::inline::custom;
    my $iptables = pf::inline::custom->new();
    return $iptables->{_technique};
}

sub stopService {
    my ($service,@services) = @_;
    my @managers = getManagers(\@services);
    #push memcached to back of the list
    my %exclude = (
        memcached => undef,
        pfcache   => undef,
    );
    my ($push_managers,$infront_managers) = part { exists $exclude{ $_->name eq 'memcached' } ? 0 : 1 } @managers;
    @managers = ();
    @managers = @$infront_managers if $infront_managers;
    push @managers, @$push_managers if $push_managers;
    print $SERVICE_HEADER;
    foreach my $manager (@managers) {
        my $command;
        my $color = '';
        if($manager->status eq '0') {
            $command = 'already stopped';
            $color =  $WARNING_COLOR;
        } else {
            if($manager->stop) {
                $color =  $SUCCESS_COLOR;
                $command = 'stop';
            } else {
                $color =  $ERROR_COLOR;
                $command = 'not stopped';
            }
        }
        print $manager->name,"|${color}${command}${RESET_COLOR}\n";
    }
    if(isIptablesManaged($service)) {
        my $count = true { $_->status eq '0'  } @managers;
        if( $count ) {
            getIptablesTechnique->iptables_restore( $install_dir . '/var/iptables.bak' );
        } else {
            $logger->error(
                "Even though 'service pf stop' was called, there are still $count services running. "
                 . "Can't restore iptables from var/iptables.bak"
            );
        }
    }
    return 0;
}

sub isIptablesManaged {
   return $_[0] eq 'pf' && isenabled($Config{services}{iptables})
}

sub restartService {
    stopService(@_);
    local $SERVICE_HEADER = '';
    startService(@_);
}

sub watchService {
    my ($service,@services) = @_;
    my @stoppedServiceManagers =
        grep { $_->status eq '0'  }
        getManagers(\@services, JUST_MANAGED | INCLUDE_DEPENDS_ON);
    if(@stoppedServiceManagers) {
        my @stoppedServices = map { $_->name } @stoppedServiceManagers;
        $logger->info("watch found incorrectly stopped services: " . join(", ", @stoppedServices));
        print "The following processes are not running:\n" . " - "
            . join( "\n - ", @stoppedServices ) . "\n";
        if ( isenabled( $Config{'servicewatch'}{'email'} ) ) {
            my %message;
            $message{'subject'} = "PF WATCHER ALERT";
            $message{'message'}
                = "The following processes are not running:\n" . " - "
                . join( "\n - ", @stoppedServices ) . "\n";
            pfmailer(%message);
        }
        if ( isenabled( $Config{'servicewatch'}{'restart'} ) ) {
            print $SERVICE_HEADER;
            foreach my $manager (@stoppedServiceManagers) {
                $manager->watch;
                print join('|',$manager->name,"watch"),"\n";
            }
            return 0;
        }
    }
    return 1;
}

sub statusOfService {
    my ($service,@services) = @_;
    my @managers = getManagers(\@services);
    print "service|shouldBeStarted|pid\n";
    my $notStarted = 0;
    foreach my $manager (@managers) {
        my $color = '';
        my $isManaged = $manager->isManaged;
        my $status = $manager->status;
        if($status eq '0' ) {
            if ($isManaged) {
                $color =  $ERROR_COLOR;
                $notStarted++;
            } else {
                $color =  $WARNING_COLOR;
            }
        } else {
            $color =  $SUCCESS_COLOR;
        }
        print $manager->name,"|${color}$isManaged|$status${RESET_COLOR}\n";
    }
    return ( $notStarted ? 3 : 0);
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

Minor parts of this file may have been contributed. See CREDITS.

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and::or
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

