function Invoke-Paket
{

    Push-Location "$(getProjectRoot)"
    
    BootstrapPaket
    BootstrapDSCModule
    generatePaketFiles

    if(isWindows)
    {
        $paketBin = ".paket\paket.exe"
    }
    else
    {
        $paketBin = "mono .paket\paket.exe"
    }

    Invoke-ExternalCommandRealtime $paketBin $args

    clearPaketFiles

    Pop-Location

}

function BootstrapPaket
{
    Push-Location "$(GetPSForgeModuleRoot)\paket"
    if(-not (Test-Path ".\paket.exe"))
    {
        if(isWindows)
        {
            Invoke-ExternalCommand ".\paket.bootstrapper.exe"
        }
        else
        {
            Invoke-ExternalCommand  "mono" @(".\paket.bootstrapper.exe")
        }
    }
    Pop-Location
}
function clearPaketFiles
{
    Remove-Item -Recurse -Force .paket -ErrorAction SilentlyContinue
    Remove-Item -Force paket.dependencies -ErrorAction SilentlyContinue
    Remove-Item -Force paket.template -ErrorAction SilentlyContinue
}

function GeneratePaketTemplate {
    param (
        [Parameter(Mandatory=$True,Position=1)]
        $moduleName,
        [Parameter(Mandatory=$True,Position=2)]
        $moduleManifest
    )
    
        return `
@"
type file
id ${ModuleName}
version $($moduleManifest.ModuleVersion)
authors $($moduleManifest.Author)
description
    $($moduleManifest.Description)
files
    ${ModuleName}.psd1 ==> .
    DSCResources ==> DSCResources
dependencies
"@ 
    
}

function generatePaketFiles
{
    $ModuleName = GetModuleName
    
    clearPaketFiles

    $moduleManifest = GetModuleManifest
    $dependenciesManifest = GetDependenciesManifest

    New-Item -Path "paket.dependencies" | Out-Null    

    Copy-Item -Recurse "$(GetPSForgeModuleRoot)\paket" ".\.paket" | Out-Null

    if($PSVersionTable.PSVersion.Major -ge 6) {
      $utf8 = [System.Text.Encoding]::UTF8
    } else {
      $utf8 = "utf8"
    }

    ForEach($nugetFeed in $dependenciesManifest.NugetFeeds)
    {
        "source $nugetFeed" | Out-File paket.dependencies -Append -Encoding $utf8 
    }

    ForEach($nugetPackage in $dependenciesManifest.NugetPackages)
    {
        "nuget $nugetPackage" | Out-File paket.dependencies -Append -Encoding $utf8 
    }

    GeneratePaketTemplate $moduleName $moduleManifest | Out-File  paket.template -Append -Encoding $utf8

    ForEach($nugetPackage in $dependenciesManifest.NugetPackages)
    {

        "    $(($nugetPackage -Split " ")[0]) == LOCKEDVERSION" | Out-File paket.template -Append -Encoding $utf8
    }

}