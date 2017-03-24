function New-DSCModule
{
param(
    [Parameter(Mandatory=$True)]
    [string]$ModuleName,
    [string[]]$ResourceNames
)

    $PlasterParams = @{
     TemplatePath = "$PSScriptRoot/paket-files/devopsguys/plaster-powershell-dsc-scaffolding/plaster-powershell-dsc-module";
     DestinationPath = $ModuleName
     project_name = $ModuleName
    }

    Invoke-Plaster @PlasterParams

    $PlasterParams = @{
     TemplatePath = "$PSScriptRoot/paket-files/devopsguys/plaster-powershell-dsc-scaffolding/plaster-powershell-dsc-resource";
     DestinationPath = "$ModuleName/packages/DSCResources/"
     project_name = $resource
    }

    foreach ($resource in $ResourceNames)
    {
        Invoke-Expression ".\$ModuleName\NewResource.ps1 -ResourceName $resource"
    }

}
