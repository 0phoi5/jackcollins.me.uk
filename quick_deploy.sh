#!/usr/bin/bash

cd /home/ophois/jackcollins.me.uk

rm -rf /home/ophois/jackcollins.me.uk/public/* && hugo

git add *
git commit -m "Automated push from CLI"
git push -f origin master
