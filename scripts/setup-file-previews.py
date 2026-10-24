#!/usr/bin/env python3
"""Enable KDE file-dialog previews without replacing other KDE settings."""
import argparse, shutil, subprocess
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--apply',action='store_true')
args=parser.parse_args()
settings={'Show Preview':'true','Show Inline Previews':'true','View Style':'DetailTree','Preview Width':'320'}
if args.apply and not shutil.which('kwriteconfig6'):
 raise SystemExit('Install xdg-desktop-portal-kde / KDE Frameworks first.')
for key,value in settings.items():
 command=['kwriteconfig6','--file','kdeglobals','--group','KFileDialog Settings','--key',key,value]
 if args.apply:subprocess.run(command,check=True)
 else:print(' '.join(command))
