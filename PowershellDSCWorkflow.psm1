Import-Module Plaster

function New-DSCModule
{
param(
    [Parameter(Mandatory=$True)]
    [string]$ModuleName,
    [string[]]$ResourceNames
)

    $PlasterParams = @{
     TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-module";
     DestinationPath = $ModuleName
     project_name = $ModuleName
    }

    Invoke-Plaster @PlasterParams

    $PlasterParams = @{
     TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-resource";
     DestinationPath = "$ModuleName\packages\DSCResources\"
     project_name = $resource
    }

    foreach ($resource in $ResourceNames)
    {
        Invoke-Expression ".\$ModuleName\NewResource.ps1 -ResourceName $resource"
    }

}

function New-DSCResource
{
param(
    [Parameter(Mandatory=$True)]
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

    Invoke-Plaster @PlasterParams

}

Export-ModuleMember -Function * -Alias *
