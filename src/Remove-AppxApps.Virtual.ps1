<#
    .SYNOPSIS
        Call Remove-AppxApps.ps1 for virtualised client Windows operating systems.
  
    .NOTES
        AUTHOR: Aaron Parker
        TWITTER: @stealthpuppy
#>
[CmdletBinding()]
param (
    [Parameter()]
    [System.String] $Path = $PSScriptRoot
)

# Run Remove-AppxApps.ps1 in block list mode
Write-Verbose -Message "Path: $Path."
& (Join-Path -Path $Path -ChildPath "Remove-AppxApps.ps1") -Operation "AllowList"
