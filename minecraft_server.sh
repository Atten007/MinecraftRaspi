#!/bin/bash

# Funktion zur Erstellung eines Backups
create_backup() {
    backup_dir="$1"
    mkdir -p "$backup_dir"
    timestamp=$(date +%Y%m%d%H%M%S)
    cp -r "world" "$backup_dir/backup_$timestamp"
}

# RAM-Einstellungen
echo "Bitte gib die RAM-Zuweisung für den Server ein (in MB):"
read ram_allocation

# Speicherort auswählen
echo "Bitte gib den Pfad zum Verzeichnis ein, in dem die Server-Dateien gespeichert werden sollen:"
read server_dir

# Verzeichnis erstellen und in das Verzeichnis wechseln
mkdir -p $server_dir
cd $server_dir

# Server-Version auswählen
echo "Bitte gib die gewünschte Server-Version ein (z.B. 1.17.1):"
read server_ver

# Variablen festlegen
server_jar="minecraft_server.${server_ver}.jar"
eula_file="eula.txt"

# Server JAR-Datei herunterladen
wget -O $server_jar "https://s3.amazonaws.com/Minecraft.Download/versions/${server_ver}/${server_jar}"

# EULA akzeptieren
echo "eula=true" > $eula_file

# Backups erstellen
echo "Möchtest du regelmäßige Backups erstellen? (j/n)"
read create_backups

if [[ $create_backups == "j" || $create_backups == "J" ]]; then
    echo "Bitte gib den Pfad zum Verzeichnis ein, in dem die Backups gespeichert werden sollen:"
    read backup_dir

    echo "Bitte gib die gewünschte Zeit (im 24-Stunden-Format) für den Neustart des Servers ein (z.B. 03:00):"
    read restart_time

    # Cron-Job für regelmäßige Backups einrichten
    cron_job="0 $restart_time * * * $(pwd)/create_backup.sh $backup_dir"
    (crontab -l ; echo "$cron_job") | crontab -
fi

# Skript für Backuperstellung erstellen
echo '#!/bin/bash' > create_backup.sh
echo 'backup_dir="$1"' >> create_backup.sh
echo 'mkdir -p "$backup_dir"' >> create_backup.sh
echo 'timestamp=$(date +%Y%m%d%H%M%S)' >> create_backup.sh
echo 'cp -r "world" "$backup_dir/backup_$timestamp"' >> create_backup.sh
chmod +x create_backup.sh

# Server starten
java -Xmx${ram_allocation}M -Xms${ram_allocation}M -jar $server_jar nogui
