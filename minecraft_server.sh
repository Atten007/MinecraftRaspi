#!/bin/bash

# Funktion zur Erstellung eines Backups
create_backup() {
    backup_dir="$1"
    mkdir -p "$backup_dir"
    timestamp=$(date +%Y%m%d%H%M%S)
    cp -r "world" "$backup_dir/backup_$timestamp"
}

# Funktion zum automatischen Aktualisieren des Servers
update_server() {
    echo "Möchtest du den Server automatisch aktualisieren? (j/n)"
    read update_choice

    if [[ $update_choice == "j" || $update_choice == "J" ]]; then
        echo "Aktualisiere den Server..."

        # Server stoppen
        screen -S minecraft -X stuff 'stop'$(echo -ne '\r')

        # Server-Dateien sichern
        create_backup "$backup_dir"

        # Server-Version auswählen
        echo "Bitte gib die gewünschte Server-Version ein (z.B. 1.17.1):"
        read server_ver

        # Server JAR-Datei herunterladen
        wget -O "$server_jar" "https://s3.amazonaws.com/Minecraft.Download/versions/${server_ver}/${server_jar}"
        
        echo "Der Server wurde aktualisiert."

        # Server starten
        start_server
    else
        echo "Der Server wird nicht aktualisiert."
        start_server
    fi
}

# Funktion zum Starten des Servers
start_server() {
    # EULA akzeptieren
    echo "eula=true" > "$eula_file"

    # Backups erstellen
    echo "Möchtest du regelmäßige Backups erstellen? (j/n)"
    read create_backups

    if [[ $create_backups == "j" || $create_backups == "J" ]]; then
        echo "Bitte gib den Pfad zum Verzeichnis ein, in dem die Backups gespeichert werden sollen:"
        read backup_dir

        echo "An welchen Wochentagen sollen die Backups erstellt werden?"
        echo "Bitte gib die gewünschten Wochentage ein (Mo, Di, Mi, Do, Fr, Sa, So)."
        echo "Trenne die Wochentage mit einem Leerzeichen:"
        read -a backup_days

        # Cron-Job für regelmäßige Backups einrichten
        cron_job="0 $restart_time * * ${backup_days[*]} $(pwd)/create_backup.sh $backup_dir"
        (crontab -l ; echo "$cron_job") | crontab -
    fi

    # Server starten
    java -Xmx${ram_allocation}M -Xms${ram_allocation}M -jar "$server_jar" nogui
}

# RAM-Einstellungen
echo "Bitte gib die RAM-Zuweisung für den Server ein (in MB):"
read ram_allocation

# Überprüfen der Betriebssystem-Architektur
if [[ $(uname -m) == "i686" || $(uname -m) == "i386" ]]; then
    echo "32-Bit Betriebssystem erkannt. Die RAM-Zuweisung wird auf 3 GB begrenzt."
    ram_allocation=$((3*1024))
fi

# Speicherort des Servers
echo "Bitte gib den Pfad zum Verzeichnis ein, in dem die Server-Dateien gespeichert werden sollen:"
read server_dir

# Verzeichnis erstellen und in das Verzeichnis wechseln
mkdir -p "$server_dir"
cd "$server_dir"

# Server-Version auswählen
echo "Bitte gib die gewünschte Server-Version ein (z.B. 1.17.1):"
read server_ver

# Variablen festlegen
server_jar="minecraft_server.${server_ver}.jar"
eula_file="eula.txt"

# Server JAR-Datei herunterladen
wget -O "$server_jar" "https://s3.amazonaws.com/Minecraft.Download/versions/${server_ver}/${server_jar}"

# Überprüfen, ob automatische Aktualisierung gewünscht ist
echo "Möchtest du den Server automatisch aktualisieren? (j/n)"
read update_choice

if [[ $update_choice == "j" || $update_choice == "J" ]]; then
    update_server
else
    start_server
fi
