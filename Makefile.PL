use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Net::Eksisozluk',
    VERSION_FROM      => 'lib/Net/Eksisozluk.pm',
    PREREQ_PM         => {
    	'LWP::UserAgent' => 3.10,
    	'DateTime' => 1.10,
    	},
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Net/Eksisozluk.pm',
       AUTHOR         => 'Kivanc Yazan <k@kyzn.org>') : ()),
);