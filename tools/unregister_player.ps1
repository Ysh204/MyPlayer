# Removes MyPlayer Pro file registrations for current user
$appName = "MyPlayer Pro"
$progId = "MyPlayer.Video"
$videoExtensions = @(
    ".mp4", ".mkv", ".avi", ".mov", ".webm", ".flv",
    ".ts", ".m4v", ".wmv", ".3gp", ".mpg", ".mpeg"
)

Remove-Item -Path "HKCU:\Software\Classes\$progId" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Classes\Applications\my_player.exe" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\MyPlayer" -Recurse -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\RegisteredApplications" -Name $appName -ErrorAction SilentlyContinue

foreach ($ext in $videoExtensions) {
    Remove-ItemProperty -Path "HKCU:\Software\Classes\$ext\OpenWithProgids" -Name $progId -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Classes\$ext\OpenWithList\my_player.exe" -Recurse -ErrorAction SilentlyContinue
}

$code = @'
using System;
using System.Runtime.InteropServices;
public class ShellNotifyUnreg {
    [DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
'@
Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
[ShellNotifyUnreg]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

Write-Host "Successfully unregistered $appName from Windows."

