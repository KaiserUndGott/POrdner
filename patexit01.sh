#!/bin/bash

PATDIR="/home/david/trpword/.stationen"

ICH=`whoami`
find $PATDIR/$ICH -maxdepth 1 -type l -delete

$DAV_HOME/dmpimport

exit 0

