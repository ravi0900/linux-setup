#!/bin/bash

set -e

usage() {
    echo "Usage: $0 <action> [archive1 archive2 archive3]"
    echo "  <action>  : 'all' to install all archives, 'single' to specify a single archive."
    echo "  [archives]: Paths to the archive files (optional if 'all' is used)."
    echo "Additional Actions:"
    echo "  --make-system-wide : Make this script system-wide accessible."
    echo "Examples:"
    echo "  $0 all /path/to/goland.tar.gz /path/to/android-studio.tar.gz /path/to/go-version-linux-amd64.tar.gz"
    echo "  $0 single /path/to/go-version-linux-amd64.tar.gz"
    echo "  $0 --make-system-wide"
    exit 1
}

GOLAND_DIR="/opt/goland"
ANDROID_STUDIO_DIR="/opt/android-studio"
GO_DIR="/usr/local/go"

check_archive_existence() {
    local archive=$1
    if [ ! -f "$archive" ]; then
        echo "Error: Archive file $archive does not exist."
        exit 1
    fi
}

handle_existing_installation() {
    local dir=$1
    local app_name=$2

    if [ -d "$dir" ]; then
        read -p "$app_name is already installed in $dir. Overwrite? (y/n): " choice
        case "$choice" in
            y|Y )
                echo "Overwriting $app_name..."
                sudo rm -rf "$dir"
                ;;
            n|N )
                echo "Skipping installation of $app_name."
                return 1
                ;;
            * )
                echo "Invalid choice. Skipping $app_name."
                return 1
                ;;
        esac
    fi
    return 0
}

create_desktop_entry() {
    local app_name=$1
    local exec_path=$2
    local icon_path=$3
    local desktop_file="/usr/share/applications/$app_name.desktop"

    echo "Creating desktop entry for $app_name..."
    sudo bash -c "cat > $desktop_file" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_name
Exec=$exec_path
Icon=$icon_path
Categories=Development;IDE;
Terminal=false
EOL

    echo "Desktop entry created: $desktop_file"
}

install_go() {
    local go_tar=$1
    check_archive_existence "$go_tar"
    if handle_existing_installation "$GO_DIR" "Go"; then
        echo "Installing Go from $go_tar..."
        sudo rm -rf "$GO_DIR"
        sudo tar -C /usr/local -xzf "$go_tar"
        if ! grep -q "/usr/local/go/bin" ~/.profile; then
            echo "Adding Go to PATH..."
            echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
        fi
        source ~/.profile
        echo "Go installation completed."
    fi
}

install_goland() {
    local goland_tar=$1
    check_archive_existence "$goland_tar"
    if handle_existing_installation "$GOLAND_DIR" "GoLand"; then
        echo "Installing GoLand from $goland_tar..."
        sudo mkdir -p "$GOLAND_DIR"
        sudo tar -xvzf "$goland_tar" -C "$GOLAND_DIR" --strip-components=1
        if ! grep -q "$GOLAND_DIR/bin" ~/.bashrc; then
            echo "Adding GoLand to PATH..."
            echo "export PATH=\$PATH:$GOLAND_DIR/bin" >> ~/.bashrc
        fi
        create_desktop_entry "GoLand" "$GOLAND_DIR/bin/goland.sh" "$GOLAND_DIR/bin/goland.png"
    fi
}

install_android_studio() {
    local android_studio_tar=$1
    check_archive_existence "$android_studio_tar"
    if handle_existing_installation "$ANDROID_STUDIO_DIR" "Android Studio"; then
        echo "Installing Android Studio from $android_studio_tar..."
        sudo mkdir -p "$ANDROID_STUDIO_DIR"
        sudo tar -xvzf "$android_studio_tar" -C "$ANDROID_STUDIO_DIR" --strip-components=1
        if ! grep -q "$ANDROID_STUDIO_DIR/bin" ~/.bashrc; then
            echo "Adding Android Studio to PATH..."
            echo "export PATH=\$PATH:$ANDROID_STUDIO_DIR/bin" >> ~/.bashrc
        fi
        create_desktop_entry "Android Studio" "$ANDROID_STUDIO_DIR/bin/studio.sh" "$ANDROID_STUDIO_DIR/bin/studio.png"
    fi
}

make_system_wide() {
    local script_name=$(basename "$0")
    local target="/usr/local/bin/$script_name"

    echo "Making script system-wide accessible..."
    sudo cp "$0" "$target"
    sudo chmod +x "$target"
    echo "Script is now system-wide accessible as '$script_name'."
}

# Main logic
if [ "$#" -lt 1 ]; then
    usage
fi

ACTION=$1
shift

case "$ACTION" in
    all)
        if [ "$#" -ne 3 ]; then
            echo "Error: All three archive paths must be provided for 'all' action."
            usage
        fi
        GOLAND_TAR=$1
        ANDROID_STUDIO_TAR=$2
        GO_TAR=$3
        install_goland "$GOLAND_TAR"
        install_android_studio "$ANDROID_STUDIO_TAR"
        install_go "$GO_TAR"
        ;;
    single)
        if [ "$#" -ne 1 ]; then
            echo "Error: A single archive path must be provided for 'single' action."
            usage
        fi
        ARCHIVE=$1
        read -p "Which tool do you want to install (goland/android-studio/go)? " tool
        case "$tool" in
            goland)
                install_goland "$ARCHIVE"
                ;;
            android-studio)
                install_android_studio "$ARCHIVE"
                ;;
            go)
                install_go "$ARCHIVE"
                ;;
            *)
                echo "Invalid choice. Please choose from 'goland', 'android-studio', or 'go'."
                exit 1
                ;;
        esac
        ;;
    --make-system-wide)
        make_system_wide
        ;;
    *)
        echo "Error: Invalid action. Use 'all', 'single', or '--make-system-wide'."
        usage
        ;;
esac

source ~/.bashrc
echo "Installation completed!"