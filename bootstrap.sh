#!/usr/bin/env zsh

# Send a Beep to get attention in the Terminal
function notify(){
    afplay /System/Library/Sounds/Blow.aiff
    open /System/Applications/Utilities/Terminal.app
}
export -f notify

# echo a string to the CLI
function showinfo(){
    # Define font style
    local REGULAR=$(tput sgr0)
    local BOLD=$(tput bold)
    # Define colors
    local NOCOLOR='\033[0m'
    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local GRAY='\033[1;30m'

    # Check if 2nd Parameter is passed
    if [ -n "$2" ]; then
        case "$2" in
            note) echout="\n$1";;
            shout) echout="\n\n${BLUE}$1\n------------------------------${NOCOLOR}";;
            confirm) echout="$1...${GREEN}done ✅${NOCOLOR}\n";;
            error) echout="\n❌ ${RED}$1${NOCOLOR}\n";;
            notice) echout="\n💡 ${YELLOW}$1${NOCOLOR}\n";;
            blank) echout="";;
            *) echout="$1";;
        esac
    else
        echout="$1"
    fi
    echo -e "$echout"
}
export -f showinfo

# Check if a variable is not empty and not whitespace
function checkIfNotEmpty() {
    if [ -n "$1" ]; then
        # Is NOT empty
        return 0 # true
    else
        # Is empty
        return 1 # false
    fi
}
export -f checkIfNotEmpty

# Check if a local path exists and is readable
function checkIfFileExists(){
    if [ -r "$1" ]; then
        # Found (and readable)
        return 0 # true
    else
        # Does not exist
        return 1 # false
    fi
}
export -f checkIfFileExists

# Check if Mac is Apple Silicon (otherwise Intel x86)
function checkIfAppleSilicion(){
    # Intel=x86_64 | AppleSilicon=arm64
    if uname -m | grep -q -w arm64; then
        return 0 # true
    else
        return 1 # false
    fi
}
export -f checkIfAppleSilicion

# Check if Mac is portable
# (MacBook, MacBook Air, MacBook Pro)
function checkIfMacIsPortable(){
    if system_profiler -detailLevel mini SPHardwareDataType | grep -q Book; then
        return 0 # true
    else
        return 1 # false
    fi
}
export -f checkIfMacIsPortable

# Check if User has authenticated to App Store
function checkIfAppStoreAuthenticated(){
    if ! command -v mas &> /dev/null; then
        # Not authenticated
        return 1 # false
    else
        # Authenticated
        return 0 # true
    fi
}
export -f checkIfAppStoreAuthenticated

# Get logged-in user's Username
function getUsername(){
    local whoami="$(id -un)"
    echo whoami
    return 0
}
export -f getUsername

# Check if current User is in admin group
# Source: https://apple.stackexchange.com/a/179531/86244
function checkIfUserIsAdmin(){
    if groups $USER | grep -q -w admin; then
        # User is admin
        return 0 # true
    else
        # User is NOT admin
        return 1 # false
    fi
}
export -f checkIfUserIsAdmin

function macosGatekeeper(){
    if checkIfNotEmpty "$1"; then
        # --> Notify first
        notify
        # Requires Admin privileges
        if checkIfUserIsAdmin; then
            if [ "$1" = "on" ]; then
                # ENABLE Gatekeeper (Allow apps from "App Store and identified developers")
                sudo spctl --master-enable
            elif [ "$1" = "off" ]; then
                # DISABLE Gatekeeper (Allow apps from "Anywhere")
                sudo spctl --master-disable
            fi
        else
            showinfo "'spctl' requires root privileges. Run with an admin user, or using sudo." "error"
        fi
    else
        # Get current Gatekeeper status
        if spctl --status | grep -q -w enabled; then
            return 0 # enabled
        else
            return 1 # disabled
        fi
    fi
}
export -f macosGatekeeper

