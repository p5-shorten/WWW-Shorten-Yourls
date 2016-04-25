package WWW::Shorten::Yourls;

use warnings;
use strict;
use Carp ();
use File::Spec;
use JSON::MaybeXS;
use XML::Simple();

use base qw( WWW::Shorten::generic Exporter );

our $VERSION = '0.070';
$VERSION = eval $VERSION;

our %EXPORT_TAGS = ('all' => [qw()]);
our @EXPORT_OK   = (@{$EXPORT_TAGS{'all'}});
our @EXPORT      = qw(new version);

our @ISA = qw(Exporter);

sub new {
    my ($class) = shift;
    my %args = @_;
    $args{source} ||= "teknatusyourls";
    my $yourlsrc
        = $^O =~ /Win32/i
        ? File::Spec->catfile($ENV{HOME}, "_yourls")
        : File::Spec->catfile($ENV{HOME}, ".yourls");
    if (-r $yourlsrc) {
        open my $fh, "<", $yourlsrc or die "can't open .yourls file $!";
        while (<$fh>) {
            $args{USER}      ||= $1 if m{^USER=(.*)};
            $args{PASSWORD}  ||= $1 if m{^PASSWORD=(.*)};
            $args{SIGNATURE} ||= $1 if m{^SIGNATURE=(.*)};
        }
        close $fh;
    }
    if (
        (
               (!$args{USER} && !$args{PASSWORD})
            && (!$args{USER} && !$args{SIGNATURE})
        )
        || !$args{BASE}
        )
    {
        carp(
            "USER/PASSWORD or USER/SIGNATURE and BASE are required parameters.\n"
        );
        return -1;
    }
    my $yourls;
    $yourls->{USER}      = $args{USER};
    $yourls->{PASSWORD}  = $args{PASSWORD};
    $yourls->{BASE}      = $args{BASE};
    $yourls->{SIGNATURE} = $args{SIGNATURE};
    $yourls->{browser}   = LWP::UserAgent->new(agent => $args{source});
    $yourls->{xml}       = XML::Simple(SuppressEmpty => 1)->new;
    my ($self) = $yourls;
    bless $self, $class;
}

sub makeashorterlink {
    my ($url, $user, $password, $base) = @_;
    Carp::croak('No URL passed to makeashorterlink') unless $url;
    Carp::croak('No username passed to makeashorterlink') unless $user;
    Carp::croak('No password passed to makeashorterlink') unless $password;
    Carp::croak('No base passed to makeashorterlink') unless $base;

    my $ua = __PACKAGE__->ua();
    my $yurl = $base . "/yourls-api.php";
    my $res = $ua->post(
        $yurl,
        [
            'url'      => $url,
            'format'   => 'json',
            'action'   => 'shorturl',
            'username' => $user,
            'password' => $password,
        ]
    );
    $res->is_success || die 'Failed to get yourls.org link: '. $res->status_line;
    my $obj = JSON::MaybeXS::decode_json($res->decoded_content);
    return $obj->{url} if $obj->{url};
    return undef;
}

sub makealongerlink {
    my $url = shift
        or croak('No shortened yourls.org URL passed to makealongerlink');
    my ($user, $password, $base) = @_
        or croak('No username, password, or base passed to makealongerlink');
    my $ua   = __PACKAGE__->ua();
    my $yurl = $base . "/yourls-api.php";
    my $yourls;
    $yourls->{json}     = JSON::Any->new;
    $yourls->{xml}      = XML::Simple(SuppressEmpty => 1)->new;
    $yourls->{response} = $ua->post(
        $yurl,
        [
            'shorturl' => $url,
            'format'   => 'json',
            'action'   => 'expand',
            'username' => $user,
            'password' => $password,
        ]
    );
    $yourls->{response}->is_success
        || die 'Failed to get yourls.org link: '
        . $yourls->{response}->status_line;
    $yourls->{longurl}
        = $yourls->{json}->jsonToObj($yourls->{response}->{_content})->{longurl}
        if (
        defined $yourls->{json}->jsonToObj($yourls->{response}->{_content})
        ->{statusCode}
        && $yourls->{json}->jsonToObj($yourls->{response}->{_content})
        ->{statusCode} == 200);
    return $yourls->{longurl};
}

