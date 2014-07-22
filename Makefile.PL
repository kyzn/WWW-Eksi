use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'WWW::Eksisozluk',
    VERSION_FROM      => 'lib/WWW/Eksisozluk.pm',
    PREREQ_PM         => {
    	'LWP::UserAgent' => 3.10,
    	'DateTime' => 1.10,
    	},
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/WWW/Eksisozluk.pm',
       AUTHOR         => 'Kivanc Yazan <k@kyzn.org>') : ()),
);