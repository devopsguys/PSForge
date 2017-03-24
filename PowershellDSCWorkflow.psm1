Import-Module Plaster

function New-DSCModule
{
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ModuleName,
    [string[]]$ResourceNames
)

    $PlasterParams = @{
     TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-module";
     DestinationPath = $ModuleName
     project_name = $ModuleName
    }

    Invoke-Plaster @PlasterParams -NoLogo

    foreach ($resource in $ResourceNames)
    {
        $PlasterParams = @{
         TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-resource";
         DestinationPath = "$ModuleName\packages\DSCResources\"
         project_name = $resource
        }

        Invoke-Plaster @PlasterParams -NoLogo
    }

    Invoke-Expression "${ModuleName}/bootstrap.ps1"

}

function New-DSCResource
{
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ResourceName,
    [string]$ModuleName
)

    if(!$ModuleName)
    {
        $ModuleName = (Get-Item -Path ".\" -Verbose).BaseName
    }

    if(-not (Test-Path "packages\${ModuleName}"))
    {
        $exception = New-Object System.Exception ("Directory 'packages\${ModuleName}' not found. Are you in the module root?")
        throw $exception
    }

    $PlasterParams = @{
        TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-resource";
        DestinationPath = "packages\${ModuleName}\DSCResources\${ResourceName}"
        project_name = $ResourceName
    }

    Invoke-Plaster @PlasterParams -NoLogo

}

function Package-DSCModule
{
param
(
    [parameter(Mandatory = $true,Position=1)]
    [string]$version
)

if(-not (Test-Path ".paket\paket.exe"))
{
    $exception = "'.paket\paket.exe' not found. Are you in the module root?"
}

    Invoke-Expression ".paket\paket.exe pack output .\output version $version"

}

Export-ModuleMember -Function * -Alias *
