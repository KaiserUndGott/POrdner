#!/bin/bash



# Erstellt beim Aufrufen eines Patienten einen Link zu dessen Dokumentenab-
# lage in trpword (zur Nutzung mit Samba).
#
# Das Skript verwendet die aktuelle Patientennummer als Linkname. Wurde der
# Schalter "FIXNAME" aktiviert, wird lautet der Linkname konstant "Patient".
# Ansonsten wird der volle Pat.name inkl. Fallnummer als Linkname verwendet.
#
# Am Windows PC wird ggf. der Rexserver benoetigt.
#
# In den OO-Exporteinstellungen DAV_LID aktivieren sowie dieses Script bei
# "Patient aufgerufen" eintragen.
#
# Empfohlen wird die Verwendung von detox, welches auf dem Speedpoint
# Clonemasterist bereits installiert ist.
# Download ggf. unter http://sourceforge.net/projects/detox/files/detox
# 
# Bitte nur zusammen mit patexitXY.sh verwenden!
#
# SPnG (FW), Stand: Dezember 2015




##############################################################################
# Bitte anpassen: ############################################################
#
# Pfad fuer die Samba Shares der User, bitte mit der smb.conf abgleichen:
#
SMBPFAD="/home/david/trpword/.stationen" 
#
##############################################################################
#
# Schalter legt fest, ob der Linkname auf "Patient" fixiert wird.
#   "1": Linkname ist fixiert "Patient" 
#   "0": Voller Patientenname inkl. DV Fallnummer wird verwendet (default)
#
FIXNAME=0
#
##############################################################################
#
# Logging ggf. aktivieren (0/1):
#
DEBUG=0
DEBUGFILE="/home/david/trpword/pordner-$3-debug.txt"
#
##############################################################################
#
# Batch Aufruf am Windows PC, falls gewuenscht:
#
GOBAT=0					  # Batch starten (0/1)?
#
IP="192.168.1.121"                        # IP des WinPC (Rexserver!)
PORT="6666"                               # Port des Rexservers
BATCH="c:\\david\startmich.bat"           # Name der Batchdatei am WinPC
#
# Ende der Anpassungen #######################################################
##############################################################################
#
#
#
#
#
# Ab hier bitte Finger weg!
#
#
#
#
#
# User und Samba Pfad bestimmen:
ICHBINS=`whoami`
APUSER="$SMBPFAD/$ICHBINS"
[ -d $APUSER ] || mkdir -p -m 666 $APUSER
#
#
# ggf. Datenreste beseitigen:
find $SMBPFAD/$ICHBINS -maxdepth 1 -type l -delete
[ -f $DEBUGFILE ] && rm -f $DEBUGFILE
#
#
# detox Tool suchen:
DETX="Nein"
[ -x /usr/bin/detox -o -x /usr/local/bin/detox ] && DETX="Ja"
#
#
# Namen des Patienten definieren:
PATIENT="$1"
[ -z $PATIENT ] && PATIENT="Patient"
#
#
# Vollen Pat.namen bestimmen, sofern Exportdatei vorliegt UND $FIXNAME inaktiv:
if [ ${FIXNAME} = "0" ]; then
   PFILE="/home/david/trpword/$3/patienten$3.txt"
   #
   if [ -e $PFILE ]; then
      P1=`sed -n '2 p' $PFILE | awk -F";" '{print $1}' | sed 's/"//g'`
      P2=`sed -n '2 p' $PFILE | awk -F";" '{print $2}' | sed 's/"//g' | tr [:blank:] '-' | tr [:lower:] [:upper:]`
      P3=`sed -n '2 p' $PFILE | awk -F";" '{print $3}' | sed 's/"//g' | tr [:blank:] '-'`
      #
      PATIENT="$P2"_"$P3"_"$P1"
   fi
else
   kdialog --sorry "Exportdatei nicht gefunden. Bitte DATA VITAL Datenexport pruefen."
fi
#
#
# Aktuelles Patientenverzeichnis bestimmen:
serverpfad=$DAV_HOME/trpword/pat_nr
pfad=`echo $1 | awk '{printf("%08.f\n",$1)}' | awk -F '' '{printf("%d/%d/%d/%d/%d/%d/%d/%d",$1,$2,$3,$4,$5,$6,$7,$8)}'`
fullpfad="$serverpfad/$2/$pfad"
mkdir -p -m 777 "$fullpfad" > "/dev/null" 2>&1 
#
#
# Link im Stationsordner zum akt. Patienten anlegen:
ln -s $fullpfad $APUSER/$PATIENT
#
#
# Falls der Name Sonderzeichen enthaelt, sollte mit detox konvertiert werden, damit aus 
# Windows Sicht (UTF-8) die Darstellung korrket ist:
[ ${DETX} = "Ja" ] && detox --special $APUSER/$PATIENT
#
#
# Ggf. Batchdatei am Windowsrechner starten:
[ ${GOBAT} = "1" ] && echo "DAVCMD start /min $BATCH" | netcat $IP $PORT >/dev/null
#
#
####################################################
if [ ${DEBUG} = "1" ]; then
   echo ""                               >$DEBUGFILE
   echo "Aktueller DV Patientenaufruf:" >>$DEBUGFILE
   echo "-----------------------------" >>$DEBUGFILE
   echo ""                              >>$DEBUGFILE
   echo "DV Uebergabeparameter:"        >>$DEBUGFILE   
   echo "  David User  :" $DAV_ID       >>$DEBUGFILE
   echo "  Lock_ID     :" $3            >>$DEBUGFILE
   echo "  Praxis      :" $2            >>$DEBUGFILE
   echo "  PatNr.      :" $1            >>$DEBUGFILE
   echo ""                              >>$DEBUGFILE
   echo "Aktuelle DV Eportdatei:"       >>$DEBUGFILE
   echo "   $PFILE"                     >>$DEBUGFILE
   echo ""                              >>$DEBUGFILE
   echo "Skript Generierte Werte:"      >>$DEBUGFILE
   echo "  Detox vorh. :" $DETX         >>$DEBUGFILE
   echo "  PatNr.      :" $P1           >>$DEBUGFILE 
   echo "  Nachname    :" $P2           >>$DEBUGFILE
   echo "  Vorname     :" $P3           >>$DEBUGFILE
   echo "  DAVCMD aktiv:" $GOBAT        >>$DEBUGFILE
   echo "  Dok.ablage  :" $fullpfad     >>$DEBUGFILE
   echo "  Pordner     :" $APUSER       >>$DEBUGFILE
   echo -n "  Linkname    : "           >>$DEBUGFILE
   ls $APUSER                           >>$DEBUGFILE
   chmod 666 $DEBUGFILE
fi
####################################################
#
#
exit 0
