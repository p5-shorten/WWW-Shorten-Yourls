# NAME

WWW::Shorten::Yourls - Interface to shortening URLs using [http://yourls.org](http://yourls.org)

# SYNOPSIS

The traditional way, using the [WWW::Shorten](https://metacpan.org/pod/WWW::Shorten) interface:

    use strict;
    use warnings;

    use WWW::Shorten::Yourls;
    # use WWW::Shorten 'Yourls';  # or, this way

    # if you have a config file with your credentials:
    my $short_url = makeashorterlink('http://www.foo.com/some/long/url');
    my $long_url  = makealongerlink($short_url);
    # otherwise
    my $short = makeashorterlink('http://www.foo.com/some/long/url', {
        username => 'username',
        password => 'password',
        server => 'https://yourls.org/yourls-api.php',
        ...
    });

Or, the Object-Oriented way:

    use strict;
    use warnings;
    use Data::Dumper;
    use Try::Tiny qw(try catch);
    use WWW::Shorten::Yourls;

    my $yourls = WWW::Shorten::Yourls->new(
        username => 'username',
        password => 'password',
        signature => 'adflkdga234252lgka',
        server => 'https://yourls.org/yourls-api.php', # default
    );
    try {
        my $res = $yourls->shorten(longUrl => 'http://google.com/');
        say Dumper $res;
        # {
        #    message => "http://google.com/ added to database",
        #    shorturl => "https://yourls.org/4",
        #    status => "success",
        #    statusCode => 200,
        #    title => "Google",
        #    url => {
        #        date => "2017-02-08 02:34:37",
        #        ip => "192.168.0.1",
        #        keyword => 4,
        #        title => "Google",
        #        url => "http://google.com/"
        #    }
        # }
    }
    catch {
        die("Oh, no! $_");
    };

# DESCRIPTION

A Perl interface to the [Yourls.org API](http://yourls.org/#API).

You can either use the traditional (non-OO) interface provided by [WWW::Shorten](https://metacpan.org/pod/WWW::Shorten).
Or, you can use the OO interface that provides you with more functionality.

# FUNCTIONS

In the non-OO form, [WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls) makes the following functions available.

## makeashorterlink

    my $short_url = makeashorterlink('https://some_long_link.com');
    # OR
    my $short_url = makeashorterlink('https://some_long_link.com', {
        username => 'foo',
        password => 'bar',
        # any other attribute can be set as well.
    });

The function `makeashorterlink` will call the [Yourls Server](http://yourls.org) web site,
passing it your long URL and will return the shorter version.

[http://yourls.org](http://yourls.org) requires the use of a user account to shorten links.

## makealongerlink

    my $long_url = makealongerlink('http://yourls.org/22');
    # OR
    my $long_url = makealongerlink('http://yourls.org/22', {
        username => 'foo',
        password => 'bar',
        # any other attribute can be set as well.
    });

The function `makealongerlink` does the reverse. `makealongerlink`
will accept as an argument either the full URL or just the identifier.

If anything goes wrong, either function will die.

# ATTRIBUTES

In the OO form, each [WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls) instance makes the following
attributes available.

## password

    my $password = $yourls->password;
    $yourls = $yourls->password('some_secret'); # method chaining

Gets or sets the `password`. This is used along with the
["username" in WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls#username) attribute.  Credentials are sent to the server
upon each and every request.

## server

    my $server = $yourls->server;
    $yourls = $yourls->server(
        URI->new('https://yourls.org/yourls-api.php')
    ); # method chaining

Gets or sets the `server`. This is full and absolute path to the server and
`yourls-api.php` endpoint.

## signature

    my $signature = $yourls->signature;
    $signature = $yourls->signature('abcdef123'); # method chaining

Gets or sets the `signature`. If the `signature` attribute is set, the
["userna,e" in WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls#userna-e) and ["password" in WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls#password) attributes
are ignored on each request and instead the `signature` is sent.
See the [Password-less API](https://github.com/YOURLS/YOURLS/wiki/PasswordlessAPI)
documentation for more details.

## username

    my $username = $yourls->username;
    $yourls = $yourls->username('my_username'); # method chaining

Gets or sets the `username`. This is used along with the
["password" in WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls#password) attribute.  Credentials are sent to the server
upon each and every request.

# METHODS

In the OO form, [WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls) makes the following methods available.

## new

    my $yourls = WWW::Shorten::Yourls->new(
        username => 'username',
        password => 'password',
        signature => 'adflkdga234252lgka',
        server => 'https://yourls.org/yourls-api.php', # default
    );

The constructor can take any of the attributes above as parameters.

Any or all of the attributes can be set in your configuration file. If you have
a configuration file and you pass parameters to `new`, the parameters passed
in will take precedence.

## clicks

    my $clicks = $yourls->clicks(shorturl => "https://yourls.org/5");
    say Dumper $clicks;
    # {
    #    link => {
    #        clicks => 0,
    #        ip => "192.168.0.1",
    #        shorturl => "http://yourls.org/5",
    #        timestamp => "2017-02-08 02:37:24",
    #        title => "Google",
    #        url => "http://www.google.com"
    #    },
    #    message => "success",
    #    statusCode => 200
    # }

Get the `url-stats` or number of `clicks` for a given URL made shorter using
the [Yourls API](http://yourls.org/#API).
Returns a hash reference or dies. Make use of [Try::Tiny](https://metacpan.org/pod/Try::Tiny).

## expand

    my $long = $yourls->expand(shorturl => "https://yourls.org/5");
    say $long->{longurl};
    # http://www.google.com
    say Dumper $long;
    # {
    #    keyword => 4,
    #    longurl => "http://www.google.com",
    #    message => "success",
    #    shorturl => "http://jupiter/yourls/5",
    #    statusCode => 200,
    #    title => "Google"
    # }

Expand a URL using the [Yourls API](http://yourls.org/#API).
Returns a hash reference or dies. Make use of [Try::Tiny](https://metacpan.org/pod/Try::Tiny).

## shorten

    my $short = $yourls->shorten(
        url => "http://google.com/", # required.
    );
    say $short->{shorturl};
    # https://yourls.org/4
    say Dumper $short;
    # {
    #    message => "http://google.com/ added to database",
    #    shorturl => "https://yourls.org/4",
    #    status => "success",
    #    statusCode => 200,
    #    title => "Google",
    #    url => {
    #        date => "2017-02-08 02:34:37",
    #        ip => "192.168.0.1",
    #        keyword => 4,
    #        title => "Google",
    #        url => "http://google.com/"
    #    }
    # }

Shorten a URL using the [Yourls API](http://yourls.org/#API).
Returns a hash reference or dies. Make use of [Try::Tiny](https://metacpan.org/pod/Try::Tiny).

# CONFIG FILES

`$HOME/.yourls` or `_yourls` on Windows Systems.

You may omit `USER` and `PASSWORD` in the constructor if you set them in the
`.yourls` config file on separate lines using the syntax:

    username=username
    password=password
    server=https://yourls.org/yourls-api.php
    signature=foobarbaz123

Set any or all ["ATTRIBUTES" in WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls#ATTRIBUTES) in your config file in your
home directory. Each `key=val` setting should be on its own line. If any
parameters are then passed to the ["new" in WWW::Shorten::Yourls](https://metacpan.org/pod/WWW::Shorten::Yourls#new) constructor, those
parameter values will take precedence over these.

# AUTHOR

Pankaj Jain, <`pjain@cpan.org`>

# CONTRIBUTORS

- Chase Whitener <`capoeirab@cpan.org`>
- Michiel Beijen <`michielb@cpan.org`>

# LICENSE AND COPYRIGHT

Copyright (c) 2009 Pankaj Jain, All Rights Reserved [http://blog.linosx.com](http://blog.linosx.com).

Copyright (c) 2009 Teknatus Solutions LLC, All Rights Reserved [http://www.teknatus.com](http://www.teknatus.com).

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
