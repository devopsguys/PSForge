if((get-module | ? { $_.Name -eq "Plaster" }).Count -eq 0)
{
    Import-Module Plaster
}

function runningOnWindows
{
    return (Test-Path env:windir)
}

function isAPaketFolder
{
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$path
)
    return Test-Path "${path}\.paket"
}

function Invoke-Paket
{

    $currentDirectory = (Get-Item .).FullName

    $pathSeparator = "\"

    if(-Not (runningOnWindows))
    {
        $pathSeparator = "/"
    }

    $parentDirectories = ($currentDirectory -Split "\${pathSeparator}")

    if(-Not (Test-Path ".\.paket"))
    {
        for($i = 1; $i -le $parentDirectories.count; $i++){
            $lastIndex = $parentDirectories.count - $i
            $directory = $parentDirectories[0..$lastIndex] -Join $pathSeparator
            if(isAPaketFolder -path $directory)
            {
                Write-Output "Temporarily switching directory to ${directory}"
                $popd = $True
                pushd $directory
                break
            }

            if($lastIndex -eq 0)
            {
                throw New-Object System.Exception ("No .paket directory found in ${currentDirectory} or any of its parent directories.")
            }
        }
    }

    GeneratePaketFiles

    if(-not (Test-Path ".\.paket\paket.exe"))
    {
        if(runningOnWindows)
        {
            Invoke-Expression ".\.paket\paket.bootstrapper.exe"
        }
        else
        {
            Invoke-Expression "mono .\.paket\paket.bootstrapper.exe"
            Move-Item ".\paket.exe" ".\.paket\paket.exe"
        }
    }

    if(runningOnWindows)
    {
        $paketBin = ".paket\paket.exe"
    }
    else
    {
        $paketBin = "mono .paket\paket.exe"
    }

    $commandArgs = $args -join " "

    Invoke-Expression "$paketBin $commandArgs"

    ClearPaketFiles

    if($popd){
        popd
    }

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

    Write-Progress -Activity $Activity -Status "Scaffolding module filestructure" -percentComplete 10
    Invoke-Plaster @PlasterParams -NoLogo *> $null

    pushd $ModuleName

    foreach ($resource in $ResourceNames)
    {
        New-DSCResource -ResourceName $resource
    }

    BootstrapDSCModule
    popd
}

function New-DSCResource
{
param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ResourceName,
    [string]$ModuleName
)

    CheckUserConfig

    Write-Output "Scaffolding new DSC resource: $resource"

    if(!$ModuleName)
    {
        $ModuleName = (Get-Item -Path ".\" -Verbose).BaseName
    }

    if(-not (Test-Path "${ModuleName}.psd1"))
    {
        throw New-Object System.Exception ("'${ModuleName}.psd1' not found. Are you in the module root?")
    }

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

    Invoke-Plaster @PlasterParams -NoLogo 2>&1 | Out-Null

}

function Export-DSCModule
{
param
(
    [parameter(Mandatory = $true,Position=1)]
    [string]$version
)

    Invoke-Paket update
    Invoke-Paket pack output .\output version $version

}

function Test-DSCModule
{
param (
    [ValidateSet('create', 'converge', 'verify', 'test','destroy')]
    [string] $Action = 'verify',
    [switch] $Debug
)

    Write-Output "Action: $Action"

    $azureRMCredentials = "$env:HOME/.azure/credentials"

    if( -not (Test-Path $azureRMCredentials))
    {
        throw New-Object System.Exception ("Create an azure credentials file at $env:HOME/.azure/.credentials as described here: https://github.com/test-kitchen/kitchen-azurerm")
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

     Invoke-Paket update
     Invoke-Expression "bundle exec kitchen ${KitchenParams}"

}

function Get-DSCModuleGlobalConfig
{
    $configFile = "$env:HOME/DSCWorkflowConfig.json"

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

    $configFile = "$env:HOME/DSCWorkflowConfig.json"
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
    $currentDirectory = (Get-Item -Path ".\" -Verbose).FullName
    $Activity = "Bootstrapping Powershell DSC Module"
    Write-Progress -Activity $Activity -Status "Installing Paket" -percentComplete 20
    Invoke-Paket install | Out-Null
    Write-Progress -Activity $Activity -Status "Installing Ruby Dependencies" -percentComplete 40
    if(-Not (Get-Command "bundler" -ErrorAction SilentlyContinue)){
        Invoke-Expression "gem install bundler" | Out-Null
    }
    Write-Progress -Activity $Activity -Status "Installing Ruby Dependencies" -percentComplete 60
    Invoke-Expression "bundle install" | Out-Null
    Write-Progress -Activity $Activity -Status "Initialising local Git repository" -percentComplete 80
    Invoke-Expression "git init" | Out-Null
    Write-Progress -Activity $Activity -percentComplete 100
    Write-Output "Module bootstrapped at $currentDirectory"

}

function ClearPaketFiles
{
    Remove-Item paket.dependencies -ErrorAction SilentlyContinue
    Remove-Item paket.template -ErrorAction SilentlyContinue
}

function GeneratePaketFiles
{
    $ModuleName = (Get-Item -Path ".\" -Verbose).BaseName
    Import-LocalizedData -BaseDirectory "." -FileName "${ModuleName}.psd1" -BindingVariable moduleManifest
    Import-LocalizedData -BaseDirectory "." -FileName "dependencies.psd1" -BindingVariable dependenciesManifest

    ClearPaketFiles

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
