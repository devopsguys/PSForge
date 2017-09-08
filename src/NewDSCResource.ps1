function New-DSCResource
{
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ResourceName
)

    Push-Location "$(getProjectRoot)"

    Write-Output "Scaffolding new DSC resource: $resource"

    $ModuleName = GetModuleName

    BootstrapDSCModule
    $metadata = GetModuleManifest

    $PlasterParams = @{
        TemplatePath = [System.IO.Path]::Combine($(GetPSForgeModuleRoot), "plaster-powershell-dsc-resource")
        DestinationPath = "DSCResources\${ResourceName}";
        project_name = $ResourceName;
        company =  $metadata.CompanyName;
        project_short_description = $ModuleName;
        full_name = $metadata.Author;
        version = "1.0.0";
    }

    Invoke-PlasterWrapper $PlasterParams
    Write-Output "New resource has been created at $(Get-Item DSCResources\$ResourceName)"

    Pop-Location
}