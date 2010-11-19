package FusionInventory::Agent::Target::Server;

use strict;
use warnings;
use base 'FusionInventory::Agent::Target';

use English qw(-no_match_vars);
use URI;

my $count = 0;

sub new {
    my ($class, %params) = @_;

    die "no url parameter" unless $params{url};

    my $self = $class->SUPER::new(%params);

    $self->{url} = URI->new($params{url});

    my $scheme = $self->{url}->scheme();
    if (!$scheme) {
        # this is likely a bare hostname
        # as parsing relies on scheme, host and path have to be set explicitely
        $self->{url}->scheme('http');
        $self->{url}->host($params{url});
        $self->{url}->path('ocsinventory');
    } else {
        die "invalid protocol for URL: $params{url}"
            if $scheme ne 'http' && $scheme ne 'https';
        # complete path if needed
        $self->{url}->path('ocsinventory') if !$self->{url}->path();
    }

    # compute storage subdirectory from url
    my $subdir = $params{url};
    $subdir =~ s/\//_/g;
    $subdir =~ s/:/../g if $OSNAME eq 'MSWin32';

    $self->_init(
        id     => 'server' . $count++,
        vardir => $params{basevardir} . '/' . $subdir
    );

    return $self;
}

sub getUrl {
    my ($self) = @_;

    return $self->{url};
}

sub getAccountInfo {
    my ($self) = @_;

    return $self->{accountInfo};
}

sub setAccountInfo {
    my ($self, $accountInfo) = @_;

    $self->{accountInfo} = $accountInfo;
}

sub _load {
    my ($self) = @_;

    my $data = $self->{storage}->restore();
    $self->{nextRunDate} = $data->{nextRunDate} if $data->{nextRunDate};
    $self->{maxOffset}   = $data->{maxOffset} if $data->{maxOffset};
    $self->{accountInfo} = $data->{accountInfo} if $data->{accountInfo};
}

sub saveState {
    my ($self) = @_;

    $self->{storage}->save({
        data => {
            nextRunDate => $self->{nextRunDate},
            maxOffset   => $self->{maxOffset},
            accountInfo => $self->{accountInfo}
        }
    });

}

sub getDescriptionString {
    my ($self) = @_;

    my $url = $self->{url};

    # Remove the login:password if needed
    $url =~ s/(http|https)(:\/\/)(.*@)(.*)/$1$2$4/;

    return "server, $url";
}

1;

__END__

=head1 NAME

FusionInventory::Agent::Target::Server - Server target

=head1 DESCRIPTION

This is a target for sending execution result to a server.

=head1 METHODS

=head2 new($params)

The constructor. The following parameters are allowed, in addition to those
from the base class C<FusionInventory::Agent::Target>, as keys of the $params
hashref:

=over

=item I<url>

the server URL (mandatory)

=back

=head2 getAccountInfo()

Get account informations for this target.

=head2 setAccountInfo($info)

Set account informations for this target.

=head2 getUrl()

Return the server URL for this target.

=head2 getDescriptionString)

Return a string to display to user in a 'target' field.

