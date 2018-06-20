__author__ = 'andrew.H'
import sys,os,os.path,json,fnmatch,glob,shutil,time,getopt,re,csv
from fnmatch import fnmatch
from subprocess import *

path = "/var/lib/docker/volumes/seq-vol/_data/myfile"
os.mkdir(path)