sub shorten {
    my $self = shift;
    my %args = @_;
    if (!defined $args{URL}) {
        croak("URL is required.\n");
        return -1;
    }
    $args{format} ||= 'json';
    if (!$self->{SIGNATURE}) {
        $self->{response} = $self->{browser}->post(
            $self->{BASE} . '/yourls-api.php',
            [
                'url' => $args{URL},

                #        'keyword' => $args{keyword},
                'format'   => $args{format},
                'action'   => 'shorturl',
                'username' => $self->{USER},
                'password' => $self->{PASSWORD},
            ]
        );
    }
    else {
        $self->{response} = $self->{browser}->post(
            $self->{BASE} . '/yourls-api.php',
            [
                'url' => $args{URL},

                #        'keyword' => $args{keyword},
                'format'    => $args{format},
                'action'    => 'shorturl',
                'signature' => $self->{SIGNATURE},
            ]
        );
    }
    $self->{response}->is_success
        || die 'Failed to get yourls.org link: '
        . $self->{response}->status_line;
    $self->{url}
        = $self->{json}->jsonToObj($self->{response}->{_content})->{shorturl}
        if (
        defined $self->{json}->jsonToObj($self->{response}->{_content})
        ->{statusCode}
        && $self->{json}->jsonToObj($self->{response}->{_content})->{statusCode}
        == 200);
    return $self->{url};
}

sub expand {
    my $self = shift;
    my %args = @_;
    $args{URL} ||= $self->{url};
    if (!defined $args{URL}) {
        croak("URL is required.\n");
        return -1;
    }
    $args{format} ||= 'json';
    if (!$self->{SIGNATURE}) {
        $self->{response} = $self->{browser}->post(
            $self->{BASE} . '/yourls-api.php',
            [
                'shorturl' => $args{URL},
                'action'   => 'expand',
                'username' => $self->{USER},
                'password' => $self->{PASSWORD},
                'format'   => $args{format}
            ]
        );
    }
    else {
        $self->{response} = $self->{browser}->post(
            $self->{BASE} . '/yourls-api.php',
            [
                'shorturl'  => $args{URL},
                'action'    => 'expand',
                'signature' => $self->{SIGNATURE},
                'format'    => $args{format}
            ]
        );
    }
    $self->{response}->is_success
        || die 'Failed to get yourls.org link: '
        . $self->{response}->status_line;
    $self->{longurl}
        = $self->{json}->jsonToObj($self->{response}->{_content})->{longurl}
        if (
        defined $self->{json}->jsonToObj($self->{response}->{_content})
        ->{statusCode}
        && $self->{json}->jsonToObj($self->{response}->{_content})->{statusCode}
        == 200);
    return $self->{longurl};
}

sub clicks {
    my $self = shift;
    my %args = @_;
    $args{URL} ||= $self->{url};
    if (!defined $args{URL}) {
        croak("URL is required.\n");
        return -1;
    }
    if (!$self->{SIGNATURE}) {
        $self->{response} = $self->{browser}->post(
            $self->{BASE} . '/yourls-api.php',
            [
                'action'   => 'url-stats',
                'format'   => 'json',
                'shorturl' => $args{URL},
                'username' => $self->{USER},
                'password' => $self->{PASSWORD},
            ]
        );
    }
    else {
        $self->{response}
            = $self->{browser}->get($self->{BASE}
                . '/yourls-api.php?action=url-stats&format=json&shorturl='
                . $args{URL}
                . '&signature='
                . $self->{SIGNATURE});
    }
    $self->{response}->is_success
        || die 'Failed to get yourls.org link: '
        . $self->{response}->status_line;
    if (
        defined $self->{json}->jsonToObj($self->{response}->{_content})
        ->{statusCode}
        && $self->{json}->jsonToObj($self->{response}->{_content})->{statusCode}
        == 200)
    {
        $self->{$args{URL}}->{clicks}
            = $self->{json}->jsonToObj($self->{response}->{_content})->{link}
            ->{clicks};
        $self->{$args{URL}}->{info}
            = $self->{json}->jsonToObj($self->{response}->{_content});
    }
    return $self->{$args{URL}};
}

sub errors {
    my $self = shift;
    if (!$self->{SIGNATURE}) {
        $self->{response} = $self->{browser}->post($self->{BASE} . '/errors',
            ['username' => $self->{USER}, 'password' => $self->{PASSWORD},]);
    }
    else {
        $self->{response} = $self->{browser}->post($self->{BASE} . '/errors',
            ['signature' => $self->{SIGNATURE},]);
    }
    $self->{response}->is_success
        || die 'Failed to get yourls.org link: '
        . $self->{response}->status_line;
    $self->{$self->{url}}->{content}
        = $self->{xml}->XMLin($self->{response}->{_content});
    $self->{$self->{url}}->{errorCode}
        = $self->{$self->{url}}->{content}->{errorCode};
    if ($self->{$self->{url}}->{errorCode} == 0) {
        $self->{$self->{url}}->{clicks}
            = $self->{$self->{url}}->{content}->{results};
        return $self->{$self->{url}}->{clicks};
    }
    else {
        return;
    }
}

