import os
import os.path
import sys
import shutil
import subprocess
from SCons.Builder import Builder


def mkdir(path):
    """ An error-free mkdir """
    print "mkdir -p %s" % path
    os.makedirs(path)

def rmtree(path):
    print "rm -r %s" % path
    shutil.rmtree(path)
    
def link(src, dst):
    print "ln %s %s" % (src, dst)
    os.link(src, dst)

def call(*args):
    print " ".join(args[0])
    subprocess.call(*args)

def createCD(target, source, env):
    """ Creates a verto CD with a base system"""
    
    iso_path    = '/tmp/iso'
    boot_path   = os.path.join(iso_path, 'boot')
    grub_path   = os.path.join(boot_path, 'grub')
    stage2_path = os.path.join(grub_path, 'stage2_eltorito')

    # Give us a clean place to put the iso files
    if os.path.isdir(iso_path):
        rmtree(iso_path)
    mkdir(grub_path)

    for source_file in source:
        basename = os.path.basename(source_file.path)
        
        if basename == 'loader' or basename == 'kernel':
            link(source_file.path, os.path.join(boot_path, basename))
        elif basename == 'stage2_eltorito':
            link(source_file.path, stage2_path)
        elif basename == 'iso-menu.lst':
            link(source_file.path, os.path.join(grub_path, 'menu.lst'))
        
    call(['mkisofs', '-R', '-no-emul-boot', '-boot-info-table',
          '-boot-load-size', '4',
          '-b', 'boot/grub/stage2_eltorito',
          '-o', target[0].path,
          iso_path])

    rmtree(iso_path)
        
    return None

CDBuilder = Builder(action = createCD)
