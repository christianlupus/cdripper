import mutagen
import os
import json
import tabulate
import re
import sys

class Tagger:
    def __init__(self, dry):
        self.data = []
        self.dry = dry

        pattern = '(.*?) *\(([A-Za-z ]+ *[0-9]+)\)'
        self.reFixup = re.compile(pattern)

    def parseTrackFile(self, trackFile):
        with open(trackFile) as fp:
            self.data = json.load(fp)
    
    def parseAlbumOverwriteFile(self, albumFile):
        with open(albumFile) as fp:
            aData = json.load(fp)
        
        def cb(x):
            x['album'] = aData['album']
            return x
        
        self.data = list(map(cb, self.data))

    def printDebug(self):
        print('Parsed data from json files:')
        print(self.data)
    
    def checkTags(self):
        for row in self.data:
            self.__checkStringForUnicode(row, 'artist')
            self.__checkStringForUnicode(row, 'title')
            self.__checkStringForUnicode(row, 'album')
    
    def __checkStringForUnicode(self, row, field):
        string = row[field]
        for c in string:
            if ord(c) > 127:
                print(f"Warning: Found Unicode char in track {row['track']} in field {field}", file=sys.stderr)
                return

    def applyTags(self, debug):
        for row in self.data:
            self.__applyTagToFile(row, debug)
    
    def __applyTagToFile(self, data, debug):
        if debug:
            print('Tagging file %s' % data['fileName'])
        
        tags = mutagen.File(data['fileName'], easy=True)
        changed = self.__applySingleTag(tags, data['artist'], 'artist', debug)
        changed = changed or self.__applySingleTag(tags, data['title'], 'title', debug)
        changed = changed or self.__applySingleTag(tags, str(data['track']), 'tracknumber', debug)
        changed = changed or self.__applySingleTag(tags, data['album'], 'album', debug)

        if debug:
            print(tags.pprint())
            # print(type(tags.tags))
        
        if changed:
            if self.dry:
                print('Skipping writing to file as we are in dry-run mode.')
            else:
                tags.tags.save(data['fileName'])
    
    def __applySingleTag(self, tags, value, name, debug):
        if tags[name][0] != value:
            if self.dry or debug:
                print('Setting the field {field} value to "{val}" (was "{old}")'.format(field=name, val=value, old=tags[name][0]))
            
            tags[name] = value
            return True
        return False
    
    def fixupTags(self, fixupFileName, debug):
        maps = self.__readFixupTable(fixupFileName)
        # print(maps)
        self.__fixupData(maps, debug)

    def __readFixupTable(self, fileName):
        with open(fileName) as fp:
            content = fp.read()
        
        lines = content.split('\n')
        maps = []
        for line in lines:
            if line.startswith('#') or line == '':
                continue
            
            pts = line.split(':')
            maps.append(pts)
        
        return maps

    def __fixupData(self, maps, debug):
        def cb(x):
            return self.__fixupSingleRow(x, maps, debug)
        
        self.data = list(map(cb, self.data))
    
    def __fixupSingleRow(self, row, maps, debug):
        title = row['title']
        
        if debug:
            print('Checking title "%s"' % title)
        
        match = self.reFixup.match(title)
        
        if match:
            # print(match.groups())
            base = match.group(1)
            dance = match.group(2)

            for m in maps:
                # print('Old dance value', dance, 'lookking for', m[0])
                dance = dance.replace(m[0], m[1])

            pattern = '([a-zA-Z]+) *([0-9]+)'
            subre = re.compile(pattern)
            submatch = subre.match(dance)
            if submatch:
                dance = '{dance} {speed}'.format(dance=submatch.group(1), speed=submatch.group(2))

            title = '{title} ({info})'.format(title=base, info=dance)
            
            if debug:
                print('new title', title)
            
            row['title'] = title

        return row

    def printSummary(self):
        table = {
            'filename': [x['fileName'] for x in self.data],
            'track': [x['track'] for x in self.data],
            'artist': [x['artist'] for x in self.data],
            'title': [x['title'] for x in self.data],
            'album': [x['album'] for x in self.data]
        }
        print("Summary of the file data collected:")
        print(tabulate.tabulate(table, headers='keys'))
        print()
    
    def moveFiles(self, debug):
        trackLen = self.__getTrackFieldWidth()
        for row in self.data:
            fileName = self.__getNewFileName(row, trackLen)
            if fileName != row['fileName']:
                self.__renameFile(row['fileName'], fileName)
            elif debug:
                print('Moving of file {name} is not required'.format(name=fileName))

    def __getTrackFieldWidth(self):
        tracks = [row['track'] for row in self.data]
        tracks.sort()
        maximum = tracks[-1]
        return len(str(maximum))
    
    def __getNewFileName(self, row, trackLen):
        name = f"{row['track']:>0{trackLen}} - {row['artist']} - {row['title']}.mp3"
        name = name.replace('/', '_')
        return name
        
    def __renameFile(self, src, dst):
        dirname = os.path.dirname(dst)
        if dirname != '':
            if self.dry:
                print('Ensuring that the folder %s exists. Skipping due to dry mode' % dirname)
            else:
                os.makedirs(dirname, exist_ok=True)

        if self.dry:
            print('Skipping moving file from "{src}" to "{dst}" due to dry mode'.format(src=src, dst=dst))
        else:
            os.rename(src, dst)
