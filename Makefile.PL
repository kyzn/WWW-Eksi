use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'WWW::Eksisozluk',
    VERSION_FROM      => 'lib/WWW/Eksisozluk.pm',
    PREREQ_PM         => {
    	'LWP::UserAgent' => 6.06,
    	'DateTime' => 1.10,
    	'LWP::Protocol::https' => 6.06,
        'experimental' => 0.013,
        'Mozilla::CA' => 20130114,
        'utf8::all' => 0.015,
    	},
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/WWW/Eksisozluk.pm',
       AUTHOR         => 'Kivanc Yazan <k@kyzn.org>') : ()),
);