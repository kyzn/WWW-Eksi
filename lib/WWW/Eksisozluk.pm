package WWW::Eksisozluk;
# ABSTRACT: Perl interface for Eksisozluk.com

use strict;
use warnings;
use DateTime;
use LWP::UserAgent;
use experimental 'smartmatch';
use utf8::all;

#Exporting stuff
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	new
) ] );
our @EXPORT_OK = ( 'new' );
our @EXPORT = qw();

sub new{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}


#Global variables.
my $date_now      = DateTime->now->set_time_zone('Europe/Istanbul'); 
my $date_search   = DateTime->now->subtract(days=>1)->ymd; #2015-04-25
my %link = (
	'debe'    => "https://eksisozluk.com/istatistik/dunun-en-begenilen-entryleri",
    'author'  => "https://eksisozluk.com/biri/",
    'entry'   => "https://eksisozluk.com/entry/",
    'topic'   => "https://eksisozluk.com/",
    'search'  => "?a=search&searchform.when.from=$date_search",
    'popular' => "https://eksisozluk.com/basliklar/populer?p=",
    'today'   => "https://eksisozluk.com/basliklar/bugun/"
);
my $sleeptime     = 5; #sleep after each request. 0 would mean disabled.



sub entry{

	#Get id from arguments.
	my $class = shift;
	my $id = shift;

	#Test if satisfies id number format.
	if($id !~ /^\d{1,9}$/ || $id==0){
		die "Argument passed to the entry subroutine is not correct. Did you create an object as described in synopsis?";
	}

	my %entry = (
		'id' => $id,
		'id_link' => "$link{entry}$id",
		'id_ref' => 0,

		'is_found' => 0,

		'topic' => "",
		'topic_link' => "",
		
		'date' => 0,

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
	my $response = $ua->get("$link{entry}$id");
	sleep($sleeptime);
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
	if($downloaded_entry_file=~/<a href="([^<>]*)" itemprop="url"><span itemprop="name">([^<>]*)<\/span><\/a>[^<]/){
	   	$entry{'topic_link'}=$link{topic}.$1;
	   	$entry{'topic'}=$2;
	} 

	#date
	if($downloaded_entry_file=~/$entry{'id'}\s([\d\s\.\:~]+)/){
    	$entry{'date'}=$1;
	}
	
	#author
    if($downloaded_entry_file=~/data-author="([\w\d\s]+)" data-author-id/){
    	$entry{'author'}=$1;
    	$entry{'author_link'}=$link{author}.$1;
    }

   	#body_raw, body
    if($downloaded_entry_file=~/class=\"content\">(.*?)<\/div>/){
    	$entry{'body_raw'}=$1;
    	$entry{'body'}=$1; #handled below.
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

    #body: add img src to display images that are jpg jpeg png
    $entry{'body'}=~s/(href="([^"]*\.(jpe?g|png)(:large)?)"[^<]*<\/a>)/$1<br><br><img src="$2"><br><br>/g;
    
    #body: add a northwest arrow, and domain name in parantheses
    $entry{'body'}=~s/(https?:\/\/(?!eksisozluk.com)([^\/<]*\.[^\/<]*)[^<]*<\/a>)/$1 \($2 &#8599;\)/g;

    #favcount
    if($downloaded_entry_file=~/data-favorite-count="(\d+)"/){
    	$entry{'fav_count'}=$1;
    }

    #id_ref (first entry of the day, used for debe)
	$response = $ua->get("$entry{'topic_link'}$link{search}");
	sleep($sleeptime);
	my $downloaded_search_file;
	if($response->is_success){
		$downloaded_search_file=$response->decoded_content;
		if($downloaded_search_file=~/<li data-id="(\d+)"/){
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



sub topiclist{

	#Get type from arguments.
	my $class = shift;
	my $type = shift;

	#Test if it's valid.
	if($type ne "popular" && $type ne "today"){
		die "Argument passed to topiclist subroutine has to be either \"popular\" or \"today\".";
	}

	my $currentpage = 0;
	my $pagecount = 2;
	my %topiclist_topics;

	while($currentpage<$pagecount){

		#update pagecount
		$currentpage++;
		print "looking for page $currentpage\n";

		my $ua = LWP::UserAgent->new;
		$ua->timeout(10);
		$ua->env_proxy;
		my $response = $ua->get("$link{$type}$currentpage");
		sleep($sleeptime);
		my $downloaded_topiclist_file;

		if($response->is_success){	
			$downloaded_topiclist_file=$response->decoded_content;

			#Get the pagecount value only once.
			#First page doesn't have pagecount.. Check it at second page.
			if($currentpage == 2 && $downloaded_topiclist_file=~/data-pagecount="(\d+)"/){
				$pagecount = $1;
				print "pagecount becomes $pagecount\n";
			}

			#We might have removed left frame populars here, but it doesn't really matter.

			#Add topics to the hash, with the number of entries in it.
			while($downloaded_topiclist_file =~ />(.*)\s?<small>(\d+)</){

				#Add if not added before
				if(!($1 ~~ %topiclist_topics)){
					$topiclist_topics{"$1"}=$2;
				}
				#Cross out the processed one
				$downloaded_topiclist_file=~s/>(.*)\s<small>(\d+)</-----/;
			}

		}else{
			die "Error on downloading topic list. Response: ".$response->status_line;
		}

	}

	return %topiclist_topics;

}




sub debe_ids{

	my @debe;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	my $response = $ua->get("$link{debe}");
	sleep($sleeptime);
	my $downloaded_debe_file;
	
	if($response->is_success){
		$downloaded_debe_file=$response->decoded_content;


		while($downloaded_debe_file =~ /%23(\d+)">/){

			#If the matched entry id did not added before, then add.
			if(!($1 ~~ @debe)){
				push @debe,$1;
			}
			#Cross it to avoid duplicates.
			$downloaded_debe_file=~s/%23(\d+)">/%23XXXX">/;
		}

		if(scalar(@debe)!=50){
			my $miscount = scalar(@debe);
			warn "Debe list has $miscount entries";
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

=head1 SYNOPSIS

	use WWW::Eksisozluk;
	#You should create an object as shown below.
	my $eksi    = WWW::Eksisozluk->new();

	#IDs for today's debe list (element at index 0 is the top one)
	my @debe    = $eksi->debe_ids();

	#Details (body, author, date etc) of an entry with given id.
	my %entry   = $eksi->entry($debe[0]);

	#Popular topics with number of recent entries in it.
	my %popular = $eksi->topiclist(popular);

	#Today's topics with number of recent entries in it.
	my %today   = $eksi->topiclist(today);

=head1 DESCRIPTION

This module provides a simple perl interface for eksisozluk, which is a user-based
web dictionary written mostly in Turkish, active since 1999. You can get debe list
(top entries of yesterday) by using this module. You can also reach topic list for
today, and popular topic lists.

As a friendly note, data you reach by using this module might be subject to copyright 
terms of Eksisozluk. See eksisozluk.com for details.