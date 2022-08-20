import argparse
import tagging

parser = argparse.ArgumentParser()

parser.add_argument('-d', '--debug', action='store_true', help='Put out debugging information')

sps = parser.add_subparsers(metavar='MODE', help='Select the main mode of operation', required=True)

def readFiles(args):
    fileParser = tagging.parser.Parser()
    fileParser.readFiles(args.folder, args.recursive)

    if args.debug:
        fileParser.outputDebug()

    if args.output is None:
        fileParser.outputResult(args.sort_by_track)
    else:
        fileParser.writeFile(args.output[0], args.sort_by_track)
    
    if args.output_album is not None:
        fileParser.writeAlbumInfo(args.output_album[0])

parser_read = sps.add_parser('read-files', help='Read all files in a folder and build a table')
parser_read.add_argument('-r', '--recursive', action='store_true', help='Search recursively in the folder(s)')
parser_read.add_argument('-o', '--output', nargs=1, help='The output file to write the parsed information to', metavar='OUT')
parser_read.add_argument('-a', '--output-album', nargs=1, help='Write album information to this file', metavar='OUT')
parser_read.add_argument('-s', '--sort-by-track', action='store_true', help='Sort the output by the track number when exporting')
parser_read.add_argument('folder', nargs='+', help='The folders to look for files in')
parser_read.set_defaults(func=readFiles)

def updateId3(args):
    fileTagger = tagging.tagger.Tagger(args.dry_run)

    fileTagger.parseTrackFile(args.input[0])
    if args.album_info is not None:
        fileTagger.parseAlbumOverwriteFile(args.album_info[0])
    
    if args.debug:
        fileTagger.printDebug()
    
    if args.fixup is not None:
        fileTagger.fixupTags(args.fixup[0], args.debug)
    
    fileTagger.checkTags()
    
    if args.summary:
        fileTagger.printSummary()

    fileTagger.applyTags(args.debug)

    if args.move:
        fileTagger.moveFiles(args.debug)

parser_update_tags = sps.add_parser('update-files', help='Update the metadata tags in the files')
parser_update_tags.add_argument('-i', '--input', nargs=1, required=True, help='Read track information from this file')
parser_update_tags.add_argument('-a', '--album-info', nargs=1, help='Overwrite album info from this file')
parser_update_tags.add_argument('-f', '--fixup', nargs=1, help='Table of fixup strings replacements related to dances')
parser_update_tags.add_argument('-m', '--move', action='store_true', help='Rename the files according to the tags')
parser_update_tags.add_argument('-s', '--summary', action='store_true', help='Output a summary of the file tags before applying them')
parser_update_tags.add_argument('-n', '--dry-run', action='store_true', help='Do not perform any operation but write what would have been done')
parser_update_tags.set_defaults(func=updateId3)

args = parser.parse_args()

args.func(args)

# print(args)
