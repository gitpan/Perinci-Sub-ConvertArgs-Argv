package Perinci::Sub::ConvertArgs::Argv;

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(convert_args_to_argv);

our $VERSION = '0.04'; # VERSION

our %SPEC;

sub _json {
    require JSON;
    state $json = JSON->new->allow_nonref;
    $json->encode($_[0]);
}

sub _encode {
    ref($_[0]) ? _json($_[0]) : $_[0];
}

$SPEC{convert_args_to_argv} = {
    v => 1.1,
    summary => 'Convert hash arguments to command-line options (and arguments)',
    description => <<'_',

Convert hash arguments to command-line arguments. This is the reverse of
`Perinci::Sub::GetArgs::Argv::get_args_from_argv`.

Note: currently the function expects schemas in metadata to be normalized
already.

_
    args => {
        args => {req=>1, schema=>'hash*', pos=>0},
        meta => {req=>0, schema=>'hash*', pos=>1},
        use_pos => {
            summary => 'Whether to use positional arguments',
            schema  => 'bool',
            description => <<'_',

For example, given this metadata:

    {
        v => 1.1,
        args => {
          arg1 => {pos=>0, req=>1},
          arg2 => {pos=>1},
          arg3 => {},
        },
    }

then under `use_pos=0` the hash `{arg1=>1, arg2=>2, arg3=>'a b'}` will be
converted to `['--arg1', 1, '--arg2', 2, '--arg3', 'a b']`. Meanwhile if
`use_pos=1` the same hash will be converted to `[1, 2, '--arg3', 'a b']`.

_
        },
    },
};
sub convert_args_to_argv {
    my %fargs = @_;

    my $iargs = $fargs{args} or return [400, "Please specify args"];
    my $meta  = $fargs{meta} // {v=>1.1};
    my $args_prop = $meta->{args} // {};

    my $v = $meta->{v} // 1.0;
    return [412, "Sorry, only metadata version 1.1 is supported (yours: $v)"]
        unless $v == 1.1;

    my @argv;
    my %iargs = %$iargs; # copy 'coz we will delete them one by one as we fill

    if ($fargs{use_pos}) {
        for (sort {$args_prop->{$a}{pos} <=> $args_prop->{$b}{pos}}
                 grep {defined $args_prop->{$_}{pos}} keys %iargs) {
            $argv[ $args_prop->{$_}{pos} ] = _encode($iargs{$_});
            delete $iargs{$_};
        }
    }

    for (sort keys %iargs) {
        my $is_bool = $args_prop->{$_}{schema} &&
            $args_prop->{$_}{schema}[0] eq 'bool';
        my $opt = $_; $opt =~ s/_/-/g;
        my $dashopt = length($opt) > 1 ? "--$opt" : "-$opt";
        if ($is_bool) {
            if ($iargs{$_}) {
                push @argv, $dashopt;
            } else {
                push @argv, "--no$opt";
            }
        } else {
            if (ref $iargs{$_}) {
                push @argv, "$dashopt-json", _encode($iargs{$_});
            } else {
                push @argv, $dashopt, "$iargs{$_}";
            }
        }
    }
    [200, "OK", \@argv];
}

1;
#ABSTRACT: Convert hash arguments to command-line options (and arguments)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::ConvertArgs::Argv - Convert hash arguments to command-line options (and arguments)

=head1 VERSION

This document describes version 0.04 of Perinci::Sub::ConvertArgs::Argv (from Perl distribution Perinci-Sub-ConvertArgs-Argv), released on 2014-07-18.

=head1 SYNOPSIS

 use Perinci::Sub::ConvertArgs::Argv qw(convert_args_to_argv);

 my $res = convert_args_to_argv(args=>\%args, meta=>$meta, ...);

=head1 FUNCTIONS


=head2 convert_args_to_argv(%args) -> [status, msg, result, meta]

Convert hash arguments to command-line options (and arguments).

Convert hash arguments to command-line arguments. This is the reverse of
C<Perinci::Sub::GetArgs::Argv::get_args_from_argv>.

Note: currently the function expects schemas in metadata to be normalized
already.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args>* => I<hash>

=item * B<meta> => I<hash>

=item * B<use_pos> => I<bool>

Whether to use positional arguments.

For example, given this metadata:

    {
        v => 1.1,
        args => {
          arg1 => {pos=>0, req=>1},
          arg2 => {pos=>1},
          arg3 => {},
        },
    }

then under C<use_pos=0> the hash C<{arg1=>1, arg2=>2, arg3=>'a b'}> will be
converted to C<['--arg1', 1, '--arg2', 2, '--arg3', 'a b']>. Meanwhile if
C<use_pos=1> the same hash will be converted to C<[1, 2, '--arg3', 'a b']>.

=back

Return value:

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

 (any)

=head1 TODO

Option to use/prefer cmdline_aliases.

=head1 SEE ALSO

L<Perinci::CmdLine>, which uses this module for presenting command-line
examples.

L<Perinci::Sub::GetArgs::Argv> which does the reverse: converting command-line
arguments to hash.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-ConvertArgs-Argv>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Sub-ConvertArgs-Argv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-ConvertArgs-Argv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
