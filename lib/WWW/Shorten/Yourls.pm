package WWW::Shorten::Yourls;

use warnings;
use strict;
use Carp;

use base qw( WWW::Shorten::generic Exporter );

use JSON::Any;

require XML::Simple;
require Exporter;

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(new version);

my @ISA = qw(Exporter);

use vars qw( @ISA @EXPORT );


=head1 NAME

WWW::Shorten::Yourls - Interface to shortening URLs using L<http://yourls.org>

=head1 VERSION

$Revision: 0.01 $

=cut

BEGIN {
    our $VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%1d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
    $WWW::Shorten::Yourls::VERBOSITY = 2;
}

# ------------------------------------------------------------


=head1 SYNOPSIS

WWW::Shorten::Yourls provides an easy interface for shortening URLs using http://yourls.org. In addition to shortening URLs, you can pull statistics that yourls.org gathers regarding each shortened
WWW::Shorten::Yourls uses XML::Simple to convert the xml response for the meta info and click stats to create a hashref of the results.

WWW::Shorten::Yourls provides two interfaces. The first is the common C<makeashorterlink> and C<makealongerlink> that WWW::Shorten provides. However, due to the way the yourls.org API works, additional arguments are required. The second provides a better way of retrieving additional information and statistics about a yourls.org URL.

use WWW::Shorten::Yourls;

my $url = "http://www.example.com";

my $tmp = makeashorterlink($url, 'MY_YOURLS_USERNAME', 'MY_YOURLS_PASSWORD');
my $tmp1 = makealongerlink($tmp, 'MY_YOURLS_USERNAME', 'MY_YOURLS_PASSWORD');

or

use WWW::Shorten::Yourls;

my $url = "http://www.example.com";
my $yourls = WWW::Shorten::Yourls->new(USER => "my_user_id",
APIKEY => "my_api_key");

$yourls->shorten(URL => $url);
print "shortened URL is $yourls->{url}\n";

$yourls->expand(URL => $yourls->{url});
print "expanded/original URL is $yourls->{longurl}\n";

=head1 FUNCTIONS

=head2 new

Create a new yourls.org object using your yourls.org user id and yourls.org api key.

my $yourls = WWW::Shorten::Yourls->new(URL => "http://www.example.com/this_is_one_example.html",
USER => "yourls_user_id",
PASSWORD => "yourls_password");

=cut

sub new {
    my ($class) = shift;
    my %args = @_;
    $args{source} ||= "teknatusyourls";
    use File::Spec;
    my $yourlsrc = $^O =~/Win32/i ? File::Spec->catfile($ENV{HOME}, "_yourls") : File::Spec->catfile($ENV{HOME}, ".yourls");
    if (-r $yourlsrc){
        open my $fh, "<", $yourlsrc or die "can't open .yourls file $!";
        while(<$fh>){
            $args{USER} ||= $1 if m{^USER=(.*)};
            $args{PASSWORD} ||= $1 if m{^PASSWORD=(.*)};
        }
        close $fh;
    }
    if (!defined $args{USER} || !defined $args{PASSWORD} || !defined $args{BASE}) {
        carp("USER,PASSWORD and BASE are required parameters.\n");
        return -1;
    }
    my $yourls;
    $yourls->{USER} = $args{USER};
    $yourls->{PASSWORD} = $args{PASSWORD};
    $yourls->{BASE} = $args{BASE};
    $yourls->{json} = JSON::Any->new;
    $yourls->{browser} = LWP::UserAgent->new(agent => $args{source});
    $yourls->{xml} = new XML::Simple(SuppressEmpty => 1);
    my ($self) = $yourls;
    bless $self, $class;
    if (defined $args{URL}) {
        $self->shorten(URL => $args{URL});
        return $self->{url};
    }
}


=head2 makeashorterlink

The function C<makeashorterlink> will call the yourls.org API site passing it
your long URL and will return the shorter yourls.org version.

yourls.org requires the use of a user id and password to shorten links.

makeashorterlink($url,$uid,$passwd,$base);

=cut

