@echo off
setlocal enabledelayedexpansion

:: Check for admin rights
NET SESSION >nul 2>&1
if %errorLevel% == 0 (
    goto :runScript
) else (
    echo Requesting administrative privileges...
    goto :getAdmin
)

:getAdmin
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B

:runScript
echo Running script with admin privileges...

:: Create temporary PowerShell script for ghost removal
echo $setupapi = @' > "%temp%\remove_ghosts.ps1"
echo using System; >> "%temp%\remove_ghosts.ps1"
echo using System.Runtime.InteropServices; >> "%temp%\remove_ghosts.ps1"
echo namespace Win32 { >> "%temp%\remove_ghosts.ps1"
echo     public static class SetupApi { >> "%temp%\remove_ghosts.ps1"
echo         [DllImport("setupapi.dll", CharSet = CharSet.Auto)] >> "%temp%\remove_ghosts.ps1"
echo         public static extern IntPtr SetupDiGetClassDevs(ref Guid ClassGuid, IntPtr Enumerator, IntPtr hwndParent, int Flags); >> "%temp%\remove_ghosts.ps1"
echo         [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)] >> "%temp%\remove_ghosts.ps1"
echo         public static extern bool SetupDiEnumDeviceInfo(IntPtr DeviceInfoSet, uint MemberIndex, ref SP_DEVINFO_DATA DeviceInfoData); >> "%temp%\remove_ghosts.ps1"
echo         [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)] >> "%temp%\remove_ghosts.ps1"
echo         public static extern bool SetupDiGetDeviceRegistryProperty(IntPtr deviceInfoSet, ref SP_DEVINFO_DATA deviceInfoData, uint property, out UInt32 propertyRegDataType, byte[] propertyBuffer, uint propertyBufferSize, out UInt32 requiredSize); >> "%temp%\remove_ghosts.ps1"
echo         [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)] >> "%temp%\remove_ghosts.ps1"
echo         public static extern bool SetupDiRemoveDevice(IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData); >> "%temp%\remove_ghosts.ps1"
echo     } >> "%temp%\remove_ghosts.ps1"
echo     [StructLayout(LayoutKind.Sequential)] >> "%temp%\remove_ghosts.ps1"
echo     public struct SP_DEVINFO_DATA { >> "%temp%\remove_ghosts.ps1"
echo         public uint cbSize; >> "%temp%\remove_ghosts.ps1"
echo         public Guid classGuid; >> "%temp%\remove_ghosts.ps1"
echo         public uint devInst; >> "%temp%\remove_ghosts.ps1"
echo         public IntPtr reserved; >> "%temp%\remove_ghosts.ps1"
echo     } >> "%temp%\remove_ghosts.ps1"
echo     [Flags] >> "%temp%\remove_ghosts.ps1"
echo     public enum DiGetClassFlags : uint { >> "%temp%\remove_ghosts.ps1"
echo         DIGCF_ALLCLASSES = 0x00000004, >> "%temp%\remove_ghosts.ps1"
echo     } >> "%temp%\remove_ghosts.ps1"
echo     public enum SetupDiGetDeviceRegistryPropertyEnum : uint { >> "%temp%\remove_ghosts.ps1"
echo         SPDRP_DEVICEDESC = 0x00000000, >> "%temp%\remove_ghosts.ps1"
echo         SPDRP_HARDWAREID = 0x00000001, >> "%temp%\remove_ghosts.ps1"
echo         SPDRP_FRIENDLYNAME = 0x0000000C, >> "%temp%\remove_ghosts.ps1"
echo         SPDRP_CLASS = 0x00000007, >> "%temp%\remove_ghosts.ps1"
echo         SPDRP_INSTALL_STATE = 0x00000022, >> "%temp%\remove_ghosts.ps1"
echo     } >> "%temp%\remove_ghosts.ps1"
echo } >> "%temp%\remove_ghosts.ps1"
echo '@ >> "%temp%\remove_ghosts.ps1"
echo Add-Type -TypeDefinition $setupapi >> "%temp%\remove_ghosts.ps1"
echo $removeArray = @() >> "%temp%\remove_ghosts.ps1"
echo $array = @() >> "%temp%\remove_ghosts.ps1"
echo $setupClass = [Guid]::Empty >> "%temp%\remove_ghosts.ps1"
echo $devs = [Win32.SetupApi]::SetupDiGetClassDevs([ref]$setupClass, [IntPtr]::Zero, [IntPtr]::Zero, [Win32.DiGetClassFlags]::DIGCF_ALLCLASSES) >> "%temp%\remove_ghosts.ps1"
echo $devInfo = New-Object Win32.SP_DEVINFO_DATA >> "%temp%\remove_ghosts.ps1"
echo $devInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devInfo) >> "%temp%\remove_ghosts.ps1"
echo $devCount = 0 >> "%temp%\remove_ghosts.ps1"
echo while ([Win32.SetupApi]::SetupDiEnumDeviceInfo($devs, $devCount, [ref]$devInfo)) { >> "%temp%\remove_ghosts.ps1"
echo     $props = @{} >> "%temp%\remove_ghosts.ps1"
echo     @('SPDRP_FRIENDLYNAME', 'SPDRP_DEVICEDESC', 'SPDRP_HARDWAREID', 'SPDRP_CLASS', 'SPDRP_INSTALL_STATE') ^| ForEach-Object { >> "%temp%\remove_ghosts.ps1"
echo         $propEnum = [Win32.SetupDiGetDeviceRegistryPropertyEnum]::$_ >> "%temp%\remove_ghosts.ps1"
echo         $propBuffer = New-Object byte[] 1024 >> "%temp%\remove_ghosts.ps1"
echo         $propType = 0 >> "%temp%\remove_ghosts.ps1"
echo         $requiredSize = 0 >> "%temp%\remove_ghosts.ps1"
echo         $result = [Win32.SetupApi]::SetupDiGetDeviceRegistryProperty($devs, [ref]$devInfo, $propEnum, [ref]$propType, $propBuffer, $propBuffer.Length, [ref]$requiredSize) >> "%temp%\remove_ghosts.ps1"
echo         if ($result) { >> "%temp%\remove_ghosts.ps1"
echo             $props[$_] = if ($_ -eq 'SPDRP_INSTALL_STATE') { $requiredSize -ne 0 } else { >> "%temp%\remove_ghosts.ps1"
echo                 if ($requiredSize -gt 0) { >> "%temp%\remove_ghosts.ps1"
echo                     [System.Text.Encoding]::Unicode.GetString($propBuffer, 0, [Math]::Min($requiredSize, $propBuffer.Length)).Trim() >> "%temp%\remove_ghosts.ps1"
echo                 } else { "" } >> "%temp%\remove_ghosts.ps1"
echo             } >> "%temp%\remove_ghosts.ps1"
echo         } else { >> "%temp%\remove_ghosts.ps1"
echo             $props[$_] = "" >> "%temp%\remove_ghosts.ps1"
echo         } >> "%temp%\remove_ghosts.ps1"
echo     } >> "%temp%\remove_ghosts.ps1"
echo     $deviceName = $props['SPDRP_FRIENDLYNAME'] -or $props['SPDRP_DEVICEDESC'] -or $props['SPDRP_HARDWAREID'] -or "Unknown Device" >> "%temp%\remove_ghosts.ps1"
echo     $device = [PSCustomObject]@{ >> "%temp%\remove_ghosts.ps1"
echo         'Device Name' = $deviceName >> "%temp%\remove_ghosts.ps1"
echo         InstallState = $props['SPDRP_INSTALL_STATE'] >> "%temp%\remove_ghosts.ps1"
echo         Class = $props['SPDRP_CLASS'] >> "%temp%\remove_ghosts.ps1"
echo     } >> "%temp%\remove_ghosts.ps1"
echo     $array += $device >> "%temp%\remove_ghosts.ps1"
echo     if (-not $device.InstallState) { >> "%temp%\remove_ghosts.ps1"
echo         $removeArray += $device >> "%temp%\remove_ghosts.ps1"
echo         [Win32.SetupApi]::SetupDiRemoveDevice($devs, [ref]$devInfo) ^| Out-Null >> "%temp%\remove_ghosts.ps1"
echo     } >> "%temp%\remove_ghosts.ps1"
echo     $devCount++ >> "%temp%\remove_ghosts.ps1"
echo } >> "%temp%\remove_ghosts.ps1"
echo Write-Host 'Removed devices:' >> "%temp%\remove_ghosts.ps1"
echo $removeArray ^| Sort-Object 'Device Name' ^| Format-Table >> "%temp%\remove_ghosts.ps1"
echo Write-Host "Total removed devices: $($removeArray.Count)" >> "%temp%\remove_ghosts.ps1"