# Download a file from a given URL using curl
function downloadFromUrl(){
    # Check that the URL and destination file name are valid
    if checkIfNotEmpty "$1" && checkIfNotEmpty "$2"; then
        local downloadFolder="$HOME/Downloads/"
        local downloadPath="$downloadFolder$2"

        # Use curl to fetch the URL and store the resource
        #  -S = silent, but allow errors & progress bar
        #  -L = follow HTTP redirects
        #  -f = fail silently on server errors
        #  -# = show a progress bar (instead of a table)
        #  -A = use a custom User Agent string
        curl -SLf\# "$1" -o "$downloadPath" -A "macOS-scripted-setup/1.0 (compatible; +https://github.com/Swiss-Mac-User/macOS-scripted-setup)"
    else
        showinfo "Missing URL or download target path" "error"
    fi
}
export -f downloadFromUrl

# Unzip a ZIP-file in place
function unzipFile(){
    local downloadFolder="$HOME/Downloads/"
    local filePath="$downloadFolder$1"
    if checkIfFileExists "$filePath"; then
        unzip -qq "$filePath" -d "$downloadFolder"
    else
        showinfo "ZIP file not found:\n$filePath" "error"
    fi
}
export -f unzipFile

# Unmount a DMG-image and copy App to Downloads folder
function unmountFile(){
    local downloadFolder="$HOME/Downloads/"
    local filePath="$downloadFolder$1"
    if checkIfFileExists "$filePath" && checkIfNotEmpty "$2"; then
        local appFilename="$2.app"
        # --> Mount Volume
        hdiutil attach "$filePath" -quiet
        # --> Move to Applications (suppress errors)
        cp -r "/Volumes/$2/$2.app" "$downloadFolder"
        # --> Unmount Volume
        hdiutil unmount "/Volumes/$2" -force -quiet
    else
        showinfo "Missing file path or Application name" "error"
        return 1 # error
    fi
}
export -f unmountFile

# Move an Application to the User or System Applications folder
# (and optionally open it upon moving)
function moveApplication(){
    if checkIfNotEmpty "$1"; then
        local downloadedApplicationPath="$HOME/Downloads/$1"

        if checkIfFileExists "$downloadedApplicationPath"; then
            if checkIfFileExists "$HOME/Applications/"; then
                local ApplicationsDir="$HOME/Applications/"
            else
                local ApplicationsDir="/Applications/"
            fi

            # Disable Quarantine for App (not working on macOS 13+)
            #disableAppQuarantine "$downloadedApplicationPath"

            # Move the Application file
            mv "$downloadedApplicationPath" "$ApplicationsDir"

            # Open App, if required
            if checkIfNotEmpty "$2" && [ "$2" = "open" ]; then
                open -gj "$ApplicationsDir$1"
            fi
        else
            showinfo "Cannot move Application '$1'\nPath not found: $downloadedApplicationPath" "error"
            return 1 # error
        fi
    else
        showinfo "No Application name provided" "error"
        return 1 # error
    fi
}
export -f moveApplication

function installApp1Password(){
	# --> Download & Unzip
	downloadFromUrl "https://downloads.1password.com/mac/1Password.zip" "1PasswordInstaller.zip"
	unzipFile "1PasswordInstaller.zip"
	# --> Launch Installer
	open "$HOME/Downloads/1Password Installer.app"
}
export -f installApp1Password

# "1Password for Safari" Browser Extension
function masinstallApp1PasswordSafariExtension(){
	# https://apps.apple.com/ch/app/1password-for-safari/id1569813296
	mas install 1569813296
}
export -f masinstallApp1PasswordSafariExtension

# -- Remove Apple's Garageband.app --
function removeAppGarageband(){
	local location="/Applications/GarageBand.app"
	if checkIfFileExists "$location"; then
		rm "$location"
	fi
}
export -f removeAppGarageband

# -- Remove Apple's iMovie.app --
function removeAppiMovie(){
	local location="/Applications/iMovie.app"
	if checkIfFileExists "$location"; then
		rm "$location"
	fi
}
export -f removeAppiMovie

# -- FileVault2 --
# --> Check if FileVault is active
# Source: https://apple.stackexchange.com/q/70969/86244
function checkIfFileVaultOn(){
    if [ "$(fdesetup isactive)" = "true" ]; then
        return 0 # true (is active)
    else
        return 1 # false (not enabled)
    fi
}
export -f checkIfFileVaultOn

