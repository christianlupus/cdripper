import os
import mutagen
import json
import tabulate
import sys

class Parser:

    def __init__(self):
        self.files = []
        self.metadata = {}

    def readFiles(self, nodes, recursive):
        self.files = []
        for f in nodes:
            if os.path.isdir(f):
                self.__findFilesInFolder(f, recursive)
            elif os.path.isfile(f):
                self.files.append(f)
        # print(self.files)

        self.files.sort()

        self.metadata = {}
        for fileName in self.files:
            md = self.__parseFileMetadata(fileName)
            if md is None:
                print('Skipping file {name} as no ID3 was detected'.format(name=fileName), file=sys.stderr)
            else:
                self.metadata[fileName] = md
    
    def __findFilesInFolder(self, folder, recursive):
        content = os.listdir(folder)
        for c in content:
            f = os.path.join(folder, c)

            if os.path.isdir(f):
                if recursive:
                    self.__findFilesInFolder(f, recursive)
            elif os.path.isfile(f):
                self.files.append(f)
            else:
                print("Unknown file", f)
    
    def __parseFileMetadata(self, fileName):
        return mutagen.File(fileName, easy=True)
        # return {}

    def writeFile(self, outputFileName, sortByTrack):
        data = self.__collectResult(sortByTrack)
        
        with open(outputFileName, 'w') as fp:
            json.dump(data, fp, indent=3)

    def outputResult(self, sortByTrack):
        data = self.__collectResult(sortByTrack)
        table = {
            'file': [x['fileName'] for x in data],
            'track': [x['track'] for x in data],
            'artist': [x['artist'] for x in data],
            'title': [x['title'] for x in data],
            'album': [x['album'] for x in data]
        }
        print(tabulate.tabulate(table, headers='keys'))
        # for row in data:
        #     print('{file}: {track} - {artist} - {title} ({album})'.format(
        #         file=row['fileName'], track=row['track'], artist=row['artist'],
        #         title=row['title'], album=row['album']
        #     ))
    
    def outputRaw(self):
        first = True
        for fileName in self.metadata.keys():
            if not first:
                print()
            print("File: %s" % fileName)
            print(self.metadata[fileName])
            first = False

    def __collectResult(self, sortByTrack):
        data = []
        for fileName in self.metadata.keys():
            data.append({
                'album': self.metadata[fileName]['album'][0],
                'track': int(self.metadata[fileName]['tracknumber'][0]),
                'artist': self.metadata[fileName]['artist'][0],
                'title': self.metadata[fileName]['title'][0],
                'fileName': fileName
            })
        
        if sortByTrack:
            def sortFun(x):
                return x['track']
            data.sort(key=sortFun)
        
        return data

    def writeAlbumInfo(self, outputFileName):
        albums = [self.metadata[k]['album'][0] for k in self.metadata.keys()]
        albums = set(albums)
        if len(albums) > 1:
            print('Found albums:', albums)
            raise Exception('Cannot output information of multiple albums')
        
        artists = [self.metadata[k]['artist'][0] for k in self.metadata.keys()]
        artists = set(artists)
        if len(artists) > 1:
            artist = 'Various Artists'
        else:
            artist = list(artists)[0]
        
        data = {
            'artist': artist,
            'album': list(albums)[0]
        }
        # print(data)

        with open(outputFileName, 'w') as fp:
            json.dump(data, fp, indent=3)

    def outputDebug(self):
        print('Found files', self.files)
        print('Meta data', self.metadata)

