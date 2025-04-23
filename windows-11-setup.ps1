# It should be run in Administrator mode from PowerShell.
# Makes sure you have all the latest updates before running this!

# run this first to enable scripts:
# Set-ExecutionPolicy Bypass -Scope Process
# iex (New-Object Net.WebClient).DownloadString('https://example.com/script.ps1')

# Ensure the script runs with administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Output("Uninstalling all the packaged software")
DISM /Online /Get-ProvisionedAppxPackages | select-string Packagename | % {$_ -replace("PackageName : ", "")} | select-string "^((?!WindowsStore).)*$" | select-string "^((?!SecHealthUI).)*$" | select-string "^((?!DesktopAppInstaller).)*$" | ForEach-Object {Remove-AppxPackage -allusers -package $_}

Write-Output("Uninstalling more default apps")
winget uninstall "Cortana" --silent --accept-source-agreements
winget uninstall "Disney+" --silent --accept-source-agreements
winget uninstall "Mail and Calendar" --silent --accept-source-agreements
winget uninstall "Microsoft News" --silent --accept-source-agreements
winget uninstall "Microsoft OneDrive" --silent --accept-source-agreements
winget uninstall "Microsoft Tips" --silent --accept-source-agreements
winget uninstall "MSN Weather" --silent --accept-source-agreements
winget uninstall "Movies & TV" --silent --accept-source-agreements
winget uninstall "Office" --silent --accept-source-agreements
winget uninstall "OneDrive" --silent --accept-source-agreements
winget uninstall "Spotify Music" --silent --accept-source-agreements
winget uninstall "Windows Maps" --silent --accept-source-agreements
winget uninstall "Xbox TCUI" --silent --accept-source-agreements
winget uninstall "Xbox Game Bar Plugin" --silent --accept-source-agreements
winget uninstall "Xbox Game Bar" --silent --accept-source-agreements
winget uninstall "Xbox Identity Provider" --silent --accept-source-agreements
winget uninstall "Xbox Game Speech Windows" --silent --accept-source-agreements

Write-Output("Changing registry settings for taskbar, lockscreen, and more...")
# Disable Chat, Widgets Taskbar Buttons
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0
# Disable Game Overlays
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0
# Show hidden files and folders
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
# Don't hide file extensions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 1
# Don't include public folders in search (faster)
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_SearchFiles' -Value 1

# Don't show ads / nonsense on the lockscreen
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'ContentDeliveryAllowed' -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenEnabled' -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenOverlayEnabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-88000326Enabled' -Value 0

# Stop pestering to create a Microsoft Account. Local accounts: this is the way.
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'NoConnectedUser' -PropertyType DWord -Value 3 -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_AccountNotifications' -PropertyType DWord -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_AccountNotifications' -Value 0

# Get rid of the incredibly stupid "Show More Options" context menu default that NO ONE ASKED FOR
New-Item -Path 'HKCU:\Software\Classes\CLSID' -Name '{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -f
New-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Name 'InprocServer32' -Value '' -f

# Set timezone automatically
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name "Start" -Value "00000003";

# Disable prompts to create an MSFT account
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value "00000000";

Write-Output("Disabling as much data collection / mining as we can...")
Get-Service DiagTrack | Set-Service -StartupType Disabled
Get-Service dmwappushservice | Set-Service -StartupType Disabled
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0

# Disable Copilot
New-Item -Path 'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value '1' -f
New-Item -Path 'HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value '1' -f
New-Item -Path 'HKLM\Software\Policies\Microsoft\Windows\Windows Search' -Name 'EnableDynamicContentInWSB' -Value '0' -f
New-Item -Path 'HKLM\Software\Policies\Microsoft\Edge' -Name 'HubsSidebarEnabled' -Value '0' -f
New-Item -Path 'HKCU\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value '1' -f
New-Item -Path 'HKLM\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value '1' -f

# Finally, stop and restart explorer.
Get-Process -Name explorer | Stop-Process
start explorer.exe
