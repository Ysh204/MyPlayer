# Registers MyPlayer Pro in Windows for current user (no admin rights required)
param (
    [string]$ExePath = "$PSScriptRoot\..\build\windows\x64\runner\Release\my_player.exe"
)

$resolvedExe = [System.IO.Path]::GetFullPath($ExePath)
if (-not (Test-Path $resolvedExe)) {
    Write-Error "Executable not found at: $resolvedExe"
    exit 1
}

$progId = "MyPlayer.Video"
$appName = "MyPlayer Pro"
$videoExtensions = @(
    ".mp4", ".mkv", ".avi", ".mov", ".webm", ".flv",
    ".ts", ".m4v", ".wmv", ".3gp", ".mpg", ".mpeg"
)

Write-Host "Registering $appName at: $resolvedExe"

# 1. ProgID definition
$progIdKey = "HKCU:\Software\Classes\$progId"
New-Item -Path $progIdKey -Force | Out-Null
Set-ItemProperty -Path $progIdKey -Name "(default)" -Value "Video File"
New-Item -Path "$progIdKey\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$progIdKey\DefaultIcon" -Name "(default)" -Value "$resolvedExe,0"
New-Item -Path "$progIdKey\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$progIdKey\shell\open\command" -Name "(default)" -Value "`"$resolvedExe`" `"%1`""

# 2. Applications registration
$appKey = "HKCU:\Software\Classes\Applications\my_player.exe"
New-Item -Path $appKey -Force | Out-Null
Set-ItemProperty -Path $appKey -Name "FriendlyAppName" -Value $appName
New-Item -Path "$appKey\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$appKey\DefaultIcon" -Name "(default)" -Value "$resolvedExe,0"
New-Item -Path "$appKey\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$appKey\shell\open\command" -Name "(default)" -Value "`"$resolvedExe`" `"%1`""

$supportedTypesKey = "$appKey\SupportedTypes"
New-Item -Path $supportedTypesKey -Force | Out-Null
foreach ($ext in $videoExtensions) {
    Set-ItemProperty -Path $supportedTypesKey -Name $ext -Value ""
}

# 3. Add to OpenWithProgids for each extension
foreach ($ext in $videoExtensions) {
    $extKey = "HKCU:\Software\Classes\$ext\OpenWithProgids"
    New-Item -Path $extKey -Force | Out-Null
    Set-ItemProperty -Path $extKey -Name $progId -Value ([byte[]]@())

    $openWithList = "HKCU:\Software\Classes\$ext\OpenWithList\my_player.exe"
    New-Item -Path $openWithList -Force | Out-Null
}

# 4. RegisteredApplications capabilities
$capKey = "HKCU:\Software\MyPlayer\Capabilities"
New-Item -Path "$capKey\FileAssociations" -Force | Out-Null
Set-ItemProperty -Path $capKey -Name "ApplicationName" -Value $appName
Set-ItemProperty -Path $capKey -Name "ApplicationDescription" -Value "A lightweight desktop video player."

foreach ($ext in $videoExtensions) {
    Set-ItemProperty -Path "$capKey\FileAssociations" -Name $ext -Value $progId
}

$regAppKey = "HKCU:\Software\RegisteredApplications"
New-Item -Path $regAppKey -Force | Out-Null
Set-ItemProperty -Path $regAppKey -Name "MyPlayer Pro" -Value "Software\MyPlayer\Capabilities"

# 5. Notify Shell of association change
$code = @'
using System;
using System.Runtime.InteropServices;
public class ShellNotify {
    [DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
'@
Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
[ShellNotify]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero) # SHCNE_ASSOCCHANGED

Write-Host "Successfully registered $appName with Windows."
Write-Host "You can now select $appName directly in Windows Settings > Default Apps or right-click any video -> Open with -> Always."

