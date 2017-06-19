#!/usr/bin/python
#
# Reduce time of stored timestamps to next hour
#
import glob
import re
import os
import datetime

stamp_format='%Y%m%d%H%M%S'
keydata_match = "KEYDATA\s+(\d+)\s+(\d+)\s+(\d+)"
replace_suffix='.update'
show_diff=False
managed_keys_dir='/var/named/dynamic'

def stamp_fromstr(stamp):
    return datetime.datetime.strptime(stamp, stamp_format)

def stamp_tostr(time):
    return datetime.datetime.strftime(time, stamp_format)

class stamper:
    def __init__(self, add_seconds={0: 600, 1: 3600}):
        self.seconds = add_seconds
        now = datetime.datetime.utcnow()
        self.after_10m = now + datetime.timedelta(0, 600)
        self.after_1h = now + datetime.timedelta(0, 3600)
        self.after_2h = now + datetime.timedelta(0, 2*3600)

    def replaceone(self, m, start, index, s, replace):
        s += m.string[start:m.start(index)]
        s += replace
        return (s, m.start(index)+len(m.group(index)))

    def sub(self, m):
        refresh = stamp_fromstr(m.group(1))
        trusted = stamp_fromstr(m.group(2))
        revoked = stamp_fromstr(m.group(3))
        needReplace = False
        if refresh > self.after_10m:
            refresh = self.after_10m
            needReplace = True
        if trusted > self.after_1h:
            trusted = self.after_1h
            needReplace = True
        if needReplace:
            (s, end) = self.replaceone(m, m.start(0), 1, '', stamp_tostr(refresh))
            (s, end) = self.replaceone(m, end, 2, s, stamp_tostr(trusted))
    #        (s, end) = self.replaceone(m, end, 3, s)
            s += m.string[end:]
            return s
        else:
            return m.group(0)

def read_mkeys(fpath):
    changed = 0
    with open(fpath, "r") as mkey:
        updated_path = fpath+replace_suffix
        with open(updated_path, "w") as updatedf:
            stamp = stamper()
            pattern = re.compile("KEYDATA\s+(\d+)\s+(\d+)\s+(\d+)")
            for line in mkey.readlines():
                newline = line
                m = re.search(pattern, line)
                if m != None:
                    newline = re.sub(pattern, stamp.sub, line)
                    if newline != line:
                        ++changed
                    if show_diff:
                        print('< {0}'.format(line))
                        print('> {0}'.format(newline))
#                   print('# refresh {0} trusted {1} revoked {2}'.format(
#                       m.group(1), m.group(2), m.group(3)))
                updatedf.write(newline)

    if changed > 0:
        print('# File {0} has changed'.format(fpath))
        #os.rename(updated_path, fpath)
    else:
        print('# File {0} has NOT changed'.format(fpath))
        os.remove(updated_path)


for paths in [managed_keys_dir+"/managed-keys.bind", managed_keys_dir+"/*.mkeys"]:
    for fpath in glob.glob(paths):
        read_mkeys(fpath)
            
