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




# Bitte anpassen: ############################################################
#
# Pfad fuer die Samba Shares der User, bitte mit der smb.conf abgleichen:
#
smbpfad="/home/david/trpword/.stationen" 
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
debug=0
debugfile="/home/david/trpword/pordner-$3-debug.txt"
#
##############################################################################
#
# Batch Aufruf am Windows PC, falls gewuenscht:
#
gobat=0					  # Batch starten (0/1)?
#
ip="172.16.11.98"                         # IP des WinPC (Rexserver!)
port="6667"                               # Port des Rexservers
batch="c:\\david\startwas.bat"            # Name der Batchdatei am WinPC
#
#
# Ende der Anpassungen #######################################################
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
ichbins=`whoami`
apuser="$smbpfad/$ichbins"
[ -d $apuser ] || mkdir -p -m 666 $apuser
#
#
# ggf. alten Symlink beseitigen:
find $smbpfad/$ichbins -maxdepth 1 -type l -delete
#
#
# detox Tool suchen:
DETX="Nein"
[ -x /usr/bin/detox -o -x /usr/local/bin/detox ] && DETX="Ja"
#
#
# Namen des Patienten definieren:
Patient="$1"
[ -z $Patient ] && Patient="Patient"
#
#
# Vollen Pat.namen bestimmen, sofern Exportdatei vorliegt UND $FIXNAME inaktiv:
if [ ${FIXNAME} = "0" ]; then
   PFile="/home/david/trpword/$3/patienten$3.txt"
   #
   if [ -e $PFile ]; then
      P1=`sed -n '2 p' $PFile | awk -F";" '{print $1}' | sed 's/"//g'`
      P2=`sed -n '2 p' $PFile | awk -F";" '{print $2}' | sed 's/"//g' | tr [:blank:] '-' | tr [:lower:] [:upper:]`
      P3=`sed -n '2 p' $PFile | awk -F";" '{print $3}' | sed 's/"//g' | tr [:blank:] '-'`
      #
      Patient="$P2"_"$P3"_"$P1"
   fi
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
ln -s $fullpfad $apuser/$Patient
#
#
# Falls der Name Sonderzeichen enthaelt, sollte mit detox konvertiert werden, damit aus 
# Windows Sicht (UTF-8) die Darstellung korrket ist:
[ ${DETX} = "Ja" ] && detox --special $apuser/$Patient
#
#
# Ggf. Batchdatei am Windowsrechner starten:
[ ${gobat} = "1" ] && echo "DAVCMD start /min $batch" | netcat $ip $port >/dev/null
#
#
####################################################
if [ ${debug} = "1" ]; then
   echo ""                            >$debugfile
   echo "Aktueller DV Patientenaufruf:" >>$debugfile
   echo "-----------------------------" >>$debugfile
   echo ""                              >>$debugfile
   echo "DV Uebergabeparameter:"        >>$debugfile   
   echo "  David User  :" $DAV_ID       >>$debugfile
   echo "  Lock_ID     :" $3            >>$debugfile
   echo "  Praxis      :" $2            >>$debugfile
   echo "  PatNr.      :" $1            >>$debugfile
   echo ""                              >>$debugfile
   echo "Aktuelle DV Eportdatei:"       >>$debugfile
   echo "   $PFile"                     >>$debugfile
   echo ""                              >>$debugfile
   echo "Skript Generierte Werte:"      >>$debugfile
   echo "  Detox vorh. :" $DETX         >>$debugfile
   echo "  PatNr.      :" $P1           >>$debugfile 
   echo "  Nachname    :" $P2           >>$debugfile
   echo "  Vorname     :" $P3           >>$debugfile
   echo "  DAVCMD aktiv:" $gobat        >>$debugfile
   echo "  Dok.ablage  :" $fullpfad     >>$debugfile
   echo "  Pordner     :" $apuser       >>$debugfile
   echo -n "  Linkname    : "           >>$debugfile
   ls $apuser                           >>$debugfile
   chmod 666 $debugfile
fi
####################################################
#
#
exit 0
