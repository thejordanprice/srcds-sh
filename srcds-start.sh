#!/bin/bash

# Variables
SRCDS_PORT=27015
SRCDS_MAXPLAYERS=18
SRCDS_MAP="de_dust2"
STEAMCMD_DIR="$HOME/steamcmd"
SRCDS_INSTALL_DIR="$HOME/srcds"
STEAMCMD="./steamcmd.sh"
GAME="cstrike"
HOSTNAME="CounterStrike Source Server"
MOTD="Welcome to this special place!"

# URLs for Metamod:Source and Sourcemod
METAMOD_URL="https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1313-linux.tar.gz"
SOURCEMOD_URL="https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6968-linux.tar.gz"

# Array of SteamIDs for admin users
ADMINS=(
    "STEAM_0:0:12345678"    # unknown
)

# Function to check if steamcmd is installed
install_steamcmd() {
    if [ ! -f "$STEAMCMD_DIR/$STEAMCMD" ]; then
        echo "SteamCMD not found. Installing SteamCMD..."
        mkdir -p "$STEAMCMD_DIR"
        cd "$STEAMCMD_DIR" || exit
        curl -O https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
        tar -xvzf steamcmd_linux.tar.gz
    fi
}

# Install SRCDS with steamcmd
install_srcds() {
    echo "Installing SRCDS..."
    cd "$STEAMCMD_DIR" || exit
    $STEAMCMD +login anonymous +force_install_dir "$SRCDS_INSTALL_DIR" +app_update 232330 validate +quit
}

# Install Metamod:Source
install_metamod() {
    echo "Installing Metamod:Source..."
    cd "$SRCDS_INSTALL_DIR/$GAME" || exit
    curl -SL "$METAMOD_URL" -o metamod.tar.gz
    tar -xzf metamod.tar.gz
    rm metamod.tar.gz
    echo "Metamod:Source installed!"
}

# Install Sourcemod
install_sourcemod() {
    echo "Installing Sourcemod..."
    cd "$SRCDS_INSTALL_DIR/$GAME" || exit
    curl -SL "$SOURCEMOD_URL" -o sourcemod.tar.gz
    tar -xzf sourcemod.tar.gz
    rm sourcemod.tar.gz
    echo "Sourcemod installed!"
}

# Add SteamIDs to admins_simple.ini
configure_admins() {
    ADMIN_FILE="$SRCDS_INSTALL_DIR/$GAME/addons/sourcemod/configs/admins_simple.ini"

    # Ensure the Sourcemod directory and admin file exist
    if [ -f "$ADMIN_FILE" ]; then
        echo "Configuring admins in $ADMIN_FILE..."
        for STEAMID in "${ADMINS[@]}"; do
            echo "\"$STEAMID\" \"99:z\"" >> "$ADMIN_FILE"
        done
        echo "Admins configured!"
    else
        echo "ERROR: Sourcemod admin file not found at $ADMIN_FILE."
        exit 1
    fi
}

# Add server title and MOTD to server.cfg
configure_server_cfg() {
    echo "Configuring server.cfg with server-side settings..."

    CFG_FILE="$SRCDS_INSTALL_DIR/$GAME/cfg/server.cfg"

    # Ensure server.cfg exists and add settings
    mkdir -p "$(dirname "$CFG_FILE")"
    cat <<EOL > "$CFG_FILE"
hostname "$HOSTNAME"
motd "$MOTD"
sv_minrate 13000
sv_maxrate 30000
sv_minupdaterate 33
sv_maxupdaterate 67
sv_mincmdrate 33
sv_maxcmdrate 67
sv_client_cmdrate_difference 1
sv_client_predict 1
sv_client_min_interp_ratio -1
sv_client_max_interp_ratio -1
EOL
    echo "server.cfg updated!"
}

# Configure and start SRCDS with custom parameters
start_srcds() {
    echo "Starting SRCDS with the following parameters:"
    echo "Port: $SRCDS_PORT"
    echo "Map: $SRCDS_MAP"
    echo "Max Players: $SRCDS_MAXPLAYERS"

    cd "$SRCDS_INSTALL_DIR" || exit

    # Check if the game directory exists
    if [ ! -d "$SRCDS_INSTALL_DIR/$GAME" ]; then
        echo "ERROR: The game directory for $GAME does not exist in $SRCDS_INSTALL_DIR."
        exit 1
    fi

    ./srcds_run -game "$GAME" -console -usercon +map "$SRCDS_MAP" -port "$SRCDS_PORT" +maxplayers "$SRCDS_MAXPLAYERS"
}

# Main script execution
install_steamcmd
install_srcds
install_metamod
install_sourcemod
configure_admins
configure_server_cfg
start_srcds
