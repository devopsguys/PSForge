if((get-module | Where-Object { $_.Name -eq "Plaster" }).Count -eq 0)
{
    Import-Module Plaster
}

function addToPath
{
param(
    [string]$path
)

    if(-not ($env:PATH -split ";") -contains $path)
    {
        $env:PATH = $path,$env:PATH -join ";"
    }

}

function getEnvironmentOSVersion
{
    return [Environment]::OSVersion
}

function getOSPlatform
{

    $osPlatform = (getEnvironmentOSVersion).Platform

    if($osPlatform -like "Win*")
    {
        return "windows"
    }

    if($osPlatform -eq "Unix")
    {
        $uname = Invoke-Expression "uname"
        if($uname -eq "Darwin")
        {
            return "mac"
        }

        return ($uname).toLower()
    }

    return "unknown"

}

function isWindows
{
    return ((getOSPlatform) -eq "windows")
}

function isUnix
{
    return (@("linux","mac","freebsd","sunos","openbsd")).contains((getOSPlatform))
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


function checkDependencies
{
    if(isUnix)
    {
        if(-not (isOnPath "mono"))
        {
            throw New-Object System.Exception ("PSForge has a dependency on 'mono' on Linux and MacOS - please install mono via the system package manager.")
        }
    }

    if(-not (isOnPath "ruby"))
    {
        throw New-Object System.Exception ("PSForge has a dependency on 'ruby' 2.3 or higher - please install ruby via the system package manager.")
    }

    if(-not (isOnPath "git"))
    {
        throw New-Object System.Exception ("PSForge has a dependency on 'git' - please install git via the system package manager.")
    }

    [string]$longRubyVersion = (Invoke-Expression "ruby --version").split(' ')[1]
    [double]$shortRubyVersion = ($longRubyVersion.split('.')[0,1]) -join '.'

    if($shortRubyVersion -lt 2.3)
    {
        throw New-Object System.Exception ("PSForge has a dependency on 'ruby' 2.3 or higher. Current version of ruby is ${longRubyVersion} - please update ruby via the system package manager.")
    }

}

function installRuby
{	
    $Activity = "Installing Ruby"
    $rubyURL = "https://dl.bintray.com/oneclick/rubyinstaller/ruby-2.3.3-i386-mingw32.7z"
    $rubyInstaller = "$PSScriptRoot\ruby.7z"
    Write-Progress -Activity $Activity -Status "Downloading Ruby archive" -percentComplete 20
    Invoke-WebRequest -Uri $rubyURL -OutFile $rubyInstaller 
    Write-Progress -Activity $Activity -Status "Extracting Ruby archive" -percentComplete 60
    & $PSScriptRoot\7zip\7za.exe x $rubyInstaller -o"${PSScriptRoot}" | Out-Null
    Write-Progress -Activity $Activity -percentComplete 100 -Completed
    Remove-Item $rubyInstaller
}

function isProjectRoot
{
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$path
)
    return Test-Path "${path}\.git"
}

function getProjectRoot
{

    $projectRoot = Invoke-Expression "git rev-parse --show-toplevel"

    if(-Not (Test-Path $projectRoot))
    {
        throw New-Object System.Exception ("No .git directory found in ${PWD} or any of its parent directories.")
    }

    return $projectRoot

}

function updateBundle{

    if(-not (isOnPath "bundler"))
    {
        Invoke-Expression "gem install bundler" | Out-Null
    }

    $bundle = Start-Process -FilePath "bundle" -ArgumentList "check" -Wait -NoNewWindow -RedirectStandardOutput stdout -PassThru
    Remove-Item stdout
    if($bundle.Exitcode -ne 0)
    {
        Invoke-Expression "bundle install --path .bundle"
    }
}

function Invoke-Paket
{

    Push-Location "$(getProjectRoot)"
    
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

    $commandArgs = $args -join " "

    Invoke-Expression "$paketBin $commandArgs".TrimEnd()

    clearPaketFiles

    Pop-Location

}

