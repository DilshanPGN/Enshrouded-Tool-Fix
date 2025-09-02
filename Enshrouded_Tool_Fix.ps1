# Creator LiaNdrY
$ver = "1.1.11"
$Host.UI.RawUI.WindowTitle = "Enshrouded Tool Fix v$ver"
$logFilePath = "$env:TEMP\Enshrouded_Tool_Fix.log"
if (Test-Path -Path $logFilePath) {
    Remove-Item -Path $logFilePath
}
# Function for writing to a file and outputting to the console
function WHaL {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$Message,
        [switch]$NoNewline,
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Gray
    )
    if ([string]::IsNullOrWhiteSpace($Message)) {
        Write-Host ""
        Write-Output "" | Out-File -FilePath $logFilePath -Encoding UTF8 -Append
        return
    }
    $Message | Out-File -FilePath $logFilePath -Encoding UTF8 -Append -NoNewline:$NoNewline
    if ($NoNewline) {
        Write-Host $Message -NoNewline -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}
# Checking whether the script is running with administrator rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    WHaL "This script must be run as an administrator." -ForegroundColor Yellow
    WHaL ""
    WHaL "Press Enter to close the console..."
    [Console]::ReadLine() | Out-Null
    exit
}
WHaL "Script is running as an administrator. Proceeding with the work..." -ForegroundColor Green
WHaL ""

# Manually set the game path since it's not in Steam folder
$gamePath_0 = "D:\Games\Enshrouded"
if (-not (Test-Path $gamePath_0)) {
    WHaL "Path to the installed game does not exist: $gamePath_0"
    WHaL ""
    Read-Host -Prompt "Press Enter to Exit"
    exit
} else {
    WHaL "Using manually specified game path: $gamePath_0"
    WHaL ""
}

# All code below referencing $gamePath_0 will now use D:\Games\Enshrouded

# Checking Vulkan API layer versions for old versions
$vCardPath = Get-ItemProperty -Path "HKLM:\HARDWARE\DEVICEMAP\VIDEO" -ErrorAction SilentlyContinue
$minValue = [int]::MaxValue
foreach ($property in $vCardPath.PSObject.Properties) {
    if ($property.Value -like "\*\*\*\*\*\Video\{*}\*") {
        $path = $property.Value -replace '\\Registry\\Machine\\', 'HKLM:\\'
        $value = [int]($path -replace '.*\\(\d+)$', '$1')
        if ($value -lt $minValue) {
            $minValue = $value
            $Api_Video0 = $path
        }
    }
}
# ... (rest of code unchanged, all references to $gamePath_0 now use the D:\Games\Enshrouded value)

# (The rest of the script remains as is, except for $gamePath_0 being set manually above)
# If you want to set $game_id for future use, keep it:
$game_id = 1203620

# When you need to reference the game log and config files, their paths will be:
$fileJson = "$gamePath_0\enshrouded_local.json"
$gameLog = "$gamePath_0\enshrouded.log"
$FolderCache = "$gamePath_0\shadercache\$game_id"

# ... (rest of script unchanged)
# Write data to log file
$dateTime = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
if (-not (Test-Path -Path "$gamePath_0\Enshrouded_Tool_Fix")) {
    New-Item -Path "$gamePath_0\Enshrouded_Tool_Fix" -ItemType Directory -Force
}
Copy-Item -Path $logFilePath -Destination "$gamePath_0\Enshrouded_Tool_Fix\Enshrouded_Tool_Fix_$dateTime.log"
Remove-Item -Path $logFilePath -Force
Start-Process -FilePath "$gamePath_0\Enshrouded_Tool_Fix"
Read-Host -Prompt "Press Enter to Exit"
exit