sub version { $WWW::Shorten::Yourls::VERSION; }

1;   # End of WWW::Shorten::Yourls

__END__

=head1 NAME

WWW::Shorten::Yourls - Interface to shortening URLs using L<http://yourls.org>

=head1 SYNOPSIS

L<WWW::Shorten::Yourls> provides an easy interface for shortening URLs
using L<http://yourls.org>. In addition to shortening URLs, you can pull
statistics that L<http://yourls.org> gathers regarding each shortened URL.

L<WWW::Shorten::Yourls> provides two interfaces. The first is the common
C<makeashorterlink> and C<makealongerlink> that L<WWW::Shorten> provides.
However, due to the way the L<http://yourls.org> API works, additional
arguments are required. The second provides a better way of retrieving
additional information and statistics about a URL.

    use WWW::Shorten::Yourls;

    my $url = "http://www.example.com";

    my $tmp = makeashorterlink($url, 'MY_YOURLS_USERNAME', 'MY_YOURLS_PASSWORD');
    my $tmp1 = makealongerlink($tmp, 'MY_YOURLS_USERNAME', 'MY_YOURLS_PASSWORD');

    # or

    use WWW::Shorten::Yourls;

    my $url = "http://www.example.com";
    my $yourls = WWW::Shorten::Yourls->new(
        SIGNATURE => "my_api_key",
        BASE      => 'myyourlsinstall.example.com',
    );

    # or

    my $yourls = WWW::Shorten::Yourls->new(
        USER     => "my_user",
        PASSWORD => "my_pass",
        BASE     => 'myyourlsinstall.example.com',
    );

    $yourls->shorten(URL => $url);
    print "shortened URL is $yourls->{url}\n";

    $yourls->expand(URL => $yourls->{url});
    print "expanded/original URL is $yourls->{longurl}\n";

=head1 FUNCTIONS

=head2 new

Create a new instance object using your user id and API key.

    my $yourls = WWW::Shorten::Yourls->new(
        SIGNATURE => "my_api_key",
        BASE      => 'myyourlsinstall.example.com',
    );

    # or

    my $yourls = WWW::Shorten::Yourls->new(
        USER     => "my_user",
        PASSWORD => "my_pass",
        BASE     => 'myyourlsinstall.example.com',
    );

=head2 makeashorterlink

The function C<makeashorterlink> will call the API, passing it
your long URL and will return the shorter version.

A user id and password is required to shorten links.

    makeashorterlink($url,$uid,$passwd,$base);

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

A user name and API Key are required.

If anything goes wrong, then the function will return C<undef>.

    makealongerlink($url,$uid,$passwd,$base);

THIS IS NOT WORKING.

=head2 shorten

Shorten a URL using L<http://yourls.org>. Calling the shorten method will
return the shortened URL but will also store it in your object instance
until the next call is made.

    my $url = "http://www.example.com";
    my $shortstuff = $yourls->shorten(URL => $url);

    print "yurl is " . $yourls->{url} . "\n";
    # or
    print "yurl is $shortstuff\n";

=head2 expand

Expands a shortened URL to the original long URL.

=head2 clicks

Get click-through information for a shortened URL. By
default, the method will use the value that's stored in
C<< $yourls->{url} >>. To be sure you're getting info on the correct URL,
it's a good idea to set this value before getting any info on it.

THIS IS NOT WORKING.

=head2 errors

THIS IS NOT WORKING.

=head2 version

Gets the module version number

=head1 FILES

$C<HOME/.yourls> or C<_yourls> on Windows Systems.

You may omit C<USER> and C<PASSWORD> in the constructor if you set them in the
C<.yourls> config file on separate lines using the syntax:

  USER=username
  PASSWORD=password

=head1 AUTHOR

Pankaj Jain, <F<pjain@cpan.org>>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener <F<capoeirab@cpan.org>>

=item *

Michiel Beijen <F<michielb@cpan.org>>

=back

=head1 LICENSE AND COPYRIGHT

=over

=item *

Copyright (c) 2009 Pankaj Jain, All Rights Reserved L<http://blog.linosx.com>.

=item *

Copyright (c) 2009 Teknatus Solutions LLC, All Rights Reserved L<http://www.teknatus.com>.

=back

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<WWW::Shorten>, L<http://yourls.org>.

=cut
