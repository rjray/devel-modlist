#
# Read the manual page from the pod at end for details.
#
# Generate a list of modules used by a perl script that has just run.
#
package Devel::Modlist;

# Uncomment only for syntax checking-- no pragmas in production use
#use strict;

# Suppress warnings without using the vars pragma
local ($Devel::Modlist::VERSION, $Devel::Modlist::revision);
$Devel::Modlist::VERSION = '0.3';
$Devel::Modlist::revision = do { my @r=(q$Revision$=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

sub report;

sub import
{
    shift(@_); # Lose the leading "classname" value

    grep($options{$_} = 1, @_);
}

sub DB::DB
{
    if ($options{stop})
    {
        report;
        exit;
    }
}

sub report
{
    return if $reported;

    local $!;
    $^W = 0;
    my $pkg;
    my $inc;
    my $format;
    my $fh = $options{stdout} ? 'STDOUT' : 'STDERR';
    $DB::trace = 0 if ($DB::trace);
    my %files = %INC;
    if ($options{nocore})
    {
        require Config; # Won't have to worry about grep'ing out this one :-)
        for my $lib ($Config::Config{installprivlib},
                     $Config::Config{installarchlib})
        {
            for (keys %files)
            {
                delete $files{$_} if ("$lib/$_" eq $files{$_});
            }
        }
    }
    if ($options{noversion} || $options{path})
    {
        $format = "%s\n";
    }
    else
    {
        $format = "%-20s %6s\n";
    }
    for $inc (sort keys %files)
    {
        next if ($inc =~ /\.(al|ix)$/);
        ($pkg = $inc) =~ s/\.pm$//;
        $pkg =~ s/\//::/g;
        next if ($pkg eq __PACKAGE__); # After all...
        my $version = ${"$pkg\::VERSION"} || '';
        if ($options{path})
        {
            printf $fh $format, $files{$inc};
        }
        else
        {
            printf $fh $format, $pkg, $version;
        }
    }

    $reported++;
}

END { report }

1;

__END__

=head1 NAME

Devel::Modlist - Perl extension to collect module use information

=head1 SYNOPSIS

    perl -d:Modlist script.pl

=head1 DESCRIPTION

The B<Devel::Modlist> utility is provided as a means by which to get a quick
run-down on which libraries and modules are being utilized by a given script.

Just as compiler systems like I<gcc> provide dependancy information via
switches such as C<-M>, B<Devel::Modlist> is intended to assist script authors
in preparing dependancy information for potential users of their scripts.

=head1 USAGE

Usage of B<Devel::Modlist> is simple. The primary method of invocation is to
use the C<-d> option of Perl:

    perl -d:Modlist script.pl

Alternately, one could use the C<-M> option:

    perl -MDevel::Modlist script.pl

In the case of this module, the two are identical save for the amount of
typing (and option passing, see below). It is I<not> recommended that this
module be loaded directly by a script via the B<use> keyword, as that would
cause the dependancy reporting after I<every> invocation until it was removed
from the code.

=head1 OPTIONS

The following options may be specified to the package on the command
line. Current (as of February 2000) Perl versions (release version up to
5.00503 and development version up to 5.5.660) cannot accept options to
the C<-d:> flag as with the C<-M> flag. Thus, to pass an option one must use:

    perl -MDevel::Modlist=option1[,option2,...]

Unfortunately, this inhibits the B<stop> option detailed below. To use this
option, an invocation of:

    perl -d:Modlist -MDevel::Modlist=option1[,option2,...]

does the trick, as the first invocation puts the interpreter in debugging mode
(necessary for B<stop> to work) while the second causes the options to be
parsed and recorded by B<Devel::Modlist>.

=over

=item nocore

Suppress the display of those modules that are a part of the Perl core. This
is dependant on the Perl private library area not being an exact substring of
the site-dependant library. The build process checks this for you prior to
install.

=item noversion

Suppress the inclusion of version information with the module names. If a
module has defined its version by means of the accepted standard of
declaring a variable C<$VERSION> in the package namespace, B<Devel::Modlist>
finds this and includes it in the report by default. Use this option to
override that default.

=item path

Display the path and filename of each module instead of the module name. Useful
for producing lists for later input to tools such as B<rpm>.

=item stop

Exit before the first actual program line is executed. This provides for fetching
the dependancy list without actually running the full program. This has a drawback:
if the program uses any of B<require>, B<eval> or other such mechanisms to load
libraries after the compilation phase, these will not be reported.

=back

=head1 AUTHOR

Randy J. Ray <rjray@tsoft.com>, using idea and prototype code provided by
Tim Bunce <Tim.Bunce@ig.co.uk>

=head1 SEE ALSO

perl(1).

=cut
