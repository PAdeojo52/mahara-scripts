#!/usr/bin/perl -w

# Takes a Mahara .po file generated by php-po.php, and converts it
# into a Mahara language pack containing help files (html) and string
# files (php).

# Assumes the .po reference comments contain either an html filename
# or a php filename followed by a space and a mahara language string
# key.

# po-php.pl /path/to/po/files/fr-1.3_STABLE.po /path/to/langpacks/fr.utf8 fr.utf8

use File::Path qw(mkpath);
use File::Basename qw(fileparse);
use Locale::PO;

my ($inputfile, $outputdir, $lang) = @ARGV;

# The version of Locale::PO on chatter (0.17) spews warnings for all
# the msgctxt lines in the file.  Should remove this later.
BEGIN { $SIG{'__WARN__'} = sub { warn $_[0] if substr($_[0], 0, 15) ne "Strange line in" } }

my $strings = Locale::PO->load_file_asarray($inputfile);

my %htmlfiles = ();
my %phpfiles = ();

foreach my $po (@$strings) {
    my $content = $po->msgstr();
    next if ( ! defined $content );
    $content =~ s{\\n}{\n}g;
    next if ( $content eq '' || $content eq '""' );
    my $reference = $po->reference();
    next if ( ! defined $reference );
    if ($reference =~ m{^(\S*lang/)\S+\.utf8(/\S+)\.html$}) {
        my $filename = $1 . $lang . $2 . '.html';
        $htmlfiles{$filename} = $po->dequote($content);
    }
    elsif ($reference =~ m{^(\S*lang/)\S+\.utf8(/\S+)\.php\s+(\S+)$}) {
        my $key = $3;
        my $filename = $1 . $lang . $2 . '.php';
        $phpfiles{$filename}->{$key} = $content;
    }
}

foreach my $htmlfile (keys %htmlfiles) {
    my ($filename, $subdir, $suffix) = fileparse($htmlfile);
    my $dir = $outputdir . '/' . $subdir;
    mkpath($dir);
    open(my $fh, '>', "$dir/$filename");
    print $fh $htmlfiles{$htmlfile};
    close $fh;
}

foreach my $phpfile (keys %phpfiles) {
    my ($filename, $subdir, $suffix) = fileparse($phpfile);
    my $dir = $outputdir . '/' . $subdir;
    mkpath($dir);
    open(my $fh, '>', "$dir/$filename");
    print $fh "<?php\n\ndefined('INTERNAL') || die();\n\n";
    foreach my $key (sort keys %{$phpfiles{$phpfile}}) {
        print $fh "\$string['$key'] = " . $phpfiles{$phpfile}->{$key} . ";\n";
    }
    close $fh;
}


