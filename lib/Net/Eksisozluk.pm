package Net::Eksisozluk;

use 5.014002;
use strict;
use warnings;
use DateTime;
use LWP::Simple;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	get_entry_by_id

) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';


#Variables to be used throughout the program.
my $dt   = DateTime->now->set_time_zone('Europe/Istanbul'); 
#my $searchdate = $dt->subtract(days=>1)->ymd;
#my $filedate   = $dt->subtract(days=>1)->dmy;
#my $todaydate  = $dt->dmy;
my $link_stats="https://eksisozluk.com/istatistik/dunun-en-begenilen-entryleri";
my $link_entry="https://eksisozluk.com/entry/";
my $link_topic="https://eksisozluk.com/";
my $link_search = "?a=search&searchform.when.from=$searchdate";


sub get_entry_by_id{

	#Die if no arguments.
	if(scalar(@_)<1){
		die "No argument passed to get_entry_by_id";
	}

	#Get id from arguments otherwise.
	my $id = $_[0];

	#Test if satisfies id number format.
	if($id !~ /^\d{1,9}$/ || $id==0){
		die "Argument passed to the get_entry_by_id is of wrong format";
	}else{
		
		#Get the entry file.
		my $ua = LWP::UserAgent->new;
		$ua->timeout(10);
		$ua->env_proxy;
		my $response = $ua->get("$link_entry$id");
		my $downloaded_entry_file;
		
		if($response->is_success){
			$downloaded_entry_file = $response->decoded_content;
		}else{
			die "Error on downloading entry. Response: ".$response->status_line;
		}


		my %entry = (
			'id' => $id,
			'id_link' => "$link_entry$id",
			'date_accessed' => $dt,

			'is_found' => 0,

			'topic' => "",
			'topic_link' => "",
			'number_in_topic' => 0,
			
			'date_published' => 0,
			'is_modified' => 0,
			'date_modified' => 0,
			'date_print' => 0,

			'author' => "",
			'body' => "",
			'fav_count' => 0
		);

		#is_found to be handled



		#topic & topic_link
		if($downloaded_entry_file=~/<a href="\/([^<>]*)" itemprop="url"><span itemprop="name">([^<>]*)<\/span><\/a>[^<]/){
	    	$entry{'topic_link'}=$1;
	    	$entry{'topic'}=$2;
		} 

	
	    #number_in_topic
	    if($downloaded_entry_file=~/<li id="[\d\w]*" value="(\d+)"/){
	    	$entry{'number_in_topic'}=$1;
	    }

	    #date_published, is_modified, date_modified, date_print
	    if($downloaded_entry_file=~/"commentTime">(\d\d)\.(\d{2})\.(\d\d\d\d)(\s\d\d\:\d\d)/){
	      $entry{'date_published'}=$1.".".$2.".".$3.$4;
	      $entry{'date_print'}=$entry{'date_published'};
	      if($downloaded_entry_file=~/"son g.ncelleme zaman.">([^<>]*)<\/time>/){
	      	$entry{'is_modified'}=1;
	      	$entry{'date_modified'}=$1;
	      	$entry{'date_print'}.=" ~ ".
	    }
	    
	    if($entry{'is_modified'}){
	    	$entry{'date_modified'};
	    }


	
	    #Get entries_author.
    if($downloaded_entry_file=~/data-author="(.*)" data-flags/){$entries_author[$i]=$1;}

    #Get entries_body.
    if($downloaded_entry_file=~/commentText">(.*)<\/div>/){$entries_body[$i]=$1;}

    #Get entries_favcount.
    if($downloaded_entry_file=~/data-favorite-count="(\d+)"/){$entries_favcount[$i]=$1;}
  

  #Set date to print, aka entries_datetoprint.
  $entries_datetoprint[$i]=$entries_datepublished[$i];
  if($entries_datemodified[$i]){
    $entries_datetoprint[$i].=" ~ ".$entries_datemodified[$i];
  }








		return %entry;
	}

}












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
