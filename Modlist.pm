package Devel::Modlist;

use strict;
use vars qw($VERSION $revision %options);

$VERSION = '0.1';
$revision = do { my @r=(q$Revision$=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

sub import
{
    shift(@_); # Lose the leading "classname" value

    grep($options{$_} = 1, @_);
}

sub DB::DB {}

END
{
    no strict 'refs';
    local $!;
    $^W = 0;
    my $pkg;
    my $inc;
    $DB::trace = 0;
    my %files = %INC;
    if ($options{nocore})
    {
        require Config; # Won't have to worry about grep'ing out this one :-)
        # 99.9% of the time, installprivlib will be a substr of installarchlib,
        # but it isn't *guaranteed* to be...
        for my $lib ($Config::Config{installprivlib},
                     $Config::Config{installarchlib})
        {
            for (keys %files)
            {
                delete $files{$_}
                    if (substr($files{$_}, 0, length $lib) eq $lib);
            }
        }
    }
    foreach $inc (sort keys %files)
    {
        next if ($inc =~ /\.(al|ix)$/);
        ($pkg = $inc) =~ s/\.pm$//;
        $pkg =~ s/\//::/g;
        next if ($pkg eq __PACKAGE__); # After all...
        my $version = ${"$pkg\::VERSION"} || '';
        printf "%-20s %6s\n", $pkg, $version;
    }
}

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
module be loaded directly by a script via the C<use> keyword, as that would
cause the dependancy reporting after I<every> invocation until it was removed
from the code.

=head1 OPTIONS

The following options may be specified to the package on the command
line. Current (as of February 1999) Perl versions (release version up to
5.00502 and development version up to 5.00554) cannot accept options to
the C<-d:> flag as with the C<-M> flag. Thus, to pass an option one must use:

    perl -MDevel::Modlist=option

=over

=item nocore

Suppress the display of those modules that are a part of the Perl core. This
is dependant on the Perl private library area not being an exact substring of
the site-dependant library. The build process checks this for you prior to
install.

=back

=head1 AUTHOR

Randy J. Ray <rjray@tsoft.com>, using idea and prototype code provided by
Tim Bunce <Tim.Bunce@ig.co.uk>

=head1 SEE ALSO

perl(1).

=cut
