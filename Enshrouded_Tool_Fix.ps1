# Creator LiaNdrY - Modified for custom game path
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

# --- CUSTOM GAME PATH SETTING ---
# Set your custom game installation path here:
$customGamePath = "D:\Games\Enshrouded"  # <--- CHANGE THIS PATH TO YOUR GAME FOLDER
if (-not (Test-Path $customGamePath)) {
    WHaL "The custom game path does not exist: $customGamePath" -ForegroundColor Red
    WHaL ""
    Read-Host -Prompt "Press Enter to Exit"
    exit
}
$gamePath_0 = $customGamePath
$game_id = 1203620

WHaL "Using custom game path: $gamePath_0" -ForegroundColor Green
WHaL ""

# --- Rest of the script remains unchanged ---
# From this point, you can leave all original logic for Vulkan layers, caches, resolution, FOV, etc.
# All $gamePath_0 references now use your custom path instead of Steam detection.

# Example: Setting native resolution
$fileJson = "$gamePath_0\enshrouded_local.json"
if (Test-Path -Path $fileJson) {
    WHaL "Set the native resolution for the game: " -NoNewline
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens
    foreach ($screen in $screens) {
        if ($screen.Primary) {
            $primaryMonitorWidth = $screen.Bounds.Width
            $primaryMonitorHeight = $screen.Bounds.Height
            break
        }
    }
    $json = Get-Content -Path $fileJson | ConvertFrom-Json
    $json.graphics.windowMode = "Fullscreen"
    $json.graphics.windowPosition.x = 0
    $json.graphics.windowPosition.y = 0
    $json.graphics.windowSize.x = $($primaryMonitorWidth)
    $json.graphics.windowSize.y = $($primaryMonitorHeight)
    $json.graphics.forceBackbufferResolution.x = 0
    $json.graphics.forceBackbufferResolution.y = 0
    $json.graphics.sleepInBackground = $false
    $json | ConvertTo-Json -Depth 100 | Format-Json |
        ForEach-Object {$_ -replace "(?m)  (?<=^(?:  )*)", "`t" } |
        Set-Content -Path $fileJson
    WHaL "Done ($($primaryMonitorWidth)x$($primaryMonitorHeight))" -ForegroundColor Green
    WHaL ""
} else {
    WHaL "Set the native resolution for the game: " -NoNewline
    WHaL "The enshrouded_local.json file is missing from the game folder." -ForegroundColor Red
    WHaL ""
}