# --> Enable disk encryption of the macOS System Drive
function enableFileVault(){
    # Requires Admin privileges
    if checkIfUserIsAdmin; then
        if ! checkIfFileVaultOn; then
            # --> Notify first
            notify
            sudo fdesetup enable $(id -un)
        else
            # fdesetup status
            showinfo "FileVault is already enabled." "notice"
        fi
    else
        showinfo "'enableFileVault' requires root privileges. Run with an admin user, or using sudo." "error"
    fi
}
export -f enableFileVault

# -- Built-in Firewall (com.apple.alf.plist) --
# --> Enable built-in Firewall
function enableFirewall(){
    # Requires Admin privileges
    if checkIfUserIsAdmin; then
        # --> Notify first
        notify
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    else
        echo "'enableFirewall' requires system administrator or root privileges. Run with an admin user, or using sudo."
    fi
}
export -f enableFirewall

# -- Screensaver --
# Require password immediately after sleep or screen saver begins
function enableUserpasswordOnScreensaver(){
    defaults write com.apple.screensaver "askForPassword" -int 1
    defaults write com.apple.screensaver "askForPasswordDelay" -int 0
}
export -f enableUserpasswordOnScreensaver

# -- Time Machine settings --
# --> Prevent Time Machine asking to use new Disks as backup volume
function muteTimeMachine(){
    defaults write com.apple.TimeMachine "DoNotOfferNewDisksForBackup" -bool TRUE
}
export -f muteTimeMachine

# -- MacBook Trackpad behaviours --
# --> Improve Trackpad Click behaviours (single and right click)
function enableTrackpadClicking(){
	# Enable Single Tap to Click
	defaults write com.apple.AppleMultitouchTrackpad "Clicking" -int 1
	# Enable Right Click
	defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string 'TwoButton'
	defaults write com.apple.AppleMultitouchTrackpad "TrackpadRightClick" -int 1
}
export -f enableTrackpadClicking

# File save, save to disk by default rather than to iCloud
function saveToDiskInsteadOfiCloud(){
    defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool FALSE
}
export -f saveToDiskInsteadOfiCloud

# Finder, show all filename extensions
function showAllFileExtensions(){
    defaults write NSGlobalDomain "AppleShowAllExtensions" -bool TRUE
}
export -f showAllFileExtensions

# Disable creation of Metadata Files on Network Volumes (avoids creation of .DS_Store and AppleDouble ._ files.)
function disableMetadataFilesOnNetworkshares(){
    defaults write com.apple.desktopservices "DSDontWriteNetworkStores" -bool TRUE
}
export -f disableMetadataFilesOnNetworkshares

# Disable creation of Metadata Files on USB Volumes (avoids creation of .DS_Store and AppleDouble ._ files.)
function disableMetadataFilesOnExternalDrives(){
    defaults write com.apple.desktopservices "DSDontWriteUSBStores" -bool TRUE
}
export -f disableMetadataFilesOnExternalDrives


# ------------------------------
#          INITIALIZE
# ------------------------------
showinfo "Enabling FileVault:" "note"
enableFileVault
showinfo "" "confirm"

showinfo "Enabling Firewall:" "note"
enableFirewall
showinfo "" "confirm"

showinfo "Disabling Time Machine prompts for new connected drives:" "note"
muteTimeMachine
showinfo "" "confirm"

showinfo "Enabling password prompt when interrupting Screensaver:" "note"
enableUserpasswordOnScreensaver
showinfo "" "confirm"

showinfo "Enable Tap to Click on the Trackpad:" "note"
enableTrackpadClicking
showinfo "" "confirm"

showinfo "Customizing the macOS Finder:" "notice"

# --> Photos handling when Apple Devices connected
showinfo "Disabling auto-import of Photos (from connected Apple Devices):" "note"
preventAutoImportPhotos
showinfo "" "confirm"

# -- Finder windows & folders --
showinfo "Improving Finder windows and dialogues:" "note"
disableMetadataFilesOnNetworkshares
disableMetadataFilesOnExternalDrives
saveToDiskInsteadOfiCloud
showAllFileExtensions

# -- REMOVE pre-installed large Apps --
showinfo "Removing Garageband App:" "note"
removeAppGarageband
showinfo "(removed if present)" "confirm"

showinfo "Removing iMovie App:" "note"
removeAppiMovie
showinfo "(removed if present)" "confirm"

# -- 1Password.app --
showinfo "Installing 1Password:" "note"
installApp1Password
showinfo "" "confirm"