function New-DSCModule
{
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ModuleName,
    [string[]]$ResourceNames,
    [string]$Version="1.0.0",
    [string]$Description=""
)

    CheckUserConfig

    $config = Get-DSCModuleGlobalConfig

    $Activity = "Bootstrapping Powershell DSC Module"

    $PlasterParams = @{
     TemplatePath = "$PSScriptRoot\plaster-powershell-dsc-module";
     DestinationPath = $ModuleName
     project_name = $ModuleName
     version = $Version
     full_name = $config.username
     company = $config.company
     project_short_description = $Description
    }

    Write-Progress -Activity $Activity -Status "Scaffolding module filestructure" -percentComplete 30
    Invoke-Plaster @PlasterParams -NoLogo *> $null

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

function New-DSCResource
{
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ResourceName
)

    Push-Location "$(getProjectRoot)"

    CheckUserConfig

    Write-Output "Scaffolding new DSC resource: $resource"

    $ModuleName = (Get-Item -Path ".\" -Verbose).BaseName

    if(-not (Test-Path "${ModuleName}.psd1"))
    {
        throw New-Object System.Exception ("'${ModuleName}.psd1' not found. Are you in the module root?")
    }

    BootstrapDSCModule

    $PlasterParams = @{
        TemplatePath = "$PSScriptRoot\plaster-powershell-dsc-resource";
        DestinationPath = "DSCResources\${ResourceName}"
        project_name = $ResourceName
    }

    Import-LocalizedData -BaseDirectory "." -FileName "${ModuleName}.psd1" -BindingVariable metadata

    $PlasterParams.company = $metadata.CompanyName
    $PlasterParams.project_short_description = $ModuleName
    $PlasterParams.full_name = $metadata.Author
    $PlasterParams.version = "1.0.0"

    Invoke-Plaster @PlasterParams -NoLogo *> $null
    Write-Output "New resource has been created at $(Get-Item DSCResources\$ResourceName)"

    Pop-Location
}

function Export-DSCModule
{
param
(
    [parameter(Mandatory = $true,Position=1)]
    [string]$Version
)
    Push-Location "$(getProjectRoot)"

    BootstrapDSCModule
    Invoke-Paket update
    Invoke-Paket pack output .\output version $version

    Pop-Location
}

function Test-DSCModule
{
param (
    [ValidateSet('create', 'converge', 'verify', 'test','destroy','login')]
    [string] $Action = 'verify',
    [switch] $Debug
)

    Push-Location "$(getProjectRoot)"

    Write-Output "Action: $Action"

    BootstrapDSCModule

    $azureRMCredentials = "$HOME/.azure/credentials"

    if( -not (Test-Path $azureRMCredentials))
    {
        throw New-Object System.Exception ("Create an azure credentials file at $HOME/.azure/.credentials as described here: https://github.com/test-kitchen/kitchen-azurerm")
    }

    if (-not (Test-Path env:AZURERM_SUBSCRIPTION)) {
        Write-Output "The environment variable AZURERM_SUBSCRIPTION has not been set."
        Write-Output ""
        Write-Output "Setting the value of AZURERM_SUBSCRIPTION"

        $firstLine,$remainingLines = Get-Content $azureRMCredentials

        $defaultValue = $firstLine -replace '[[\]]',''
        $prompt = Read-Host "Input your Azure Subscription ID [$($defaultValue)]"
        $prompt = ($defaultValue,$prompt)[[bool]$prompt]

        $env:AZURERM_SUBSCRIPTION = $prompt
    }

    $KitchenParams = $Action

    if($Debug)
    {
        $KitchenParams += " --log-level Debug"
    }

    updateBundle

    Invoke-Paket update
    Invoke-Expression "bundle exec kitchen ${KitchenParams}"

    Pop-Location

}

function Get-DSCModuleGlobalConfig
{
    $configFile = "$HOME/DSCWorkflowConfig.json"

    if(-Not (Test-Path $configFile))
    {
        return @{}
    }

    return Get-Content -Raw -Path $configFile | ConvertFrom-Json

}

