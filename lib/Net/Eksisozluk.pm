package Net::Eksisozluk;

use 5.014002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

#To be developed.

1;
__END__

=head1 NAME

Net::Eksisozluk - Perl extension to grab entries and lists of entries from eksisozluk (eksisozluk.com).

=head1 SYNOPSIS

  use Net::Eksisozluk;

=head1 DESCRIPTION

This module provides a simple command line interface for eksisozluk,
which is a user-based web dictionary, a famous web site in Turkey since 1999.
You can get "debe" list (list of most voted entries from yesterday) by using
this module. You can also get details of an entry by only giving the entry id.


=head2 EXPORT

None by default.



=head1 SEE ALSO

Follow and/or contribute to the development of this package at <http://www.github.com/kyzn/net-eksisozluk>.

=head1 AUTHOR

Kivanc Yazan <lt>k@kyzn.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kivanc Yazan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
