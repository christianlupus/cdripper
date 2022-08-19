import argparse
import tagging

parser = argparse.ArgumentParser()

parser.add_argument('--debug', action='store_true', help='Put out debugging information')

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

args = parser.parse_args()

args.func(args)

# print(args)
