# 1. Install proot-distro
pkg update && pkg install proot-distro -y

# 2. Grant Termux access to your phone's downloads folder (if saved via browser)
termux-setup-storage

# 3. Install the container directly from the .tar file
proot-distro install --name gamebox ~/storage/downloads/gamebox-arm64-main.tar.gz

# 4. Boot into your custom container
proot-distro login gamebox
