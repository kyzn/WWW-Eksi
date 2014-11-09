package WWW::Eksisozluk;

use strict;
use warnings;
use DateTime;
use LWP::UserAgent;
use experimental 'smartmatch';
use utf8::all;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	new
) ] );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT_OK = ( 'new' );
our @EXPORT = qw();
our $VERSION = '0.09';

#Variables to be used throughout the program.
my $date_now   = DateTime->now->set_time_zone('Europe/Istanbul'); 
my $date_search = DateTime->now->subtract(days=>1)->ymd;
#my $date_file   = DateTime->now->subtract(days=>1)->dmy;
#my $date_today  = DateTime->now->dmy;
my $link_debe="https://eksisozluk.com/istatistik/dunun-en-begenilen-entryleri";
my $link_author="https://eksisozluk.com/biri/";
my $link_entry="https://eksisozluk.com/entry/";
my $link_topic="https://eksisozluk.com/";
my $link_search = "?a=search&searchform.when.from=$date_search";
my $link_popular="https://eksisozluk.com/basliklar/populer?p=";

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub entry{

	#Get id from arguments.
	my $class = shift;
	my $id = shift;

	#Test if satisfies id number format.
	if($id !~ /^\d{1,9}$/ || $id==0){
		die "Argument passed to the get_entry_by_id is of wrong format. It might be possible that you didn't call this method from an object. See readme file.";
	}

	my %entry = (
		'id' => $id,
		'id_link' => "$link_entry$id",
		'id_ref' => 0,
		'date_accessed' => $date_now,

		'is_found' => 0,

		'topic' => "",
		'topic_link' => "",
		'number_in_topic' => 0,
			
		'date_published' => 0,
		'is_modified' => 0,
		'date_modified' => 0,
		'date_print' => 0,

		'author' => "",
		'author_link' => "",
		'body_raw' => "",
		'body' => "",
		'fav_count' => 0
	);
		
	#Get the entry file.
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	my $response = $ua->get("$link_entry$id");
	my $downloaded_entry_file;
		
	if($response->is_success){
		$entry{'is_found'}=1;
		$downloaded_entry_file = $response->decoded_content;
	}else{
		#return with is_found=0
		return %entry;
		#Another possible way of handling could have been:
		#die "Error on downloading entry. Response: ".$response->status_line;
		#TODO ask user which way he/she wishes, ie. take parameters to handle this issue.
	}

	#topic & topic_link
	if($downloaded_entry_file=~/<a href="\/([^<>]*)" itemprop="url"><span itemprop="name">([^<>]*)<\/span><\/a>[^<]/){
	   	$entry{'topic_link'}=$link_topic.$1;
	   	$entry{'topic'}=$2;
	} 

	
	#number_in_topic
	if($downloaded_entry_file=~/<li id="[\d\w]*" value="(\d+)"/){
		$entry{'number_in_topic'}=$1;
	}

	#date_published, is_modified, date_modified, date_print
	if($downloaded_entry_file=~/"commentTime">(\d\d)\.(\d\d)\.(\d\d\d\d)(\s\d\d\:\d\d)?/){
    $entry{'date_published'}=$1.".".$2.".".$3.((defined $4) ? $4 : "");
		$entry{'date_print'}=$entry{'date_published'};
	    if($downloaded_entry_file=~/"son g.ncelleme zaman.">([^<>]*)<\/time>/){
	    	$entry{'is_modified'}=1;
	      	$entry{'date_modified'}=$1;
	      	$entry{'date_print'}.=" ~ ".$entry{'date_modified'};
	    }
	}
	
	#author
    if($downloaded_entry_file=~/data-author="(.*)" data-flags/){
    	$entry{'author'}=$1;
    	$entry{'author_link'}=$link_author.$1;
    }

   	#body_raw, body
    if($downloaded_entry_file=~/commentText">(.*)<\/div>/){
    	$entry{'body_raw'}=$1;
    	$entry{'body'}=$1;
    }

	#body: open goo.gl
    while($entry{'body'}=~/href="(http:\/\/goo.gl[^"]*)"/){
      my $temp=&longgoogl($1);
      $entry{'body'}=~s/href="(http:\/\/goo.gl[^"]*)"/href="$temp"/;
    }
    
    #body: open hidden references (akıllı bkz)
    $entry{'body'}=~s/<sup class=\"ab\"><([^<]*)(data-query=\")([^>]*)\">\*<\/a><\/sup>/<$1$2$3\">\(* $3\)<\/a>/g;
    
    #body: fix links so that they work outside eksisozluk.com + _blank
    $entry{'body'}=~s/href="\//target="_blank" href="https:\/\/eksisozluk.com\//g;
    
    #body: gmail underline fix
    $entry{'body'}=~s/href="/style="text-decoration:none;" href="/g;
    
    #body: fix imgur links ending without jpg
    $entry{'body'}=~s/(href="https?:\/\/[^.]*\.?imgur.com\/\w{7})"/$1\.jpg"/g;

    #body: add img src to display images that are jpg jpeg png gif
    $entry{'body'}=~s/(href="([^"]*\.(jpe?g|png|gif)(:large)?)"[^<]*<\/a>)/$1<br><br><img src="$2"><br><br>/g;
    
    #body: add a northwest arrow, and domain name in parantheses
    $entry{'body'}=~s/(https?:\/\/(?!eksisozluk.com)([^\/<]*\.[^\/<]*)[^<]*<\/a>)/$1 \($2 &#8599;\)/g;

    #favcount
    if($downloaded_entry_file=~/data-favorite-count="(\d+)"/){
    	$entry{'fav_count'}=$1;
    }

    #id_ref (first entry of the day, used for debe)
	$response = $ua->get("$entry{'topic_link'}$link_search");
	my $downloaded_search_file;
	if($response->is_success){
		$downloaded_search_file=$response->decoded_content;
		if($downloaded_search_file=~/<li id="li(.*)" value="\d+"/){
   			$entry{'id_ref'}=$1;
   		}
	}else{
		#Return with minus 1.
		$entry{'id_ref'}=-1;
		#Another possible way of handling.
		#die "Error on searching reference entry. Response: ".$response->status_line;
	}


	return %entry;

}


