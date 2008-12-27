package autodie::exception;
use 5.008;
use strict;
use warnings;
use Carp qw(croak);

our $DEBUG = 0;

use overload
    q{""} => "stringify"
;

# Overload smart-match only if we're using 5.10

use if ($] >= 5.010), overload => '~~'  => "matches";

our $VERSION = '1.997';

my $PACKAGE = __PACKAGE__;  # Useful to have a scalar for hash keys.

=head1 NAME

autodie::exception - Exceptions from autodying functions.

=head1 SYNOPSIS

    eval {
        use autodie;

        open(my $fh, '<', 'some_file.txt');

        ...
    };

    if (my $E = $@) {
        say "Ooops!  ",$E->caller," had problems: $@";
    }


=head1 DESCRIPTION

When an L<autodie> enabled function fails, it generates an
C<autodie::exception> object.  This can be interrogated to
determine further information about the error that occurred.

This document is broken into two sections; those methods that
are most useful to the end-developer, and those methods for
anyone wishing to subclass or get very familiar with
C<autodie::exception>.

=head2 Common Methods

These methods are intended to be used in the everyday dealing
of exceptions.

The following assume that the error has been copied into
a separate scalar:

    if ($E = $@) {
        ...
    }

This is not required, but is recommended in case any code
is called which may reset or alter C<$@>.

=cut

=head3 args

    my $array_ref = $E->args;

Provides a reference to the arguments passed to the subroutine
that died.

=cut

sub args        { return $_[0]->{$PACKAGE}{args}; }

=head3 function

    my $sub = $E->function;

The subroutine (including package) that threw the exception.

=cut

sub function   { return $_[0]->{$PACKAGE}{function};  }

=head3 file

    my $file = $E->file;

The file in which the error occurred (eg, C<myscript.pl> or
C<MyTest.pm>).

=cut

sub file        { return $_[0]->{$PACKAGE}{file};  }

=head3 package

    my $package = $E->package;

The package from which the exceptional subroutine was called.

=cut

sub package     { return $_[0]->{$PACKAGE}{package}; }

=head3 caller

    my $caller = $E->caller;

The subroutine that I<called> the exceptional code.

=cut

sub caller      { return $_[0]->{$PACKAGE}{caller};  }

=head3 line

    my $line = $E->line;

The line in C<< $E->file >> where the exceptional code was called.

=cut

sub line        { return $_[0]->{$PACKAGE}{line};  }

=head3 errno

    my $errno = $E->errno;

The value of C<$!> at the time when the exception occurred.

B<NOTE>: This method will leave the main C<autodie::exception> class
and become part of a role in the future.  You should only call
C<errno> for exceptions where C<$!> would reasonably have been
set on failure.

=cut

# TODO: Make errno part of a role.  It doesn't make sense for
# everything.

sub errno       { return $_[0]->{$PACKAGE}{errno}; }

=head3 matches

    if ( $e->matches('open') ) { ... }

    if ( $e ~~ 'open' ) { ... }

C<matches> is used to determine whether a
given exception matches a particular role.  On Perl 5.10,
using smart-match (C<~~>) with an C<autodie::exception> object
will use C<matches> underneath.

An exception is considered to match a string if:

=over 4

=item *

For a string not starting with a colon, the string exactly matches the
package and subroutine that threw the exception.  For example,
C<MyModule::log>.  If the string does not contain a package name,
C<CORE::> is assumed.

=item *

For a string that does start with a colon, if the subroutine
throwing the exception I<does> that behaviour.  For example, the
C<CORE::open> subroutine does C<:file>, C<:io> and C<:all>.

See L<autodie/CATEGORIES> for futher information.

=back

=cut

