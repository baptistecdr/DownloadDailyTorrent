# DownloadDailyTorrent

If you tired to download every day your new TVShow episode, then DownloadDailyTorrent is for you !
DownloadDailyTorrent allow you to download automatically your favorite TVShow's episode of the day.

## Prequisites

### Torrent Client
* Deluge
* Deluge Web
* AutoAdd Plugin

### Perl Module :
* Error (cpan install Error)
* Rarbg::torrentapi (cpan install Rarbg::torrentapi)
* DateTime (cpan install DateTime)
* DateTime::Format::DateParse (cpan install DateTime::Format::DateParse)

## Installation

```sh
mkdir /etc/ddt/
chmod 755 /etc/ddt/
chown root:root /etc/ddt/
mv download_daily_torrent.pl /usr/local/bin/
chown root:staff /usr/local/bin/download_daily_torrent.pl
chmod 755 /usr/local/bin/download_daily_torrent.pl
mv download_daily_torrent.ini /etc/ddt/
chown root:root /etc/ddt/download_daily_torrent.ini
chmod 644 /etc/ddt/download_daily_torrent.ini
```

## Execution

DownloadDailyTorrent can simply be run by this command:

```sh
download_daily_torrent.pl --download-path "<Deluge watch folder>"
```

By default, DownloadDailyTorrent read the configuration file in "/etc/ddt/download\_daily\_torrent.ini”. If you haven’t copy the configuration file in this directory, you can pass it with the argument "--config" :

```sh
download_daily_torrent.pl --download-path "<Deluge watch folder>" --config "<Path the configuration file>"
```

### Cron
You can also create a crontab rule to run DownloadDailyTorrent every day automatically at 16:30:

```sh
30 16 * * * /usr/local/bin/download_daily_torrent.pl --download-path "<Deluge watch folder>" >/dev/null 2>&1
```

### Available parameters
This is all the parameters avalaible in DownloadDailyTorrent.

| Parameters        | Shortcuts | Descriptions  | Mandatory |
|-------------------|-----------|---------------|-----------|
| --download-path   | -dp       | Path to the watch folder of Deluge Web  | Yes |
| --config          | -c        | Path to a configuration file | No |
| --category-id     | -ci       | The category to search the torrents  | No |
| --debug           | -d        | Active the debug mode (more log)   | No |

#### Category ID
* 18: TV Episodes
* 41: TV HD Episodes
* 49: TV UHD Episodes

## Configuration

The configuration file use the [INI format](https://en.wikipedia.org/wiki/INI_file)  ([Section], Key=Value), you can comment your configuration with the '#' character.
Here an example of a configuration file:

```ini
[Monday]
Elementary=1080p.WEB-DL,720p.HDTV

# This is a beautiful comment
[Tuesday]
Lucifer=720p.HDTV

[Wednesday]
iZombie=720p.HDTV
The.Flash=720p.HDTV

[Thursday]
Blindspot=720p.HDTV
Arrow=720p.HDTV,1080p.WEB-DL
The.100=720p.HDTV

[Friday]
The.Big.Bang.Theory=1080p.WEB-DL
The.Blacklist=720p.HDTV,1080p.WEB-DL
```
