function New-DSCModule
{
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]    
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ModuleName,
    [string[]]$ResourceNames,
    [string]$Version="1.0.0",
    [string]$Description=""
)

    $config = Get-DSCModuleGlobalConfig

    $Activity = "Bootstrapping Powershell DSC Module"

    $PlasterParams = @{
        TemplatePath = [System.IO.Path]::Combine($PSScriptRoot, "..", "plaster-powershell-dsc-module")
        DestinationPath = $ModuleName
        project_name = $ModuleName
        version = $Version
        full_name = $config.username
        company = $config.company
        project_short_description = "$Description"
    }

    Write-Progress -Activity $Activity -Status "Scaffolding module filestructure" -percentComplete 30
    Invoke-PlasterWrapper $PlasterParams

    Push-Location $ModuleName
    $currentDirectory = (Get-Item -Path ".\" -Verbose).FullName

    foreach ($resource in $ResourceNames)
    {
        New-DSCResource -ResourceName $resource
    }

    BootstrapDSCModule
    Write-Output "Module bootstrapped at $currentDirectory"
    Pop-Location
}