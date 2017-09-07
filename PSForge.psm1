Import-Module Plaster

function addToPath
{
param(
    [string]$path
)
    $delimiter = ";"

    if(isUnix)
    {
        $delimiter = ":"
    }

    if(-not (($env:PATH -split $delimiter) -contains $path))
    {
        $env:PATH = $path,$env:PATH -join $delimiter
    }

}

function Invoke-ExternalCommand {
Param(
    [Parameter(Mandatory=$True,Position=1)]
    $command,
    [Parameter(Mandatory=$False,Position=2)]
    $arguments
)
    
    # Reset $result in case it's used somewhere else
    $result = $null

    # Reset $LASTEXITCODE in case it was tripped somewhere
    $Global:LASTEXITCODE = 0

    $result = & $command $arguments  

    if ($LASTEXITCODE -ne 0) {
        Throw "Something bad happened while executing $command. Details: $($result | Out-String)"
    }

    return $result
}

function getOSPlatform{
    return [Environment]::OSVersion.Platform
}

function isWindows
{
    return (getOSPlatform) -like "Win*"
}

function isUnix
{
    return (getOSPlatform) -eq "Unix"
}

function isOnPath
{
    param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$cmd
    )

    $bin = Get-Command -ErrorAction "SilentlyContinue" $cmd
    return ($bin -ne $null)
}

function getProjectRoot
{

    $projectRoot = Invoke-ExternalCommand "git" @("rev-parse", "--show-toplevel")

    if(-Not (Test-Path $projectRoot))
    {
        throw New-Object System.Exception ("No .git directory found in ${PWD} or any of its parent directories.")
    }

    return $projectRoot

}

function GetModuleName{
    return (Get-Item -Path ".\" -Verbose).BaseName
}

function GetModuleManifest
{
    $ModuleName = GetModuleName
    Import-LocalizedData -BaseDirectory "." -FileName "${ModuleName}.psd1" -BindingVariable moduleManifest
    return $moduleManifest
}
function GetDependenciesManifest
{
    Import-LocalizedData -BaseDirectory "." -FileName "dependencies.psd1" -BindingVariable dependenciesManifest
    return $dependenciesManifest
}

# Private helper functions
. $PSScriptRoot\src\Dependencies.ps1
. $PSScriptRoot\src\PlasterHelpers.ps1

# Public functions
. $PSScriptRoot\src\NewDSCModule.ps1
. $PSScriptRoot\src\NewDSCResource.ps1
. $PSScriptRoot\src\TestDSCModule.ps1
. $PSScriptRoot\src\ExportDSCModule.ps1
. $PSScriptRoot\src\GetDSCModuleGlobalConfig.ps1
. $PSScriptRoot\src\SetDSCModuleGlobalConfig.ps1
. $PSScriptRoot\src\InvokePaket.ps1

Export-ModuleMember -function *-*
