use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
              NAME         => 'Devel::Modlist',
              VERSION_FROM => 'Modlist.pm', # finds $VERSION
              clean        => { FILES =>
                                'pod2html-* *.html blibdirs META.yml' },
             );
