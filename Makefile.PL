use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Shorten::Yourls',
    AUTHOR              => 'Pankaj Jain <pjain@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Shorten/Yourls.pm',
    ABSTRACT_FROM       => 'lib/WWW/Shorten/Yourls.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('MIN_PERL_VERSION'=> '5.6.1')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'WWW::Shorten' => 1.90,
        'XML::Simple'  => 2.18,
        'JSON::Any'    => 1.18,
    },
    PREREQ_PRINT        => 1,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Shorten-Yourls-*' },
);