{
    my (%cache);

    sub matches {
        my ($this, $that) = @_;

        # XXX - Handle references
        croak "UNIMPLEMENTED" if ref $that;

        my $sub = $this->function;

        if ($DEBUG) {
            my $sub2 = $this->function;
            warn "Smart-matching $that against $sub / $sub2\n";
        }

        # Direct subname match.
        return 1 if $that eq $sub;
        return 1 if $that !~ /:/ and "CORE::$that" eq $sub;
        return 0 if $that !~ /^:/;

        # Cached match / check tags.
        require Fatal;

        if (exists $cache{$sub}{$that}) {
            return $cache{$sub}{$that};
        }

        # This rather awful looking line checks to see if our sub is in the
        # list of expanded tags, caches it, and returns the result.

        return $cache{$sub}{$that} = grep { $_ eq $sub } @{ $this->_expand_tag($that) };
    }
}

# This exists primarily so that child classes can override or
# augment it if they wish.

sub _expand_tag {
    my ($this, @args) = @_;

    return Fatal->_expand_tag(@args);
}

=head2 Advanced methods

The following methods, while usable from anywhere, are primarily
intended for developers wishing to subclass C<autodie::exception>,
write code that registers custom error messages, or otherwise
work closely with the C<autodie::exception> model.

=cut

# The table below records customer formatters.
# TODO - Should this be a package var instead?
# TODO - Should these be in a completely different file, or
#        perhaps loaded on demand?  Most formatters will never
#        get used in most programs.

my %formatter_of = (
    'CORE::close'   => \&_format_close,
    'CORE::open'    => \&_format_open,
    'CORE::dbmopen' => \&_format_dbmopen,
    'CORE::flock'   => \&_format_flock,
);

# TODO: Our tests only check LOCK_EX | LOCK_NB is properly
# formatted.  Try other combinations and ensure they work
# correctly.

sub _format_flock {
    my ($this) = @_;

    require Fcntl;

    my $filehandle = $this->args->[0];
    my $raw_mode   = $this->args->[1];

    my $mode_type;
    my $lock_unlock;

    if ($raw_mode & Fcntl::LOCK_EX() ) {
        $lock_unlock = "lock";
        $mode_type = "for exclusive access";
    }
    elsif ($raw_mode & Fcntl::LOCK_SH() ) {
        $lock_unlock = "lock";
        $mode_type = "for shared access";
    }
    elsif ($raw_mode & Fcntl::LOCK_UN() ) {
        $lock_unlock = "unlock";
        $mode_type = "";
    }
    else {
        # I've got no idea what they're trying to do.
        $lock_unlock = "lock";
        $mode_type = "with mode $raw_mode";
    }

    my $cooked_filehandle;

    if ($filehandle and not ref $filehandle) {

        # A package filehandle with a name!

        $cooked_filehandle = " $filehandle";
    }
    else {
        # Otherwise we have a scalar filehandle.

        $cooked_filehandle = '';

    }

    local $! = $this->errno;

    return "Can't $lock_unlock filehandle$cooked_filehandle $mode_type: $!";

}

# Default formatter for CORE::dbmopen
sub _format_dbmopen {
    my ($this) = @_;
    my @args   = @{$this->args};

    # TODO: Presently, $args flattens out the (usually empty) hash
    # which is passed as the first argument to dbmopen.  This is
    # a bug in our args handling code (taking a reference to it would
    # be better), but for the moment we'll just examine the end of
    # our arguments list for message formatting.

    my $mode = $args[-1];
    my $file = $args[-2];

    # If we have a mask, then display it in octal, not decimal.
    # We don't do this if it already looks octalish, or doesn't
    # look like a number.

    if ($mode =~ /^[^\D0]\d+$/) {
        $mode = sprintf("0%lo", $mode);
    };

    local $! = $this->errno;

    return "Can't dbmopen(%hash, '$file', $mode): '$!'";
}

# Default formatter for CORE::close

sub _format_close {
    my ($this) = @_;
    my $close_arg = $this->args->[0];

    local $! = $this->errno;

    # If we've got an old-style filehandle, mention it.
    if ($close_arg and not ref $close_arg) {
        return "Can't close filehandle '$close_arg': '$!'";
    }

    # TODO - This will probably produce an ugly error.  Test and fix.
    return "Can't close($close_arg) filehandle: '$!'";

}

