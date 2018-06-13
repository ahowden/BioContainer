__author__ = 'ben'
import json
from subprocess import call
import os


json_data = open("input.json")
data = json.load(json_data)
my_input = data['input']
path = os.path.dirname(os.path.realpath(__file__))
search = my_input+"*.xml"
os.chdir(path)
file_name = ([name for name in os.listdir(path) if (os.path.isfile(name) and (".xml" in name))])
print len(file_name)
for file in file_name:
    filename = file[:-4] +'_pars.sh'
    f = open(filename, 'w')
    f.write('#!/bin/sh\n')
    f.write('#Run blast USC by Norman\n')
    f.write('echo "load Perl"\n')
    f.write('#module load perl\n')
    f.write('echo "load BioPerl"\n')
    f.write('#module load bioperl/1.6.901\n')
    f.write('echo "start '+file+'"\n')
    f.write('perl xmlparse.pl -i '+file+' -o '+file[:-4]+'.pars '+' -n '+data['n']+' -b '+data['b']+' -f '+data['DB_type'])
    f.close()
    os.chmod(filename,0777)
    print filename
    call(['./'+filename])


path = os.path.dirname(os.path.realpath(__file__))
file_name = ([name for name in os.listdir(path) if (os.path.isfile(name) and (".hits.txt" in name))])
flag =True
with open(data['input']+"result.hit.txt", "wb") as outfile:
    for f in file_name:
        with open(f, "rb") as infile:
            if flag == False:
                flag=True
                next(infile)
            for line in infile:
                outfile.write(line)
        flag=False
path = os.path.dirname(os.path.realpath(__file__))
file_name = ([name for name in os.listdir(path) if (os.path.isfile(name) and (".nohits.txt" in name))])
flag =True
with open(data['input']+"result.nohit.txt", "wb") as outfile:
    for f in file_name:
        with open(f, "rb") as infile:
            if flag == False:
                flag=True
                next(infile)
            for line in infile:
                outfile.write(line)
        flag=False
path = os.path.dirname(os.path.realpath(__file__))
file_name = ([name for name in os.listdir(path) if (os.path.isfile(name) and (".hits.header" in name))])
flag =True
with open(data['input']+"result.hit.header", "wb") as outfile:
    for f in file_name:
        with open(f, "rb") as infile:
            if flag == False:
                flag=True
                next(infile)
            for line in infile:
                outfile.write(line)
        flag=False
