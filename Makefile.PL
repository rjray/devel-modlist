use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Config q/%Config/;

#
# If your core library dir is a direct ancestor of your site_lib dir
# (for example, /usr/local/lib/perl and /usr/local/lib/perl/site_perl)
# then 'nocore' will also chop out most (if not all) of the local modules.
#
if (length($Config{installprivlib}) < length($Config{installsitelib}))
{
    $warn = 1 if (substr($Config{installsitelib}, 0,
                         length($Config{installprivlib}))
                  eq $Config{installprivlib});
}

$warn &&
    warn "Your Perl core library directory ($Config{installprivlib})
is a substring of your site lib directory ($Config{installsitelib}).
The 'nocore' run-time option will be no use to you.
";

WriteMakefile(
              'NAME'         => 'Devel::Modlist',
              'VERSION_FROM' => 'Modlist.pm', # finds $VERSION
             );