:: Run PowerShell script for ghost removal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%temp%\remove_ghosts.ps1"

:: Create PowerShell script for clearing event logs
echo $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue ^| Where-Object {$_.RecordCount -gt 0 -and $_.IsEnabled} > "%temp%\clear_logs.ps1"
echo $clearedLogs = 0 >> "%temp%\clear_logs.ps1"
echo $failedLogs = @() >> "%temp%\clear_logs.ps1"

echo function Clear-Log { >> "%temp%\clear_logs.ps1"
echo     param($logName) >> "%temp%\clear_logs.ps1"
echo     $cleared = $false >> "%temp%\clear_logs.ps1"
echo     $errorMessage = "" >> "%temp%\clear_logs.ps1"
echo     try { >> "%temp%\clear_logs.ps1"
echo         if ($logName -eq "Microsoft-Windows-LiveId/Operational") { >> "%temp%\clear_logs.ps1"
echo             Write-Host "Special handling for LiveId log..." >> "%temp%\clear_logs.ps1"
echo             $logPath = "$env:SystemRoot\System32\Winevt\Logs\Microsoft-Windows-LiveId%4Operational.evtx" >> "%temp%\clear_logs.ps1"
echo             Write-Host "Constructed log file path: $logPath" >> "%temp%\clear_logs.ps1"
echo             if (Test-Path $logPath) { >> "%temp%\clear_logs.ps1"
echo                 Write-Host "Log file exists. Attempting to take ownership and grant full control..." >> "%temp%\clear_logs.ps1"
echo                 $acl = Get-Acl $logPath >> "%temp%\clear_logs.ps1"
echo                 $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name >> "%temp%\clear_logs.ps1"
echo                 $fileSystemRights = [System.Security.AccessControl.FileSystemRights]::FullControl >> "%temp%\clear_logs.ps1"
echo                 $type = [System.Security.AccessControl.AccessControlType]::Allow >> "%temp%\clear_logs.ps1"
echo                 $fileSystemAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $fileSystemRights, $type) >> "%temp%\clear_logs.ps1"
echo                 $acl.SetAccessRule($fileSystemAccessRule) >> "%temp%\clear_logs.ps1"
echo                 $acl ^| Set-Acl $logPath >> "%temp%\clear_logs.ps1"
echo                 Write-Host "Permissions updated. Attempting to clear log using wevtutil..." >> "%temp%\clear_logs.ps1"
echo             } else { >> "%temp%\clear_logs.ps1"
echo                 Write-Host "Log file not found at the expected location. Skipping this log." >> "%temp%\clear_logs.ps1"
echo                 return @{ Cleared = $true; ErrorMessage = "Log file not found. Possibly not installed or configured on this system." } >> "%temp%\clear_logs.ps1"
echo             } >> "%temp%\clear_logs.ps1"
echo         } >> "%temp%\clear_logs.ps1"
echo         $result = wevtutil cl $logName 2>&1 >> "%temp%\clear_logs.ps1"
echo         if ($LASTEXITCODE -eq 0) { >> "%temp%\clear_logs.ps1"
echo             $cleared = $true >> "%temp%\clear_logs.ps1"
echo         } else { >> "%temp%\clear_logs.ps1"
echo             $errorMessage = $result >> "%temp%\clear_logs.ps1"
echo         } >> "%temp%\clear_logs.ps1"
echo     } catch { >> "%temp%\clear_logs.ps1"
echo         $errorMessage = $_.Exception.Message >> "%temp%\clear_logs.ps1"
echo     } >> "%temp%\clear_logs.ps1"
echo     return @{ >> "%temp%\clear_logs.ps1"
echo         Cleared = $cleared >> "%temp%\clear_logs.ps1"
echo         ErrorMessage = $errorMessage >> "%temp%\clear_logs.ps1"
echo     } >> "%temp%\clear_logs.ps1"
echo } >> "%temp%\clear_logs.ps1"