# Default formatter for CORE::open

use constant _FORMAT_OPEN => "Can't open '%s' for %s: '%s'";

sub _format_open_with_mode {
    my ($this, $mode, $file, $error) = @_;

    my $wordy_mode;

    if    ($mode eq '<')  { $wordy_mode = 'reading';   }
    elsif ($mode eq '>')  { $wordy_mode = 'writing';   }
    elsif ($mode eq '>>') { $wordy_mode = 'appending'; }

    return sprintf _FORMAT_OPEN, $file, $wordy_mode, $error if $wordy_mode;

    Carp::confess("Internal autodie::exception error: Don't know how to format mode '$mode'.");

}

sub _format_open {
    my ($this) = @_;

    my @open_args = @{$this->args};

    # Use the default formatter for single-arg and many-arg open
    if (@open_args <= 1 or @open_args >= 4) {
        return $this->format_default;
    }

    # For two arg open, we have to extract the mode
    if (@open_args == 2) {
        my ($fh, $file) = @open_args;

        if (ref($fh) eq "GLOB") {
            $fh = '$fh';
        }

        my ($mode) = $file =~ m{
            ^\s*                # Spaces before mode
            (
                (?>             # Non-backtracking subexp.
                    <           # Reading
                    |>>?        # Writing/appending
                )
            )
            [^&]                # Not an ampersand (which means a dup)
        }x;

        # Have a funny mode?  Use the default format.
        return $this->format_default if not defined $mode;

        # Localising $! means perl make make it a pretty error for us.
        local $! = $this->errno;

        return $this->_format_open_with_mode($mode, $file, $!);
    }

    # Here we must be using three arg open.

    my $file = $open_args[2];

    local $! = $this->errno;

    my $mode = $open_args[1];

    local $@;

    my $msg = eval { $this->_format_open_with_mode($mode, $file, $!); };

    return $msg if $msg;

    # Default message (for pipes and odd things)

    return "Can't open '$file' with mode '$open_args[1]': '$!'";
}

=head3 register

    autodie::exception->register( 'CORE::open' => \&mysub );

The C<register> method allows for the registration of a message
handler for a given subroutine.  The full subroutine name including
the package should be used.

Registered message handlers will receive the C<autodie::exception>
object as the first parameter.

=cut

sub register {
    my ($class, $symbol, $handler) = @_;

    croak "Incorrect call to autodie::register" if @_ != 3;

    $formatter_of{$symbol} = $handler;

}

=head3 add_file_and_line

    say "Problem occurred",$@->add_file_and_line;

Returns the string C< at %s line %d>, where C<%s> is replaced with
the filename, and C<%d> is replaced with the line number.

Primarily intended for use by format handlers.

=cut

# Simply produces the file and line number; intended to be added
# to the end of error messages.

sub add_file_and_line {
    my ($this) = @_;

    return sprintf(" at %s line %d\n", $this->file, $this->line);
}

=head3 stringify

    say "The error was: ",$@->stringify;

Formats the error as a human readable string.  Usually there's no
reason to call this directly, as it is used automatically if an
C<autodie::exception> object is ever used as a string.

Child classes can override this method to change how they're
stringified.

=cut

sub stringify {
    my ($this) = @_;

    my $call        =  $this->function;

    if ($DEBUG) {
        my $dying_pkg   = $this->package;
        my $sub   = $this->function;
        my $caller = $this->caller;
        warn "Stringifing exception for $dying_pkg :: $sub / $caller / $call\n";
    }

    # TODO - This isn't using inheritance.  Should it?
    if ( my $sub = $formatter_of{$call} ) {
        return $sub->($this) . $this->add_file_and_line;
    }

    return $this->format_default;

}

=head3 format_default

    my $error_string = $E->format_default;