sub popular{

	my $currentpage = 0;
	my $pagecount = 1;
	my %popular_topics;

	while($currentpage<$pagecount){

		#update pagecount
		$currentpage++;

		my $ua = LWP::UserAgent->new;
		$ua->timeout(10);
		$ua->env_proxy;
		my $response = $ua->get("$link_popular$currentpage");
		my $downloaded_popular_file;

		if($response->is_success){	
			$downloaded_popular_file=$response->decoded_content;

			#Die if downloaded page's number does not match what was expected.
			if($downloaded_popular_file=~/data-currentpage="(\d+)"/ && $currentpage != $1){
				die("Asked for page \#$currentpage, got page \#$1.");
			}
		
			#Get the pagecount value only once.
			if($pagecount == 1 && $downloaded_popular_file=~/data-pagecount="(\d+)"/){
				$pagecount = $1;
			}

			#We might have removed left frame populars here, but it doesn't really matter.

			#Add topics to the hash, with the number of entries in it.
			while($downloaded_popular_file =~ />(.*)\s?<small>(\d+)</){

				#Add if not added before
				if(!($1 ~~ %popular_topics)){
					$popular_topics{"$1"}=$2;
				}
				#Cross out the processed one
				$downloaded_popular_file=~s/>(.*)\s<small>(\d+)</-----/;
			}

		}else{
			die "Error on downloading popular page. Response: ".$response->status_line;
		}

	}

	return %popular_topics;

}




sub debe_ids{

	my @debe;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	my $response = $ua->get("$link_debe");
	my $downloaded_debe_file;
	
	if($response->is_success){
		$downloaded_debe_file=$response->decoded_content;


		while($downloaded_debe_file =~ /%23(\d+)">/){

			#If the matched entry id did not added before, then add.
			if(!($1 ~~ @debe)){
				push @debe,$1;
			}
			#Otherwise just cross it, don't add something twice.
			$downloaded_debe_file=~s/%23(\d+)">/%23XXXX">/;
		}

		if(scalar(@debe)!=50){
			my $miscount = scalar(@debe);
			die "Debe list has $miscount entries";
		}
	
	}else{
		die "Error on downloading data. Response: ".$response->status_line;
	}

	return @debe;
}


sub longgoogl{
  my $googl = $_[0];
  my $long = `curl -s $1 |grep HREF`;
  if($long =~/"(http[^"]*)"/){
    $long = $1;
  }
  return $long;
}


1;
__END__

===========================

=head1 NAME

WWW::Eksisozluk - Perl extension to grab entries and lists of entries from eksisozluk (eksisozluk.com).

=head1 SYNOPSIS

	use WWW::Eksisozluk;
	my $eksi  = WWW::Eksisozluk->new();
	my @debe  = $eksi->debe_ids();
	my %entry = $eksi->entry($debe[0]);
	my %popular = $eksi->popular();

=head1 DESCRIPTION

This module provides a simple command line interface for eksisozluk,
which is a user-based web dictionary, a famous web site in Turkey since 1999.
You can get "debe" list (list of most voted entries from yesterday) by using
this module.

debe_ids() will return the entry id's of the online debe list. Element at index
0 will be the first entry, 1 is second and so on. You can also get details of an
entry by only giving the entry id to entry(). Ideally, you should call these methods
from an object. This will return a hash with the values below.

	'id' # is the id of the entry. it was already given by the user.
	'id_link' # is the direct link to the entry.
	'id_ref' # is the id of the reference entry. reference entry is the first entry of the day in the same topic. it might be equal to id.
	'date_accessed' # will show the date-time of the script running.

	'is_found' # will show whether entry is found or not. will return 0 if entry is deleted, or not written yet.

	'topic' # is the topic of the entry.
	'topic_link' # is the link of the topic. can be used for search.
	'number_in_topic' # is the order of the entry in the topic.
			
	'date_published' # is the date-time entry is first published.
	'is_modified' # will show if the entry is modified or not.
	'date_modified' # is the date entry is modified. if it is not modified, will return 0.
	'date_print' # is the human readable date that can be used to print.

	'author' # is the username who wrote the entry.
	'author_link' # is the link of the author.
	'body_raw' # is the raw entry, as downloaded from eksisozluk directly.
	'body' # is the edited entry, several fixes is applied to the raw.
	'fav_count' # is the number that shows the time that entry is marked as favourite.

popular() will return currently popular topics, with the number of popular entries they contain.

=head2 EXPORT

  new()

You should create a new Eksisozluk object and call "debe_ids" and "entry" methods from there as shown in synopsis.

=head1 SEE ALSO

Follow and/or contribute to the development of this package at L<http://www.github.com/kyzn/net-eksisozluk>

=head1 AUTHOR

Kivanc Yazan

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kivanc Yazan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

The data you reach by using this module might be subject to the
copyright terms of Eksisozluk. See eksisozluk.com for details.


=cut