echo foreach ($log in $logs) { >> "%temp%\clear_logs.ps1"
echo     $logName = $log.LogName >> "%temp%\clear_logs.ps1"
echo     Write-Host "Attempting to clear log: $logName" >> "%temp%\clear_logs.ps1"
echo     $result = Clear-Log -logName $logName >> "%temp%\clear_logs.ps1"
echo     if ($result.Cleared) { >> "%temp%\clear_logs.ps1"
echo         $clearedLogs++ >> "%temp%\clear_logs.ps1"
echo         Write-Host "Successfully cleared log: $logName" >> "%temp%\clear_logs.ps1"
echo     } else { >> "%temp%\clear_logs.ps1"
echo         $failedLogs += [PSCustomObject]@{ >> "%temp%\clear_logs.ps1"
echo             LogName = $logName >> "%temp%\clear_logs.ps1"
echo             Error = $result.ErrorMessage >> "%temp%\clear_logs.ps1"
echo         } >> "%temp%\clear_logs.ps1"
echo         Write-Host "Failed to clear log: $logName - $($result.ErrorMessage)" >> "%temp%\clear_logs.ps1"
echo     } >> "%temp%\clear_logs.ps1"
echo } >> "%temp%\clear_logs.ps1"

echo Write-Host "Cleared $clearedLogs event logs." >> "%temp%\clear_logs.ps1"
echo if ($failedLogs.Count -gt 0) { >> "%temp%\clear_logs.ps1"
echo     Write-Host "Failed to clear $($failedLogs.Count) logs:" >> "%temp%\clear_logs.ps1"
echo     $failedLogs ^| ForEach-Object { >> "%temp%\clear_logs.ps1"
echo         Write-Host "- $($_.LogName)" >> "%temp%\clear_logs.ps1"
echo         Write-Host "  Error: $($_.Error)" >> "%temp%\clear_logs.ps1"
echo     } >> "%temp%\clear_logs.ps1"
echo } >> "%temp%\clear_logs.ps1"

:: Clear all event logs using PowerShell
echo.
echo Clearing Event Logs... please wait.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%temp%\clear_logs.ps1"

:: Clean up
del "%temp%\remove_ghosts.ps1" >nul 2>&1
del "%temp%\clear_logs.ps1" >nul 2>&1

echo.
echo Ghost devices removed and Event Logs cleared.
echo This window will close in 10 seconds...

:: Wait for 10 seconds and then exit
timeout /t 10 >nul
exit