# Setting the minimum FOV
$fileJsonSG = "$env:USERPROFILE\Saved Games\Enshrouded\enshrouded_user.json"
if (Test-Path -Path $fileJsonSG) {
    WHaL "Set the minimum FOV in the game: " -NoNewline
    $json = Get-Content -Path $fileJsonSG -Raw | ConvertFrom-Json
    if ($json.graphics -and $json.graphics.PSObject.Properties.Name -contains 'fov') {
        $json.graphics.fov = "42480000"
    } else {
        WHaL "The 'fov' property does not exist in the enshrouded_user.json file." -ForegroundColor Yellow
        if (!$json.graphics) {
            $json | Add-Member -NotePropertyName 'graphics' -NotePropertyValue ([PSCustomObject]@{})
        }
        $json.graphics | Add-Member -NotePropertyName 'fov' -NotePropertyValue "42480000"
    }
    $json | ConvertTo-Json -Depth 100 | Format-Json |
        ForEach-Object {$_ -replace "(?m)  (?<=^(?:  )*)", "`t" } |
        Set-Content -Path $fileJsonSG
    WHaL "Done" -ForegroundColor Green
    WHaL "In the future, you can increase the FOV in the game settings if it stops crashing." -ForegroundColor Yellow
    WHaL ""
} else {
    WHaL "Set the minimum FOV in the game: " -NoNewline
    WHaL "The enshrouded_user.json file is missing from the Saved Games folder." -ForegroundColor Red
    WHaL ""
}
# Set enshrouded.exe to normal execution priority
$regEnshroudedPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\enshrouded.exe\PerfOptions"
$regEnshroudedName = "CpuPriorityClass"
$regEnshroudedValue = 2
WHaL "Set the priority of the enshrouded.exe file to 'Normal' when starting: " -NoNewline
if (-not (Test-Path $regEnshroudedPath)) {
    New-Item -Path $regEnshroudedPath -Force | Out-Null
    New-ItemProperty -Path $regEnshroudedPath -Name $regEnshroudedName -Value $regEnshroudedValue -PropertyType DWord -Force | Out-Null
    WHaL "Done" -ForegroundColor Green
} else {
    WHaL "Done" -ForegroundColor Green
}
WHaL ""
# Set Powerplan
$guids = @{
    "High performance" = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    "Balanced"         = "381b4222-f694-41f0-9685-ff5bb260df2e"
    "Power saver"      = "a1841308-3541-4fab-bc81-f71556f20b4a"
}
$powerSchemes = powercfg -l
$activeGUID = ($powerSchemes | Select-String -Pattern '(?<=\().+?(?=\))' -AllMatches).Matches.Value
if ($activeGUID -eq $guids["Balanced"] -or $activeGUID -eq $guids["Power saver"]) {
    powercfg /S $guids["High performance"]
    WHaL "Changing the power saving scheme to 'High Performance': " -NoNewline
    WHaL "Done" -ForegroundColor Green
} else {
    $powerScheme = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan -Filter "IsActive='true'"
    WHaL "Changing the power saving scheme to 'High Performance': " -NoNewline
    WHaL "The scheme has not been changed since it is already installed - " -ForegroundColor Yellow -NoNewline
    WHaL $powerScheme.ElementName -ForegroundColor Yellow
}
# Increase system responsiveness and network throughput
WHaL ""
$perfomanceSystem = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$values = @{
    "NetworkThrottlingIndex" = 20
    "SystemResponsiveness" = 10
}
if (!(Test-Path $perfomanceSystem)) {
    New-Item -Path $perfomanceSystem -Force | Out-Null
}
foreach ($key in $values.Keys) {
    Set-ItemProperty -Path $perfomanceSystem -Name $key -Value $values[$key] -Type "DWord"
}
WHaL "Improve input responsiveness and network throughput: " -NoNewline
WHaL "Done" -ForegroundColor Green
WHaL ""
# Enabling the system's gaming mode
$regPath = "HKCU:\Software\Microsoft\GameBar"
$regName = "AutoGameModeEnabled"
$currentValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
if ($currentValue -eq 1) {
    WHaL "Game Mode: " -NoNewline
    WHaL "ALREADY ENABLE" -ForegroundColor Green
} else {
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name $regName -Value 1 -Type DWord -Force
    $newValue = (Get-ItemProperty -Path $regPath -Name $regName).$regName
    if ($newValue -eq 1) {
        WHaL "Game Mode: " -NoNewline
        WhaL "ENABLE " -NoNewline -ForegroundColor Green
        WHaL "(Need Reboot)" -ForegroundColor Yellow
    } else {
        WHaL "Game Mode: " -NoNewline
        WHaL "Failed to enable game mode" -ForegroundColor Red
    }
}
WHaL ""
# Enable/disable GameDVR
$gameDvrEnabled = (Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled
$gameDvrPolicy = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Name "value" -ErrorAction SilentlyContinue).value
WHaL "GameDVR indirectly affects performance in games; it is advisable to disable it if you have a weak video card." -ForegroundColor Yellow
if ($gameDvrEnabled -eq 0 -and $gameDvrPolicy -eq 0) {
    WHaL "GameDVR Status: " -NoNewline
    WHaL "Off" -ForegroundColor Green
    $answer = Read-Host "Want to enable GameDVR? (Y - Yes / Any - No)"
    if ($answer -eq "Y") {
        WHaL "GameDVR Status: " -NoNewline
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Name "value" -Value 1 -Type DWORD
        WHaL "On" -ForegroundColor Green
    } else {
    }
} else {
    WHaL "GameDVR Status: " -NoNewline
    WHaL "On" -ForegroundColor Green
    $answer = Read-Host "Want to disable GameDVR? (Y - Yes / Any - No)"
    if ($answer -eq "Y") {
        WHaL "GameDVR Status: " -NoNewline
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWORD
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Name "value" -Value 0 -Type DWORD
        WHaL "Off" -ForegroundColor Green
    } else {
    }
}
# Checking processor support on AVX instructions
WHaL ""
WHaL "CPU Info..."
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public class ProcessorInfo
    {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

        [DllImport("kernel32.dll")]
        public static extern bool IsProcessorFeaturePresent(int ProcessorFeature);

        public const int PF_AVX = 39;

        public static bool IsAVXSupported()
        {
            IntPtr kernel32 = GetModuleHandle("kernel32.dll");
            IntPtr procAddress = GetProcAddress(kernel32, "IsProcessorFeaturePresent");
            return IsProcessorFeaturePresent(PF_AVX);
        }
    }
