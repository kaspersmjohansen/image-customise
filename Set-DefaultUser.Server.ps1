#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    Set default user profile settings by mounting the default profile registry hive and adding settings.
    Imports a default Start menu layout.
  
    .NOTES
    AUTHOR: Aaron Parker
 
    .LINK
    http://stealthpuppy.com
#>
[CmdletBinding()]
Param (
    [Parameter()]    
    [System.String] $Path = $(Split-Path -Path $script:MyInvocation.MyCommand.Path -Parent)
)

# Load Registry Hives
$RegDefaultUser = "$env:SystemDrive\Users\Default\NTUSER.DAT"
If (Test-Path -Path $RegDefaultUser) {
    try {
        Write-Verbose -Message "Loading $RegDefaultUser"
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\reg.exe"
            ArgumentList = "load HKLM\MountDefaultUser $RegDefaultUser"
            Wait         = $True
            WindowStyle  = "Hidden"
            ErrorAction  = "SilentlyContinue"
        }
        Start-Process @params
    }
    catch {
        Throw "Failed to run $Command"
    }
}

$RegCommands =
'add "HKCU\Software\Microsoft\ServerManager" /v "DoNotOpenServerManagerAtLogon" /d 1 /t REG_DWORD /f',
'add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableBlurBehind" /d 0 /t REG_DWORD /f'

# Process Registry Commands
ForEach ($Command in $RegCommands) {
    If ($Command -like "*HKCU*") {
        $Command = $Command -replace "HKCU", "HKLM\MountDefaultUser"
        try {
            Write-Verbose -Message "reg $Command"
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\reg.exe"
                ArgumentList = $Command
                Wait         = $True
                WindowStyle  = "Hidden"
                ErrorAction  = "SilentlyContinue"
            }
            Start-Process @params
        }
        catch {
            Write-Error -Message "Failed to run $Command"
        }
    }
    Else {
        try {
            Write-Verbose -Message "reg $Command"
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\reg.exe"
                ArgumentList = $Command
                Wait         = $True
                WindowStyle  = "Hidden"
                ErrorAction  = "SilentlyContinue"
            }
            Start-Process @params
        }
        catch {
            Write-Error -Message "Failed to run $Command"
        }
    }
}

# Unload Registry Hives
try {
    Write-Verbose -Message "reg unload"
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\reg.exe"
        ArgumentList = "unload HKLM\MountDefaultUser"
        Wait         = $True
        WindowStyle  = "Hidden"
        ErrorAction  = "SilentlyContinue"
    }
    Start-Process @params
}
catch {
    Throw "Failed to run: reg unload"
}

# Configure the default Start menu
$MinBuild = "14393"
$CurrentBuild = ([System.Environment]::OSVersion.Version).Build
If (!(Test-Path("$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows"))) {
    New-Item -Value "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows" -ItemType "Directory" > $Null
}

If ($CurrentBuild -ge $MinBuild) {
    try {
        If ((Get-WindowsFeature -Name "RDS-RD-Server").InstallState -eq "Installed") {
            $Layout = Resolve-Path -Path $(Join-Path -Path $Path -ChildPath "WindowsRDSStartMenuLayout.xml")
        }
        Else {
            $Layout = Resolve-Path -Path $(Join-Path -Path $Path -ChildPath "WindowsServerStartMenuLayout.xml")
        }
        Write-Verbose -Message "Importing Start layout file: $Layout."
        Import-StartLayout -LayoutPath $Layout -MountPath "$($env:SystemDrive)\"
    }
    catch {
        Throw "Failed to import Start menu layout: [$Layout]."
    }
}
