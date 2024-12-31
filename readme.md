# Script to setup all neccessary tools for dev for linux

## Install_ide.sh 

Donwload go, goland, android studio archive. 

To Install All Tools:

./install_tools.sh all /path/to/goland.tar.gz /path/to/android-studio.tar.gz /path/to/go-version-linux-amd64.tar.gz

To Install a Single Tool:

./install_tools.sh single /path/to/go-version-linux-amd64.tar.gz

For single, you'll be prompted to choose the tool (goland, android-studio, or go).

./install_ide.sh --make-system-wide