use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Ganeti',
    AUTHOR              => q{Joris <jorisd@gmail.com>},
    VERSION_FROM        => 'lib/Net/Ganeti.pm',
    ABSTRACT_FROM       => 'lib/Net/Ganeti.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Ganeti-*' },
);