This produces the default error string for the given exception,
I<without using any registered message handlers>.  It is primarily
intended to be called from a message handler when they have
been passed an exception they don't want to format.

Child classes can override this method to change how default
messages are formatted.

=cut

# TODO: This produces ugly errors.  Is there any way we can
# dig around to find the actual variable names?  I know perl 5.10
# does some dark and terrible magicks to find them for undef warnings.

sub format_default {
    my ($this) = @_;

    my $call        =  $this->function;

    local $! = $this->errno;

    # TODO: This is probably a good idea for CORE, is it
    # a good idea for other subs?

    # Trim package name off dying sub for error messages.
    $call =~ s/.*:://;

    # Walk through all our arguments, and...
    #
    #   * Replace undef with the word 'undef'
    #   * Replace globs with the string '$fh'
    #   * Quote all other args.

    my @args = @{ $this->args() };

    foreach my $arg (@args) {
       if    (not defined($arg))   { $arg = 'undef' }
       elsif (ref($arg) eq "GLOB") { $arg = '$fh'   }
       else                        { $arg = qq{'$arg'} }
    }

    # Format our beautiful error.

    return "Can't $call(".  join(q{, }, @args) . "): $!" .
        $this->add_file_and_line;

    # TODO - Handle user-defined errors from hash.

    # TODO - Handle default error messages.

}

=head3 new

    my $error = autodie::exception->new(
        args => \@_,
        function => "CORE::open",
        errno => $!,
    );


Creates a new C<autodie::exception> object.  Normally called
directly from an autodying function.  The C<function> argument
is required, its the function we were trying to call that
generated the exception.  The C<args> parameter is optional.

The C<errno> value is optional.  In versions of C<autodie::exception>
1.99 and earlier the code would try to automatically use the
current value of C<$!>, but this was unreliable and is no longer
supported.

Atrributes such as package, file, and caller are determined
automatically, and cannot be specified.

=cut

sub new {
    my ($class, @args) = @_;

    my $this = {};

    bless($this,$class);

    # I'd love to use EVERY here, but it causes our code to die
    # because it wants to stringify our objects before they're
    # initialised, causing everything to explode.

    $this->_init(@args);

    return $this;
}

sub _init {

    my ($this, %args) = @_;

    # Capturing errno here is not necessarily reliable.
    my $original_errno = $!;

    our $init_called = 1;

    my $class = ref $this;

    # We're going to walk up our call stack, looking for the
    # first thing that doesn't look like our exception
    # code, autodie/Fatal, or some whacky eval.

    my ($package, $file, $line, $sub);

    my $depth = 0;

    while (1) {
        $depth++;

        ($package, $file, $line, $sub) = CORE::caller($depth);

        # Skip up the call stack until we find something outside
        # of the Fatal/autodie/eval space.

        next if $package->isa('Fatal');
        next if $package->isa($class);
        next if $package->isa(__PACKAGE__);
        next if $file =~ /^\(eval\s\d+\)$/;

        last;

    }

    $this->{$PACKAGE}{package} = $package;
    $this->{$PACKAGE}{file}    = $file;
    $this->{$PACKAGE}{line}    = $line;
    $this->{$PACKAGE}{caller}  = $sub;
    $this->{$PACKAGE}{package} = $package;

    $this->{$PACKAGE}{errno}   = $args{errno} || 0;

    $this->{$PACKAGE}{args}    = $args{args} || [];
    $this->{$PACKAGE}{function}= $args{function} or
              croak("$class->new() called without function arg");

    return $this;

}

1;

__END__

=head1 SEE ALSO

L<autodie>, L<autodie::exception::system>

=head1 LICENSE

Copyright (C)2008 Paul Fenwick

This is free software.  You may modify and/or redistribute this
code under the same terms as Perl 5.10 itself, or, at your option,
any later version of Perl 5.

=head1 AUTHOR

Paul Fenwick E<lt>pjf@perltraining.com.auE<gt>