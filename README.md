# cdripper

A set of scripts to rip CDs

## Installation

There is no installation needed.
The scripts all use plain bash shell commands and some external libraries.
If these are not installed, you will have to install them using you OS/package manager.

It is advised to link the scripts in a folder that is in your PATH.
To do so, you could for example call from the folder of this repository the command

```
sudo ln -sr *.sh /usr/local/bin
```

This will install the scripts in `/usr/local/bin`.
You must not remove or move the repository though,

## Usage

The process of ripping is separated into multiple steps:

1. Ripping of the raw audio to the hard disk
1. Extract the information from the ripped raw data
1. (optionally) Do some typical search&replace on the titles identified
1. Checking and fixing the CD text entries that are used as a basis for the tags of the compressed files (like MP3)
1. Encode the tracks in compressed form as MP3 and ogg vorbis files.

The optical disks are needed in the first step only.
After that, all processing is done on the hard drive and can even be delayed (running the encoding unsupervised at night).

### Ripping the optical disk

The real ripping is done by the script `rip-cd.sh`.
It accepts some parameters like `--no-cddb` to disable the querying of the CDDB server and to specify the optical device to use.
The script will generate in the local folder a folder `tmp`.
Ideally, for each disk to rip, you create a unique, empty folder.
Run the script in this dedicated folder per disk.

After the ripping has terminated (which might take a few minuted depending on your drive), the script will eject the disk.
You can then continue to rip further disks (in separate folders) or finish the disk and encode it ultimatively.

### Extraction and collection of CD data

The next step is to extract the track information from the raw ripped data for further editing.
Just call the command `prepare-rip.sh` to carry this task out.

You can redo this step in case you messed up the files.
The raw data will not be altered, thus, you can reset to the read data anytime by restarting the script.

### Search and replace

This set of scripts was generated with a clear mission in mind.
It was built to help ripping audio CDs for dancing s a backup in case of scratches etc.
Thus there is a script called `update-table-info.sh` that should map the names of the different dances into predefined abbreviations.
If you do not want to do this, you can just skip this section.

There is a table in the repo present that allows automatic search and replace.
You can tweak it to your needs.
Just call `update-table-info.sh <path/to/table>` to do the search and replace routine.

### Review the CD texts

In the current folder there should be two files `album.info` and `titles.info`.
You should review these and update according to the correct text you want to have (like artist and track title).

First go with the `album.info`.
As the name suggests, this is the generic album information.
There are two entries in the file just separated by a literal `~`.
The first entry is the album performer and the second one is the album name.
So, one entry could be `The Beatles~Abbey Road`.

The second file is the `titles.info` that contains the information of the individual tracks of the disk.
Please do not change the ordering of the lines or so, just append/fix the corresponding lines.
Some lines are comments starting with a `#`.
You can ignore these comments (or read them and get some help).

Each line starts with the track number.
This helps with navigating.
The lines are separated by `~` as well.
There are in total 4 columns per line:
track number, track length in seconds, track artist, and track title.
Please correct the latter two in an editor of your choice.

### Encode the files to MP3/OGG

The last step is to convert the files into a compressed format.
These scripts will output three formats in total:

- `mp3 HQ` with the best possible MP3 settings
- `ogg -q 4` with ogg vorbis files of rather good quality and small size
- `mp3 --vbr-new -B 256 -q 5` with MP3 files of average quality

The encoding uses one output folder.
In this folder, for each quality a folder is generated.
In the quality folders, one folder for each album is generated.
This allows to send all albums to one and the same destination folder while keeping quality levels and albums well organized.
For example, with the output folder `/mnt/music`, the following folder structure would be generated:

```
/mnt/music
├── mp3 HQ
│   ├── Abbey Road
│   └── [...]
├── mp3 --vbr-new -B 256 -q 5
│   ├── Abbey Road
│   └── [...]
└── ogg -q 4
    ├── Abbey Road
    └── [...]
```

Inside the folders the files are placed.

To start the encoding process, the script `encode-ripped.sh` is used.
You can use the parameters `--year 1969` or `--no-year` to set the year of publishing.
If you do not, you will be asked interactively.

Apart from that you _must_ set the output path with `--out` (that would be `--out /mnt/music` in the example above).
Failing to do this will make the script reject to work.

By default the script does a normalizing of the volume levels before the encoding happens.
If you want to prevent that, just add `--no-normalize`.

After the encoding has been carried out successfully (best check for the `M3U8` file), you could remove the ripping folder as it is no longer needed.

## Further hints

You can postpone the encoding and let it run during offline times (like at night).
Best is to manually carry out the steps above except for the very last one (do not encode yet).
You should however create all ripping folders as siblings.
For example, you could have 

```
/mnt/rip
├── cd01
├── cd02
├── cd03 - Abbey Road
└── cd04 - Let it be
```

Inside the folder `cdXX` you store the ripped data.

To start the encoding session, you could run a small script in bash (adopt to your needs):
```
$ cd /mnt/rip
$ for i in cd*; do encode-ripped.sh --out /mnt/music ; done
```

Have (long) coffee ;-).

## Bugs, issues and comments

If you find any problems, feel free to open issues on github.
I will try to get the issues resolved.

Thanks for your support.
