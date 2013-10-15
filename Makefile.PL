use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HTTPFast',
    VERSION_FROM      => 'lib/HTTPFast.pm',
    PREREQ_PM         => {
    }, # e.g., Module::Name => 1.1
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/Mons/httpfast',
            repository => 'https://github.com/Mons/httpfast',
            bugtracker => 'https://github.com/Mons/httpfast/issues',
        }
    },
    ABSTRACT_FROM  => 'lib/HTTPFast.pm',
    AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>',
    LIBS              => [],
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => '$(O_FILES)',
    LICENSE           => 'artistic',
);


