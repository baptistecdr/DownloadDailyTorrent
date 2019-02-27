#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Error qw(:try :warndie);
use Sys::Syslog qw(:standard :macros);
use Getopt::Long;
use Rarbg::torrentapi;
use DateTime;
use DateTime::Format::DateParse;

my $DEFAULT_CONF_PATH = "/etc/ddt/download_daily_torrent.ini";
my $DEFAULT_CATEGORY_ID = "41"; # TV HD Episodes
my $DEBUG = 0;

sub help {
    print "DownloadDailyTorrent - Download automatically your favorite TVShow's episode of the day.\n";
    print "\t-dp  --download-path   Path to the watch folder of Deluge Web\n";
    print "\t-c   --config          Path to a configuration file\n";
    print "\t-ci  --category-id     Category to search the torrents\n";
    print "\t-d   --debug           Active the debug mode (more log)\n";
    print "\t-h   --help            Show help\n";
    exit 0;
}

help() unless @ARGV;

try {
    my $download_path = undef;
    my $conf_path = $DEFAULT_CONF_PATH;
    my $category_id = $DEFAULT_CATEGORY_ID;
    my $debug = $DEBUG;

    GetOptions(
        "download-path|dp=s" => \$download_path,
        "config|c=s"         => \$conf_path,
        "category-id|ci=s"   => \$category_id,
        "debug"              => \$debug,
        "help"               => \&help
    );

    openlog("download_daily_torrent", "perror", LOG_LOCAL0);
    setlogmask(~LOG_MASK(LOG_DEBUG)) unless $debug == 1;
    syslog(LOG_INFO, "Started");

    Error::Simple->throw("Deluge's watch folder invalid.") unless (defined $download_path && -d $download_path && $download_path =~ m#^[\w\s/\\.-]+$#);

    syslog(LOG_INFO, "Reading the configuration file '$conf_path'.");
    my $conf = read_conf($conf_path);
    my $tapi = Rarbg::torrentapi->new();
    my $dt_now = DateTime->now(time_zone => "0000");

    foreach my $day (keys %$conf) {
        next unless $dt_now->day_name eq $day;

        foreach my $tvshow (keys %{$conf->{$day}}) {
            foreach my $quality (@{$conf->{$day}->{$tvshow}}) {
                my $search = search_torrent($tapi, $tvshow, $quality, $category_id);

                if (!defined($search) || ref($search) eq "Rarbg::torrentapi::Error") {
                    syslog(LOG_WARNING, "No results found for '$tvshow ($quality)'.");
                    next;
                }

                my $first_tvshow = @{$search}[0];

                if (!($first_tvshow->pubdate =~ /^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+(\+\d{4})/)) {
                    syslog(LOG_ERR, "The datetime format is invalid.");
                    next;
                }
                my $datetime = $1;
                my $time_zone = $2;
                my $dt_show = DateTime::Format::DateParse->parse_datetime($datetime, $time_zone);

                if ($dt_show->delta_days($dt_now)->delta_days > 2) {
                    syslog(LOG_WARNING, "The result found for '$tvshow ($quality)' is older than 2 days.");
                    next;
                }
                download_torrent($download_path, $first_tvshow);
            }
        }
    }
    clean_download_folder($download_path);
    syslog(LOG_INFO, "Finished");
}
catch Error with {
    my $ex = shift;
    syslog(LOG_ERR, "%s", $ex);
};


sub read_conf {
    my $conf_path = shift;
    my $config = {};
    my $current_section = "";
    Error::Simple->throw("Unable to open the file '$conf_path'.") unless open(my $conf_file, "<", $conf_path);

    while (my $line = <$conf_file>) {
        # Skip line which begin with #
        next if ($line =~ /^\s*#/);

        if ($line =~ /^\s*\[(\w+)\]\s*$/) {
            # [Section]
            $current_section = $1;
            $config->{$current_section} = {};
        }
        if ($line =~ /^\s*([\w.'-]+)\s*=\s*([\w,.-]*)\s*/) {
            # Key=Value
            @{$config->{$current_section}->{$1}} = split(/\s*,\s*/, $2);
        }
    }
    close($conf_file);
    return $config;
}

sub search_torrent {
    my $tapi = shift;
    my $tvshow = shift;
    my $quality = shift;
    my $category_id = shift;

    return $tapi->search({
        search_string => "$tvshow $quality",
        category      => $category_id,
        limit         => "1",
        sort          => "last"
    });
}


sub clean_download_folder {
    my $download_path = shift;
    syslog(LOG_DEBUG, "Cleaning up the Deluge's watch folder.");
    unlink glob "$download_path/*.invalid";
}

sub download_torrent {
    my $download_path = shift;
    my $torrent = shift;

    my $torrentname = $torrent->title;
    my $filename = "$torrentname.magnet";
    Error::Simple->throw("Unable to write the file '$filename'.") unless open(my $magnet_file, ">",
        "$download_path/$filename");
    syslog(LOG_INFO, "Extracting magnet link for '$torrentname'.");
    print($magnet_file $torrent->download);
    close($magnet_file);
}