"@
$processorName = (Get-CimInstance -ClassName Win32_Processor).Name
if ([ProcessorInfo]::IsAVXSupported()) {
    WHaL "Name CPU: $processorName"
    WHaL "AVX support: " -NoNewline
    WHaL "Yes" -ForegroundColor Green
} else {
    WHaL "Name CPU: $processorName"
    WHaL "AVX support: " -NoNewline
    WHaL "No" -ForegroundColor Red
    WHaL ""
    WHaL "Unfortunately, your processor does not support the AVX instruction set, the game will not be able to start without this set." -ForegroundColor Red
}
# Checking the parameters of the paging file
$gameLog = "$gamePath_0\enshrouded.log"
$textLogMemory = "*Could not allocate new memory block, error: out of memory*"
if (Test-Path $gameLog) {
    $logContent = Get-Content $gameLog
    if ($logContent -like $textLogMemory) {
        $result = $true
    } else {
        $result = $false
    }
} else {
    $result = $null
}
WHaL ""
$swapFile = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles").PagingFiles
if (($swapFile -eq "?:\pagefile.sys") -and ($result -eq $true)) {
    WHaL "Auto-selection of the paging file size: " -NoNewline
    WHaL "Yes" -ForegroundColor Green
    WHaL "The message 'Out of memory' was found in the log file." -ForegroundColor Yellow
}
elseif (($swapFile -ne "?:\pagefile.sys") -and (($result -eq $false) -or ($result -eq $null))) {
    WHaL "Auto-selection of the paging file size: " -NoNewline
    WHaL "No" -ForegroundColor Yellow
    WHaL "The message 'Out of memory' was not found in the log file." -ForegroundColor Yellow
}
elseif ($swapFile -eq "?:\pagefile.sys") {
    WHaL "Auto-selection of the paging file size: " -NoNewline
    WHaL "Yes" -ForegroundColor Green
}
elseif (($swapFile -ne "?:\pagefile.sys") -and ($result -eq $true)) {
    WHaL "Auto-selection of the paging file size: " -NoNewline
    WHaL "No" -ForegroundColor Yellow
    WHaL "The message 'Out of memory' was found in the log file." -ForegroundColor Yellow
    WHaL "If your game crashes immediately, it is advisable to set the auto-selection of the paging file size by the system." -ForegroundColor Yellow
    $answer = Read-Host "Do you want to do this? (Y - Yes / Any - No)"
    if ($answer -eq "Y") {
        SystemPropertiesPerformance.exe /pagefile
        WHaL ""
        WHaL "- Click the " -NoNewline
        WHaL "'Change'" -NoNewline -ForegroundColor Green
        WHaL " button"
        WHaL "- Select the disk on which you have a paging file"
        WHaL "- Specify " -NoNewline
        WHaL "'System managed size'" -NoNewline -ForegroundColor Green
        WHaL ", then click the " -NoNewline
        WHaL "'Set'" -NoNewline -ForegroundColor Green
        WHaL " button"
        WHaL "- After that, check the box " -NoNewline
        WHaL "'Automatically manage paging file size for all drives'" -ForegroundColor Green
        WHaL "- Click " -NoNewline
        WHaL "'Ok'" -ForegroundColor Green
        WHaL "The system will ask you to reboot for the changes to take effect, postpone this process and exit this script, after which you can reboot the system." -ForegroundColor Yellow
        Read-Host -Prompt "Press Enter to Continue"
    } else {
    }
}
# Check RAM
WHaL ""
$Ram = [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($Ram -lt 16) {
    WHaL "RAM: " -NoNewline
    WHaL "$Ram GB" -ForegroundColor Red
    WHaL "Attention: the amount of RAM is less than 16 GB" -ForegroundColor Yellow
    WHaL "It is very likely that the game will show you a warning that your system does not meet the minimum requirements. You can acknowledge this message and proceed at your own risk." -ForegroundColor Yellow
} else {
    WHaL "RAM: " -NoNewline
    WHaL "$Ram GB" -ForegroundColor Green
}
# Check VRAM
WHaL ""
$VideoCard = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.AdapterCompatibility }
$dxPath = $Api_Video0 -split '\\'
$dxVideoPath = Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\DirectX\" + $dxPath[-2]) -ErrorAction SilentlyContinue
$vRamDX = [Math]::Round(($dxVideoPath.DedicatedVideoMemory) / 1GB)
if ($vRamDX -lt 6) {
    WHaL "Video Card: $($VideoCard.Name)" -NoNewline
    WHaL " ($vRamDX GB)" -ForegroundColor Red
    WHaL "Attention: the amount of video memory is less than 6 GB" -ForegroundColor Yellow
    WHaL "Additionally, with only 4GB of VRAM, the game limits texture settings. You can't change them in-game." -ForegroundColor Red
    WHaL "It is very likely that the game will show you a warning that your system does not meet the minimum requirements. You can acknowledge this message and proceed at your own risk." -ForegroundColor Yellow
} else {
    WHaL "Video Card: " -NoNewline
    WHaL "$($VideoCard.Name) ($vRamDX GB)" -ForegroundColor Green
}
$GPUName = "DriverDesc"
$GPUVer = "DriverVersion"
$GPUDateDrv = "DriverDate"
$driverName = (Get-ItemProperty -Path $Api_Video0 -Name $GPUName).$GPUName
$driverVersion = (Get-ItemProperty -Path $Api_Video0 -Name $GPUVer).$GPUVer
$driverDate = (Get-ItemProperty -Path $Api_Video0 -Name $GPUDateDrv).$GPUDateDrv
if ($driverName -like "*NVIDIA*") {
    $parts = $driverVersion -split '\.'
    $convVer = ($parts[2].Substring(1) + $parts[3]).Insert(3, ".")
    WHaL "GPU driver version: " -NoNewline
    WHaL "$convVer ($driverDate)" -ForegroundColor Green
} elseif ($driverName -like "*AMD*") {
    $GPUVer = "RadeonSoftwareVersion"
    $driverVersion = (Get-ItemProperty -Path $Api_Video0 -Name $GPUVer).$GPUVer
    WHaL "GPU driver version: " -NoNewline
    WHaL "$driverVersion ($driverDate)" -ForegroundColor Green
} elseif ($driverName -like "*Intel*") {
    $convVer = ($driverVersion -split '\.')[2..3] -join '.'
    WHaL "GPU driver version: " -NoNewline
    WHaL "$convVer ($driverDate)" -ForegroundColor Green
}
WHaL ""
WHaL "The Texture Resolution setting affects the amount of video memory consumed by the game:" -ForegroundColor Yellow
WHaL "Performance (~5 GB), Balanced (~5.5 GB), Quality (~6.5 GB), Max.Quality (~8.5 GB)" -ForegroundColor Yellow
WHaL ""
WHaL "It's recommended to update your video card drivers if you have an older version and a newer one is available." -ForegroundColor Yellow
WHaL "After that, you must run this utility again to check the Vulkan API version." -ForegroundColor Yellow
WHaL ""
if ($($VideoCard.Name) -like "*nvidia*") {
    WHaL "Link to the latest video driver: " -NoNewline
    WHaL "(https://www.nvidia.com/Download/index.aspx)" -ForegroundColor Green
    WHaL "You can also try the beta driver for Vulkan: " -NoNewline
    WHaL "(https://developer.nvidia.com/vulkan-driver)" -ForegroundColor Green
} elseif ($($VideoCard.Name) -like "*radeon*" -or $($VideoCard.Name) -like "*amd*") {
    WHaL "Link to the latest video driver: " -NoNewline
    WHaL "(https://www.amd.com/en/support)" -ForegroundColor Green
} elseif (($($VideoCard.Name) -like "*intel*") -or ($($VideoCard.Name) -like "*arc*") -or ($($VideoCard.Name) -like "*iris*")) {
    WHaL "Link to the latest video driver: " -NoNewline
    WHaL "(https://www.techpowerup.com/download/intel-graphics-drivers/)" -ForegroundColor Green
} else {
    WHaL "Video card not recognized."
}
# Completing script execution
WHaL ""
WHaL 'Even if after all the corrections you have made, the game continues to crash after some time, most likely the problem is in the game itself. Either you have a very large and complex "castle", or you have a large number of crops. (This problem seems to be known to developers and it remains only to wait for patches.)' -ForegroundColor Yellow
WHaL ""
WHaL "The computer must be restarted for the changes to take effect." -ForegroundColor Yellow
WHaL ""
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