sub makeashorterlink #($;%)
{
    my $url = shift or croak('No URL passed to makeashorterlink');
    my ($user, $password, $base) = @_ or croak('No username, password or Yourls service URL passed to makeshorterlink');
    if (!defined $url || !defined $user || !defined $password ) {
        croak("url, user, password, base are required for shortening a URL with yourls.org - in that specific order");
        &help();
    }
    my $ua = __PACKAGE__->ua();
    my $yourls;
    $yourls->{json} = JSON::Any->new;
    $yourls->{xml} = new XML::Simple(SuppressEmpty => 1);
    my $yurl = $base . "/yourls-api.php";
    $yourls->{response} = $ua->post($yurl, [
        'url' => $url,
#        'keyword' => $keyword,
        'format' => 'json',
        'action' => 'shorturl',
        'username' => $user,
        'password' => $password,
    ]);
    $yourls->{response}->is_success || die 'Failed to get yourls.org link: ' . $yourls->{response}->status_line;
    $yourls->{url} = $yourls->{json}->jsonToObj($yourls->{response}->{_content})->{shorturl};
    return $yourls->{url} if ( $yourls->{json}->jsonToObj($yourls->{response}->{_content})->{status} eq 'success' || ($yourls->{json}->jsonToObj($yourls->{response}->{_content})->{status} eq 'fail' && $yourls->{json}->jsonToObj($yourls->{response}->{_content})->{code} eq 'error:url'));
}

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full yourls.org URL or just the
yourls.org identifier. yourls.org requires the use of a user name and API
Key when using the API.

If anything goes wrong, then the function will return C<undef>.

makealongerlink($url,$uid,$passwd,$base);

THIS IS NOT WORKING RIGHT NOW AS YOURLS DOESN'T SUPPORT EXPANDING A URL.

=cut

