package FusionInventory::Agent::Tools;

use strict;
use warnings;
use base 'Exporter';

use English qw(-no_match_vars);
use File::stat;
use Memoize;
use Sys::Hostname;

our @EXPORT = qw(
    getFileHandle
    getFormatedLocalTime
    getFormatedGmTime
    getFormatedDate
    getCanonicalManufacturer
    getCanonicalSpeed
    getCanonicalSize
    getInfosFromDmidecode
    getSanitizedString
    getSingleLine
    getHostname
    getDeviceId
    getRandomToken
    compareVersion
    can_run
    can_load
);

memoize('can_run');
memoize('getCanonicalManufacturer');
memoize('getInfosFromDmidecode');

sub getFormatedLocalTime {
    my ($time) = @_;

    my ($year, $month , $day, $hour, $min, $sec) =
        (localtime ($time))[5, 4, 3, 2, 1, 0];

    return getFormatedDate(
        ($year + 1900), ($month + 1), $day, $hour, $min, $sec
    );
}

sub getFormatedGmTime {
    my ($time) = @_;

    my ($year, $month , $day, $hour, $min, $sec) =
        (gmtime ($time))[5, 4, 3, 2, 1, 0];

    return getFormatedDate(
        ($year - 70), $month, ($day - 1), $hour, $min, $sec
    );
}

sub getFormatedDate {
    my ($year, $month, $day, $hour, $min, $sec) = @_;

    return sprintf
        "%02d-%02d-%02d %02d:%02d:%02d",
        $year, $month, $day, $hour, $min, $sec;
}

sub getCanonicalManufacturer {
    my ($model) = @_;

    return unless $model;

    if ($model =~ /(
        maxtor    |
        sony      |
        compaq    |
        ibm       |
        toshiba   |
        fujitsu   |
        lg        |
        samsung   |
        nec       |
        transcend |
        matshita  |
        pioneer
    )/xi) {
        $model = ucfirst(lc($1));
    } elsif ($model =~ /^(hp|HP|hewlett packard)/) {
        $model = "Hewlett Packard";
    } elsif ($model =~ /^(WDC|[Ww]estern)/) {
        $model = "Western Digital";
    } elsif ($model =~ /^(ST|[Ss]eagate)/) {
        $model = "Seagate";
    } elsif ($model =~ /^(HD|IC|HU)/) {
        $model = "Hitachi";
    }

    return $model;
}

sub getCanonicalSpeed {
    my ($speed) = @_;

    ## no critic (ExplicitReturnUndef)

    return undef unless $speed;

    return 400 if $speed =~ /^PC3200U/;

    return undef unless $speed =~ /^(\d+) \s? (\S+)$/x;
    my $value = $1;
    my $unit = lc($2);

    return
        $unit eq 'ghz' ? $value * 1000 :
        $unit eq 'mhz' ? $value        :
                         undef         ;
}

sub getCanonicalSize {
    my ($size) = @_;

    ## no critic (ExplicitReturnUndef)

    return undef unless $size;

    return undef unless $size =~ /^(\d+) \s (\S+)$/x;
    my $value = $1;
    my $unit = lc($2);

    return
        $unit eq 'tb' ? $value * 1000 * 1000 :
        $unit eq 'gb' ? $value * 1000        :
        $unit eq 'mb' ? $value               :
                        undef                ;
}

sub getInfosFromDmidecode {
    my %params = (
        command => 'dmidecode',
        @_
    );
    my $handle = getFileHandle(%params);

    my ($info, $block, $type);

    while (my $line = <$handle>) {
        chomp $line;

        if ($line =~ /DMI type (\d+)/) {
            # start of block

            # push previous block in list
            if ($block) {
                push(@{$info->{$type}}, $block);
                undef $block;
            }

            # switch type
            $type = $1;

            next;
        }

        next unless defined $type;

        next unless $line =~ /^\s+ ([^:]+) : \s (.*\S)/x;

        next if
            $2 eq 'N/A'           ||
            $2 eq 'Not Specified' ||
            $2 eq 'Not Present'   ;

        $block->{$1} = $2;
    }
    close $handle;

    return $info;
}

sub compareVersion {
    my ($major, $minor, $min_major, $min_minor) = @_;

    return
        $major > $minor
        ||
        (
            $major == $min_major
            &&
            $minor >= $min_minor
        );
}

