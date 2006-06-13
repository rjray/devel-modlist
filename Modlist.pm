#
# Read the manual page from the pod at end for details.
#
# Generate a list of modules used by a perl script that has just run.
#
package Devel::Modlist;

require 5.6.0;
use strict;

# Suppress warnings without using the vars pragma
our ($VERSION, $reported, %options);
$VERSION = '0.7';

BEGIN
{
    # This defines a simple class that CPAN will use if it is requested
    package Devel::Modlist::QuietCPAN;

    sub myprint { }
    sub mywarn  { shift; CPAN::Shell->mywarn(@_); }
    sub mydie   { shift; CPAN::Shell->mydie(@_); }
}

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

    unless (keys %options)
    {
        grep($options{$_} = 1,
             split(/[, ]/, ($ENV{'Devel::Modlist'} || $ENV{Devel__Modlist})));
    }
    # The 'noreport' option is not documented in the pod. It is only used by
    # the pod_coverage.t test suite, to prevent the loading of this module
    # from triggering a usage report.
    return if $options{noreport};

    local $!;
    $^W = 0;
    my $pkg;
    my $inc;
    my $format;
    my $fh = $options{stdout} ? 'STDOUT' : 'STDERR';
    $DB::trace = 0 if ($DB::trace);
    my %files = %INC;
    # We use this ourselves, so delete it all the time. They shouldn't need
    # to see it here anyway.
    delete $files{'strict.pm'};

    # Anything required from here on won't show up unless it was already there
    require File::Spec;
    my @order = (0 .. 2);
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
    if ($options{cpan} or $options{cpandist})
    {
        require CPAN;

        # Defeat "used only once" warnings without using local() which breaks
        $CPAN::Frontend = $CPAN::Config->{index_expire} = '';
        $CPAN::Frontend = 'Devel::Modlist::QuietCPAN';
        CPAN::HandleConfig->load;
        # This is an arbitrary value to inhibit re-loading index files
        $CPAN::Config->{index_expire} = 300;
        my %seen_dist = ();
        my ($modobj, $cpan_file);

        for $inc (sort keys %files)
        {
            $pkg = join('::', File::Spec->splitdir($inc));
            $pkg =~ s/\.pm$//;
            $modobj = CPAN::Shell->expand('Module', $pkg) or next;
            $cpan_file = $modobj->cpan_file;
            if ($seen_dist{$cpan_file})
            {
                delete $files{$inc};
                next;
            }
            # Haven't seen it until now
            $seen_dist{$cpan_file}++;
            $files{$inc} = $cpan_file if $options{cpandist};
        }
    }
    # To prevent options being evaluated EVERY loop iteration, we set a format
    # and data ordering:
    if ($options{noversion} || $options{path} || $options{cpandist})
    {
        $format = "%s\n";
        @order = (2) if ($options{path} || $options{cpandist});
        # Only include the value (3rd) element
    }
    else
    {
        $format = "%-20s %6s\n";
        @order = (2, 1) if $options{path};
    }
    for $inc (sort keys %files)
    {
        # Disable refs-checking so we can read VERSION values
        no strict 'refs';

        next if ($inc =~ /\.(al|ix)$/);
        $pkg = join('::', File::Spec->splitdir($inc));
        $pkg =~ s/\.pm$//;
        next if ($pkg eq __PACKAGE__); # After all...
        my $version = ${"$pkg\::VERSION"} || '';
        printf $fh $format, ($pkg, $version, $files{$inc})[@order];
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

The following options may be specified to the package. These are specified either by:

    perl -MDevel::Modlist=option1[,option2,...]

or

    perl -d:Modlist=option1[,option2,...]

Options may also be given in an environment variable, which gets read at any
invocation in which there are B<no> options explicitly provided. If any
options are given in the invocation, then the environment variable is ignored. Two different names are recognized:

    Devel::Modlist
    Devel__Modlist

The latter is to accomodate shells that do not like the presence of C<::> in
an environment variable name.

The options:

=over

=item cpan

Reduce the resulting list of modules by using the data maintained in the local
I<CPAN> configuration area. The B<CPAN> module (see L<CPAN>) maintains a very
thorough representation of the contents of the archive, on a per-module basis.
Using this option means that if there are two or more modules that are parts
of the same distribution, only one will be reported (the one with the shortest
name). This is useful for generating a minimalist dependancy set that can in
turn be fed to the B<CPAN> C<install> command to ensure that all needed
modules are in fact present.

=item cpandist

This is identical to the option above, with the exception that it causes the
reported output to be the B<CPAN> filename rather than the module name in
the standard Perl syntax. This can also be fed to the B<CPAN> shell, but it
can also be used by other front-ends as a path component in fetching the
requisite file from an archive site. Since the name contains the version
number, this behaves as though I<noversion> (see below) was also set. If
both I<cpan> and I<cpandist> are set, this option (I<cpandist>) takes
precedence. If I<path> is also specified, this option again takes precedence.

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

Exit before the first actual program line is executed. This provides for
fetching the dependancy list without actually running the full program. This
has a drawback: if the program uses any of B<require>, B<eval> or other
such mechanisms to load libraries after the compilation phase, these will
not be reported.

=back

=head1 CAVEATS

Perl versions up to 5.6.0 cannot accept options to the C<-d:> flag as
with the C<-M> flag. Thus, to pass options one must use:

    perl -MDevel::Modlist=option1[,option2,...]

Unfortunately, this inhibits the B<stop> option detailed earlier. To use this
option, an invocation of:

    perl -d:Modlist -MDevel::Modlist=option1[,option2,...]

does the trick, as the first invocation puts the interpreter in debugging mode
(necessary for B<stop> to work) while the second causes the options to be
parsed and recorded by B<Devel::Modlist>.

Versions of Perl from 5.6.1 onwards allow options to be included with the
C<-d:Modlist> flag.

Because B<Devel::Modlist> uses the C<strict> pragma internally (as all modules
should), that pragma is always removed from the output to avoid generating a
false-positive.

=head1 AUTHOR

Randy J. Ray <rjray@blackperl.com>, using idea and prototype code provided by
Tim Bunce <Tim.Bunce@ig.co.uk>

=head1 SEE ALSO

perl(1).

=cut
