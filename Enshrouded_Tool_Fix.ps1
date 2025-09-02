# Creator LiaNdrY - Modified for non-Steam installations
$ver = "1.2.0"
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

# --- Administrator check ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
           IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    WHaL "This script must be run as an administrator." -ForegroundColor Yellow
    WHaL ""
    WHaL "Press Enter to close the console..."
    [Console]::ReadLine() | Out-Null
    exit
}
WHaL "Script is running as an administrator. Proceeding..." -ForegroundColor Green
WHaL ""

# --- Hardcoded game path (no Steam required) ---
$gamePath_0 = "E:\Game Instalations\Enshrouded Build 06052025\Enshrouded"
$gamePath_1 = "$gamePath_0\enshrouded.exe"

if (Test-Path $gamePath_1) {
    WHaL "Found installed game in: $gamePath_0"
    WHaL ""
} else {
    WHaL "Path to the installed game does not exist: $gamePath_0"
    WHaL ""
    Read-Host -Prompt "Press Enter to Exit"
    exit
}

# --- Vulkan Layer / Driver Checks ---
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

$Api_Video_x64 = (Get-ItemProperty -Path "$Api_Video0" -ErrorAction SilentlyContinue).PSObject.Properties | 
                 Where-Object { $_.Name -match 'Vulkan' -and $_.Name -match 'Driver' -and $_.Name -notmatch 'Wow' -and $_.Name -notmatch 'SCD' }
$Api_Video_x86 = (Get-ItemProperty -Path "$Api_Video0" -ErrorAction SilentlyContinue).PSObject.Properties | 
                 Where-Object { $_.Name -match 'Vulkan' -and $_.Name -match 'Driver' -and $_.Name -match 'Wow' -and $_.Name -notmatch 'SCD' }

$pathsVK = @(
    "HKCU:\SOFTWARE\Khronos\Vulkan\ImplicitLayers",
    "HKCU:\SOFTWARE\Wow6432Node\Khronos\Vulkan\ImplicitLayers",
    "HKLM:\SOFTWARE\Khronos\Vulkan\ImplicitLayers",
    "HKLM:\SOFTWARE\WOW6432Node\Khronos\Vulkan\ImplicitLayers"
)

$keyPaths = @{}
foreach ($path in $pathsVK) {
    $properties = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
    if ($properties) {
        foreach ($property in $properties.PSObject.Properties) {
            if ($property.MemberType -eq "NoteProperty" -and $property.Name -like "*.json") {
                if ($property.Name -like "*32.json" -or $property.Name -like "*64.json") {
                    $architecture = if ($property.Name -like "*32.json") { "x86" } else { "x64" }
                } else {
                    $architecture = if ($path -like "*Wow6432Node*") { "x86" } else { "x64" }
                }
                $keyPaths[$property.Name] = @{
                    Path = $path
                    Description = ""
                    Architecture = $architecture
                    Api_Version = ""
                }
            }
        }
    }
}

# Add GPU registry Vulkan entries
$keyPaths[$Api_Video_x86.Name] = @{
    Path = $Api_Video0
    Description = ""
    Architecture = "x86"
    Api_Version = ""
}
$keyPaths[$Api_Video_x64.Name] = @{
    Path = $Api_Video0
    Description = ""
    Architecture = "x64"
    Api_Version = ""
}

# Deduplicate
$uniqueKeyPaths = @{}
$keyPaths.GetEnumerator() | Group-Object -Property { [System.IO.Path]::GetFileName($_.Name) } | 
    Sort-Object -Property { [System.IO.Path]::GetFileName($_.Group[0].Name) } | 
    ForEach-Object {
        $uniqueKeyPaths[$_.Group[0].Name] = $_.Group[0].Value
    }

# Process Vulkan JSON files
foreach ($entry in $uniqueKeyPaths.GetEnumerator() | Sort-Object { [System.IO.Path]::GetFileName($_.Key) }) {
    $jsonPath = $entry.Key
    if (Test-Path $jsonPath) {
        $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
        if ($jsonContent.PSObject.Properties.Name -contains 'ICD') {
            $api_VersionICD = $jsonContent.ICD.api_version
        }
        if ($jsonContent.PSObject.Properties.Name -contains 'layer') {
            $apiVersion = $jsonContent.layer.api_version
            $description = $jsonContent.layer.description
        } elseif ($jsonContent.PSObject.Properties.Name -contains 'layers') {
            $apiVersion = $jsonContent.layers.api_version
            $description = $jsonContent.layers.description
        }
        $uniqueKeyPaths[$entry.Name].Description = $description
        $uniqueKeyPaths[$entry.Name].Api_Version = $apiVersion
    }
}

# --- Print results ---
WHaL "Checking Vulkan layer API versions..."
foreach ($entry in $uniqueKeyPaths.GetEnumerator() | Sort-Object { [System.IO.Path]::GetFileName($_.Key) }) {
    $apiVersion = if ([string]::IsNullOrWhiteSpace($entry.Value.Api_Version)) { "0.0.000" } else {
        if ($entry.Value.Api_Version -is [System.Object[]]) { $entry.Value.Api_Version[0] } else { $entry.Value.Api_Version }
    }
    $description = if ([string]::IsNullOrWhiteSpace($entry.Value.Description)) { "Layer name is empty" } else { $entry.Value.Description }

    if ((![string]::IsNullOrWhiteSpace($entry.Value.Description)) -and ([version]$apiVersion -gt [version]"1.2")) {
        WHaL "$description $($entry.Value.Architecture)" -NoNewline
        WHaL " (v$apiVersion)" -ForegroundColor Green
    }
    if ([version]$apiVersion -lt [version]"1.2") {
        if ($entry.Key -like "*json*") {
            WHaL "$description $($entry.Value.Architecture)" -NoNewline -ForegroundColor Red
            WHaL " (v$apiVersion) - this version is outdated and will be removed" -ForegroundColor Red
            Remove-ItemProperty -Path $entry.Value.Path -Name $entry.Key -ErrorAction SilentlyContinue
        }
    }
}

WHaL ""
WHaL "Vulkan check complete."
WHaL "Press Enter to close..."
[Console]::ReadLine() | Out-Null