sub getSanitizedString {
    my ($string) = @_;

    return unless defined $string;

    # clean control caracters
    $string =~ s/[[:cntrl:]]//g;

    # encode to utf-8 if needed
    if ($string !~ m/\A(
          [\x09\x0A\x0D\x20-\x7E]           # ASCII
        | [\xC2-\xDF][\x80-\xBF]            # non-overlong 2-byte
        | \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
        | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2} # straight 3-byte
        | \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
        | \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
        | [\xF1-\xF3][\x80-\xBF]{3}         # planes 4-15
        | \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
        )*\z/x) {
        $string = encode("UTF-8", $string);
    };

    return $string;
}

sub getFileHandle {
    my %params = @_;

    my $handle;

    SWITCH: {
        if ($params{file}) {
            if (!open $handle, '<', $params{file}) {
                $params{logger}->error(
                    "Can't open file $params{file}: $ERRNO"
                ) if $params{logger};
                return;
            }
            last SWITCH;
        }
        if ($params{command}) {
            if (!open $handle, '-|', $params{command}) {
                $params{logger}->error(
                    "Can't run command $params{command}: $ERRNO"
                ) if $params{logger};
                return;
            }
            last SWITCH;
        }
        die "neither command nor file parameter given";
    }

    return $handle;
}

sub getSingleLine {
    my %params = @_;

    my $handle = getFileHandle(%params);
    my $result = <$handle>;
    close $handle;

    chomp $result;
    return $result;
}

sub can_run {
    my ($binary) = @_;

    if ($OSNAME eq 'MSWin32') {
        foreach my $dir (split/$Config::Config{path_sep}/, $ENV{PATH}) {
            foreach my $ext (qw/.exe .bat/) {
                return 1 if -f $dir . '/' . $binary . $ext;
            }
        }
        return 0;
    } else {
        return 
            system("which $binary >/dev/null 2>&1") == 0;
    }

}

sub can_load {
    my ($module) = @_;

    return $module->require();
}

sub getHostname {

    # use hostname directly under Unix
    return hostname() if $OSNAME ne 'MSWin32';

    # otherwise, use Win32 API
    eval {
        require Encode;
        require Win32::API;
        Encode->import();

        my $getComputerName = Win32::API->new(
            "kernel32", "GetComputerNameExW", ["I", "P", "P"], "N"
        );
        my $lpBuffer = "\x00" x 1024;
        my $N = 1024; #pack ("c4", 160,0,0,0);

        $getComputerName->Call(3, $lpBuffer, $N);

        # GetComputerNameExW returns the string in UTF16, we have to change
        # it to UTF8
        return encode(
            "UTF-8", substr(decode("UCS-2le", $lpBuffer), 0, ord $N)
        );
    };
}

sub getDeviceId {
    my $hostname = getHostname();
    my ($year, $month , $day, $hour, $min, $sec) =
        (localtime(time()))[5,4,3,2,1,0];
    return sprintf "%s-%02d-%02d-%02d-%02d-%02d-%02d",
        $hostname, ($year + 1900), ($month + 1), $day, $hour, $min, $sec;
}

sub getRandomToken {
    my @chars = ('A'..'Z');
    return join('', map { $chars[rand @chars] } 1..8);
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Tools - OS-independant generic functions

=head1 DESCRIPTION

This module provides some OS-independant generic functions.

=head1 FUNCTIONS

=head2 getFormatedLocalTime($time)

Returns a formated date from given Unix timestamp.

=head2 getFormatedGmTime($time)

Returns a formated date from given Unix timestamp.

=head2 getFormatedDate($year, $month, $day, $hour, $min, $sec)

Returns a formated date from given date elements.

=head2 getCanonicalManufacturer($manufacturer)

Returns a normalized manufacturer value for given one.

=head2 getCanonicalSpeed($speed)

Returns a normalized speed value (in Mhz) for given one.

=head2 getCanonicalSize($size)

Returns a normalized size value (in Mb) for given one.

=head2 getInfosFromDmidecode

Returns a structured view of dmidecode output. Each information block is turned
into an hashref, block with same DMI type are grouped into a list, and each
list is indexed by its DMI type into the resulting hashref.

$info = {
    0 => [
        { block }
    ],
    1 => [
        { block },
        { block },
    ],
    ...
}

=head2 getSanitizedString($string)

Returns the input stripped from any control character, properly encoded in
UTF-8.

=head2 compareVersion($major, $minor, $min_major, $min_minor)

Returns true if software with given major and minor version meet minimal
version requirements.

=head2 getFileHandle(%params)

Returns an open file handle on either a command output, or a file.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getSingleLine(%params)

Returns the first line of given command output or given file content, with end
of line removed.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getHostname()

Returns host name, using hostname() under Unix, Win32::API under Windows.

=head2 can_run($binary)

Returns true if given binary can be executed.

=head2 can_load($module)

Returns true if given perl module can be loaded (and actually loads it).

