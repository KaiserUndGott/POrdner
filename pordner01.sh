#!/bin/bash
#
#
#
# Erstellt beim Aufrufen eines Patienten einen Link zu dessen Dokumentenab-
# lage in trpword (zur Nutzung in Samba).
#
# Am Windows PC wird ggf. der Rexserver benoetigt.
#
# In den OO-Exporteinstellungen DAV_LID aktivieren sowie dieses Script bei
# "Patient aufgerufen" eintragen (Key erforderlich!).
#
# Empfohlen wird die Installation von detox, Download ggf. unter:
# http://sourceforge.net/projects/detox/files/detox/1.2.0/
#
# SPnG (FW), Stand: August 2015
#
#
#
# Bitte anpassen: ############################################################
#
SMBPFAD="/home/david/trpword/.stationen"  # Diesen Pfad + Login Name des Linux 
#                                         # Users mit der smb.conf abgleichen!
#
# Bitte anpassen, falls Batch Aufruf gewuenscht: #############################
#
IP="192.168.0.1"                          # IP des WinPC (Rexserver!)
PORT="6666"                               # Port fuer Rexserver
BATCH="c:\\david\startmich.bat"           # Batchdatei am WinPC
STARTWIN=0                                # "1" zum Aktivieren d. Batchaufrufs
#
PATINF=0                                  # "1" zum Ausgeben einer Infodatei
TAG="$SMBPFAD/patinf.txt"                 # Name und Pfad der Infodatei
#   
DEBUG=0                                   # "1" aktiviert das Logging
DEBUGFILE="$DAV_HOME/Desktop/debug.txt"   # Name und Pfad der Logdatei
#
##############################################################################





# Ab hier bitte Finger weg!




ICHBINS=`whoami`
APUSER="$SMBPFAD/$ICHBINS"
[ -d $APUSER ] || mkdir -p -m 666 $APUSER

######################################################
if [ ${PATINF} = "1" ]; then
   # Ggf. aktuelle Daten in einem File bereit stellen:
   echo "DAV_ID: $DAV_ID" >$TAG
   echo "Pat.nr: $1"     >>$TAG
   echo "Praxis: $2"     >>$TAG
   echo "LockID: $3"     >>$TAG
   chmod 666 $TAG
fi
######################################################

# ggf. alten Link beseitigen:
find $SMBPFAD/$ICHBINS -maxdepth 1 -type l -delete

# Namen des Patienten bestimmen:
PFILE="/home/david/trpword/$3/patienten$3.txt"
if [ -e $PFILE ]; then
    P1=`sed -n '2 p' $PFILE | awk -F";" '{print $1}' | sed 's/"//g'`
    P2=`sed -n '2 p' $PFILE | awk -F";" '{print $2}' | sed 's/"//g' | tr [:blank:] '-' | tr [:lower:] [:upper:]`
    P3=`sed -n '2 p' $PFILE | awk -F";" '{print $3}' | sed 's/"//g' | tr [:blank:] '-'`
    #
    # Falls der Name Sonderzeichen enthaelt, sollte mit detox konvertiert werden, damit aus 
    # Windows Sicht (UTF-8!) die Darstellung korrket ist:
    if [ -x /usr/local/bin/detox ]; then
       DETX="Ja"
       PATIENT="$P2"_"$P3"_"$P1"
    else
       DETX="Nein"
       PATIENT="$P1"
    fi
else
    #kdialog --error "Menno! Bitte in DV den OOo Datenexport aktivieren."
    PATIENT="Patient"
fi

# Aktuelles Patientenverzeichnis bestimmen:
SERVERPFAD=$DAV_HOME/trpword/pat_nr
PFAD=`echo $1 | awk '{printf("%08.f\n",$1)}' | awk -F '' '{printf("%d/%d/%d/%d/%d/%d/%d/%d",$1,$2,$3,$4,$5,$6,$7,$8)}'`
FULLPFAD="$SERVERPFAD/$2/$PFAD"
mkdir -p -m 777 "$FULLPFAD" > "/dev/null" 2>&1 

# Link im Stationsordner zum akt. Patienten anlegen:
ln -s $FULLPFAD $APUSER/$PATIENT
[ ${DETX} = "Ja" ] && detox --special $APUSER/$PATIENT

# Ggf. Batchdatei am Windowsrechner starten:
[ ${STARTWIN} = "1" ] && echo "DAVCMD start /min $BATCH" | netcat $IP $PORT >/dev/null

#################################################
if [ ${DEBUG} = "1" ]; then
   echo "PatNr.      :" $P1        >$DEBUGFILE
   echo "Nachname    :" $P2       >>$DEBUGFILE
   echo "Vorname     :" $P3       >>$DEBUGFILE
   echo "Detox vorh. :" $DETX     >>$DEBUGFILE
   echo -n "Linkname    : "       >>$DEBUGFILE
   ls /$APUSER                    >>$DEBUGFILE
   echo "Dok.ablage  :" $FULLPFAD >>$DEBUGFILE
   echo "Pordner     :" $APUSER   >>$DEBUGFILE
fi
#################################################

#rm -f $TAG
exit 0
