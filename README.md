# jabackup - Joomla! automated backup & restore
A set of tools that perform simple backup/restore of Joomla! website

Do not forget to make both files executable:
`chmod +x ja*.sh`

## jabackup.sh

USAGE: `jabackup.sh [OPTIONS] PATH-TO-JOOMLA-ROOT`

PATH is a path to Joomla! root (where index.php & configuration.php are located)
```
 Options:
  -f, --filename    BASENAME for archive (may include path). Extension will be added automatically (!).
  -z, --gzip2       Compress files with gzip (default)
  -j, --bzip2       Compress files with bzip2
  -J, --xz          Compress files with xz
  -q, --quiet       Quiet (no output) [not implemented yet]
  -h, --help        Display this help and exit
      --version     Output version information and exit
```
Example: **`./jabackup.sh /var/www/joomla`**
 will create backup of Joomla! from `/var/www/joomla` as `backup.tar.gz` in current directory

**`./jabackup.sh -f /home/mysite -J /var/www/joomla`**
 will create backup of Joomla! from `/var/www/joomla` as `/home/mysite.tar.xz`

## jarestore.sh
will be added in the next release
