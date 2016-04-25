# NAME

WWW::Shorten::Yourls - Interface to shortening URLs using [http://yourls.org](http://yourls.org)

# SYNOPSIS

[WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls) provides an easy interface for shortening URLs
using [http://yourls.org](http://yourls.org). In addition to shortening URLs, you can pull
statistics that [http://yourls.org](http://yourls.org) gathers regarding each shortened URL.

[WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls) provides two interfaces. The first is the common
`makeashorterlink` and `makealongerlink` that [WWW::Shorten](https://metacpan.org/pod/WWW::Shorten) provides.
However, due to the way the [http://yourls.org](http://yourls.org) API works, additional
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

# FUNCTIONS

## new

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

## makeashorterlink

The function `makeashorterlink` will call the API, passing it
your long URL and will return the shorter version.

A user id and password is required to shorten links.

    makeashorterlink($url,$uid,$passwd,$base);

## makealongerlink

The function `makealongerlink` does the reverse. `makealongerlink`
will accept as an argument either the full URL or just the identifier.

A user name and API Key are required.

If anything goes wrong, then the function will return `undef`.

    makealongerlink($url,$uid,$passwd,$base);

THIS IS NOT WORKING.

## shorten

Shorten a URL using [http://yourls.org](http://yourls.org). Calling the shorten method will
return the shortened URL but will also store it in your object instance
until the next call is made.

    my $url = "http://www.example.com";
    my $shortstuff = $yourls->shorten(URL => $url);

    print "yurl is " . $yourls->{url} . "\n";
    # or
    print "yurl is $shortstuff\n";

## expand

Expands a shortened URL to the original long URL.

## clicks

Get click-through information for a shortened URL. By
default, the method will use the value that's stored in
`$yourls->{url}`. To be sure you're getting info on the correct URL,
it's a good idea to set this value before getting any info on it.

THIS IS NOT WORKING.

## errors

THIS IS NOT WORKING.

## version

Gets the module version number

# FILES

$`HOME/.yourls` or `_yourls` on Windows Systems.

You may omit `USER` and `PASSWORD` in the constructor if you set them in the
`.yourls` config file on separate lines using the syntax:

    USER=username
    PASSWORD=password

# AUTHOR

Pankaj Jain, <`pjain@cpan.org`>

# CONTRIBUTORS

- Chase Whitener <`capoeirab@cpan.org`>
- Michiel Beijen <`michielb@cpan.org`>

# LICENSE AND COPYRIGHT

- Copyright (c) 2009 Pankaj Jain, All Rights Reserved [http://blog.linosx.com](http://blog.linosx.com).
- Copyright (c) 2009 Teknatus Solutions LLC, All Rights Reserved [http://www.teknatus.com](http://www.teknatus.com).

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# SEE ALSO

[perl](https://metacpan.org/pod/perl), [WWW::Shorten](https://metacpan.org/pod/WWW::Shorten), [http://yourls.org](http://yourls.org).