function Set-DSCModuleGlobalConfig
{
    param (
        [parameter(Mandatory = $true,Position=1)]
        [string] $Key,
        [parameter(Mandatory = $true,Position=2)]
        [string] $Value
    )

    $configFile = "$HOME/DSCWorkflowConfig.json"
    $json = Get-DSCModuleGlobalConfig
    $Key = $Key.ToLower()
    $json | Add-Member NoteProperty $Key $Value -Force
    $json | ConvertTo-Json -depth 100 | Out-File $configFile -encoding utf8

}

function CheckUserConfig
{
    $config = Get-DSCModuleGlobalConfig

    if(!$config.username)
    {
        $defaultValue = $ENV:USERNAME
        $username = Read-Host "What is your username? [$($defaultValue)]"
        $username = ($defaultValue,$username)[[bool]$username]
        Set-DSCModuleGlobalConfig "username" "$username"
    }

    if(!$config.company)
    {
        $defaultValue = "None"
        $company = Read-Host "What is your company name? [$($defaultValue)]"
        $company = ($defaultValue,$company)[[bool]$company]
        Set-DSCModuleGlobalConfig "company" "$company"
    }
}

function BootstrapDSCModule
{

    $Activity = "Bootstrapping Powershell DSC Module"

    if(isWindows)
    {
        $RubyPath = "$PSScriptRoot\ruby-2.3.3-i386-mingw32\bin\"
        addToPath $RubyPath
        if(-not (Test-Path "$RubyPath\ruby.exe"))
        {
            installRuby
            . $PSScriptRoot\helper_scripts\fixRubyCertStore.ps1
        }
    }

    checkDependencies

    if(!(Test-Path ".\.git"))
    {
        Write-Progress -Activity $Activity -Status "Initialising local Git repository" -percentComplete 60
        Invoke-Expression "git init" | Out-Null
    }

    Write-Progress -Activity $Activity -percentComplete 100 -Completed

}

function clearPaketFiles
{
    Remove-Item -Recurse -Force .paket -ErrorAction SilentlyContinue
    Remove-Item -Force paket.dependencies -ErrorAction SilentlyContinue
    Remove-Item -Force paket.template -ErrorAction SilentlyContinue
}

function generatePaketFiles
{
    $ModuleName = (Get-Item -Path ".\" -Verbose).BaseName
    Import-LocalizedData -BaseDirectory "." -FileName "${ModuleName}.psd1" -BindingVariable moduleManifest
    Import-LocalizedData -BaseDirectory "." -FileName "dependencies.psd1" -BindingVariable dependenciesManifest

    Push-Location "$PSScriptRoot\paket"
    if(-not (Test-Path ".\paket.exe"))
    {
        if(isWindows)
        {
            Invoke-Expression ".\paket.bootstrapper.exe"
        }
        else
        {
            Invoke-Expression "mono .\paket.bootstrapper.exe"
        }
    }
    Pop-Location

    clearPaketFiles

    Copy-Item -Recurse $PSScriptRoot\paket .\.paket | Out-Null

    New-Item paket.dependencies | Out-Null
    New-Item paket.template | Out-Null

    ForEach($nugetFeed in $dependenciesManifest.NugetFeeds)
    {
        "source $nugetFeed" | Out-File paket.dependencies -Append -Encoding utf8
    }

    ForEach($nugetPackage in $dependenciesManifest.NugetPackages)
    {
        "nuget $nugetPackage" | Out-File paket.dependencies -Append -Encoding utf8
    }

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
"@ | Out-File  paket.template -Append -Encoding utf8

    ForEach($nugetPackage in $dependenciesManifest.NugetPackages)
    {

        "    $(($nugetPackage -Split " ")[0]) == LOCKEDVERSION" | Out-File paket.template -Append -Encoding utf8
    }

}

Export-ModuleMember -function *-*