sub makealongerlink #($,%)
{
    my $url = shift or croak('No shortened yourls.org URL passed to makealongerlink');
    my ($user, $password, $base) = @_ or croak('No username, password, or base passed to makealongerlink');
    my $ua = __PACKAGE__->ua();
    my $yourls;
    my @foo = split(/\//, $url);
    $yourls->{json} = JSON::Any->new;
    $yourls->{xml} = new XML::Simple(SuppressEmpty => 1);
    $yourls->{response} = $ua->post($base . '/expand', [
        'url' => $url,
#        'keyword' => $keyword,
        'format' => 'json',
        'action' => 'expand',
        'username' => $user,
        'password' => $password,
    ]);
    $yourls->{response}->is_success || die 'Failed to get yourls.org link: ' . $yourls->{response}->status_line;
    $yourls->{longurl} = $yourls->{json}->jsonToObj($yourls->{response}->{_content})->{shorturl};
    return $yourls->{longurl} if ( $yourls->{json}->jsonToObj($yourls->{response}->{_content})->{status} eq 'success' || ($yourls->{json}->jsonToObj($yourls->{response}->{_content})->{status} eq 'fail' && $yourls->{json}->jsonToObj($yourls->{response}->{_content})->{code} eq 'error:url'));
}

=head2 shorten

Shorten a URL using http://yourls.org. Calling the shorten method will return the shortened URL but will also store it in yourls.org object until the next call is made.

my $url = "http://www.example.com";
my $shortstuff = $yourls->shorten(URL => $url);

print "yurl is " . $yourls->{url} . "\n";
or
print "yurl is $shortstuff\n";

=cut


sub shorten {
    my $self = shift;
    my %args = @_;
    if (!defined $args{URL}) {
        croak("URL is required.\n");
        return -1;
    }
    $args{format} ||= 'json';
    $self->{response} = $self->{browser}->post($self->{BASE} . '/yourls-api.php', [
        'url' => $args{URL},
#        'keyword' => $args{keyword},
        'format' => $args{format},
        'action' => 'shorturl',
        'username' => $self->{USER},
        'password' => $self->{PASSWORD},
    ]);
    $self->{response}->is_success || die 'Failed to get yourls.org link: ' . $self->{response}->status_line;
    $self->{url} = $self->{json}->jsonToObj($self->{response}->{_content})->{shorturl};
    return $self->{url} if ( $self->{json}->jsonToObj($self->{response}->{_content})->{status} eq 'success' || ($self->{json}->jsonToObj($self->{response}->{_content})->{status} eq 'fail' && $self->{json}->jsonToObj($self->{response}->{_content})->{code} eq 'error:url'));
}

=head2 expand

Expands a shortened yourls.org URL to the original long URL.

THIS IS NOT WORKING RIGHT NOW AS YOURLS < 1.4 DOESN'T SUPPORT EXPANDING A URL

1.4 hasn't been released yet.

=cut
sub expand {
    my $self = shift;
    my %args = @_;
    if (!defined $args{URL} || !defined $args{base} ) {
        croak("URL and base are required.\n");
        return -1;
    }
    $args{format} ||= 'json';
    my @foo = split(/\//, $args{URL});
    $self->{response} = $self->{browser}->get($args{base} . '/expand', [
        'shorturl' => $args{URL},
        'action'   => 'expand'
        'username' => $self->{USER},
        'password' => $self->{PASSWORD},
        'format'   => $args{format}
    ]);
    $self->{response}->is_success || die 'Failed to get yourls.org link: ' . $self->{response}->status_line;
    $self->{response}->is_success || die 'Failed to get yourls.org link: ' . $self->{response}->status_line;
    $self->{urllong} = $self->{json}->jsonToObj($self->{response}->{_content})->{longurl};
    return $self->{urllong} if ( $self->{json}->jsonToObj($self->{response}->{_content})->{status} eq 'success' || ($self->{json}->jsonToObj($self->{response}->{_content})->{status} eq 'fail' && $self->{json}->jsonToObj($self->{response}->{_content})->{code} eq 'error:url'));
}

=head2 clicks

Get click thru information for a shortened yourls.org URL. By default, the method will use the value that's stored in $yourls->{url}. To be sure you're getting info on the correct URL, it's a good idea to set this value before getting any info on it.

THIS HAS NOT BEEN IMPLEMENTED YET AS YOURLS DOESN'T SUPPORT THIS FUNCTIONALITY.

=cut

sub clicks {
    my $self = shift;
    $self->{response} = $self->{browser}->post($self->{BASE} . '/stats', [
        'format' => 'json',
        'shortUrl' => $self->{url},
        'username' => $self->{USER},
        'password' => $self->{PASSWORD},
    ]);
    $self->{response}->is_success || die 'Failed to get yourls.org link: ' . $self->{response}->status_line;
    $self->{$self->{url}}->{content} = $self->{xml}->XMLin($self->{response}->{_content});
    $self->{$self->{url}}->{errorCode} = $self->{$self->{url}}->{content}->{errorCode};
    if ($self->{$self->{url}}->{errorCode} == 0 ) {
        $self->{$self->{url}}->{clicks} = $self->{$self->{url}}->{content}->{results};
        return $self->{$self->{url}}->{clicks};
    } else {
        return;
    }
}

=head2 errors

THIS IS NOT WORKING RIGHT NOW AS YOURLS DOESN'T SUPPORT ERROR RESPONSES FROM A URL.

=cut

sub errors {
    my $self = shift;
    $self->{response} = $self->{browser}->post($self->{BASE} . '/errors', [
        'username' => $self->{USER},
        'password' => $self->{PASSWORD},
    ]);
    $self->{response}->is_success || die 'Failed to get yourls.org link: ' . $self->{response}->status_line;
    $self->{$self->{url}}->{content} = $self->{xml}->XMLin($self->{response}->{_content});
    $self->{$self->{url}}->{errorCode} = $self->{$self->{url}}->{content}->{errorCode};
    if ($self->{$self->{url}}->{errorCode} == 0 ) {
        $self->{$self->{url}}->{clicks} = $self->{$self->{url}}->{content}->{results};
        return $self->{$self->{url}}->{clicks};
    } else {
        return;
    }
}

=head2 version

Gets the module version number

=cut
sub version {
    my $self = shift;
    my($version) = shift;# not sure why $version isn't being set. need to look at it
    warn "Version $version is later then $WWW::Shorten::Yourls::VERSION. It may not be supported" if (defined ($version) && ($version > $WWW::Shorten::Yourls::VERSION));
    return $WWW::Shorten::Yourls::VERSION;
}#version


=head1 FILES

$HOME/.yourls or _yourls on Windows Systems.

You may omit USER and PASSWORD in the constructor if you set them in the .yourls config file on separate lines using the syntax:

USER=username
PASSWORD=password


=head1 AUTHOR

Pankaj Jain, C<< <pjain at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-shorten-yourls at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Shorten-Yourls>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc WWW::Shorten::Yourls


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Shorten-Yourls>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Shorten-Yourls>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Shorten-Yourls>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Shorten-Yourls/>

=back


=head1 ACKNOWLEDGEMENTS

=over

=item http://yourls.org for a great tool.

=item Larry Wall, Damian Conway, and all the amazing folks giving us Perl and continuing to work on it over the years.

=item Mizar, C<< <mizar.jp@gmail.com> >>, Peter Edwards, C<<pedwards@cpan.org> >>, Joerg Meltzer, C<< <joerg@joergmeltzer.de> >> for great patches to WWW::Shorten:Bitly which this module is based on.

=back

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (c) 2009 Pankaj Jain, All Rights Reserved L<http://blog.linosx.com>.

=item Copyright (c) 2009 Teknatus Solutions LLC, All Rights Reserved L<http://www.teknatus.com>.

=back

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 SEE ALSO

L<perl>, L<WWW::Shorten>, L<http://yourls.org>.

=cut

1; # End of WWW::Shorten::Yourls
