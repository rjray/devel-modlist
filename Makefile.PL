use ExtUtils::MakeMaker;

# $Id$

WriteMakefile(
              (MM->can('signature_target') ? (SIGN => 1) : ()),
              NAME         => 'Devel::Modlist',
              VERSION_FROM => 'Modlist.pm', # finds $VERSION
              clean        => { FILES =>
                                'pod2html-* *.html blibdirs META.yml' },
             );
