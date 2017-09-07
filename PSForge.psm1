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

    [string]$longRubyVersion = (Invoke-ExternalCommand "ruby" @("--version")).split(' ')[1]
    [double]$shortRubyVersion = ($longRubyVersion.split('.')[0,1]) -join '.'

    if($shortRubyVersion -lt 2.3)
    {
        throw New-Object System.Exception ("PSForge has a dependency on 'ruby' 2.3 or higher. Current version of ruby is ${longRubyVersion} - please update ruby via the system package manager.")
    }

}

function installRuby
{	
    if(isWindows)
    {
        $RubyPath = "$PSScriptRoot\ruby-2.3.3-i386-mingw32\bin\"
        addToPath $RubyPath
        if(-not (Test-Path "$RubyPath\ruby.exe"))
        {
            $Activity = "Installing Ruby"
            $rubyURL = "https://dl.bintray.com/oneclick/rubyinstaller/ruby-2.3.3-i386-mingw32.7z"
            $rubyInstaller = "$PSScriptRoot\ruby.7z"
            Write-Progress -Activity $Activity -Status "Downloading Ruby archive" -percentComplete 20
            Invoke-WebRequest -Uri $rubyURL -OutFile $rubyInstaller 
            Write-Progress -Activity $Activity -Status "Extracting Ruby archive" -percentComplete 60
            Invoke-ExternalCommand $PSScriptRoot\7zip\7za.exe @("x", "$rubyInstaller", "-o""${PSScriptRoot}""") | Out-Null
            Write-Progress -Activity $Activity -percentComplete 100 -Completed
            Remove-Item $rubyInstaller
            fixRubyCertStore
        }
    }else{
        Write-Output "Using system ruby on non-windows platforms"
    }
}

function fixRubyCertStore {
    if(isWindows){
        $SSL_DIR = "C:\RUBY_SSL"
        $CA_FILE = "cacert.pem"
        $CA_URL = "https://curl.haxx.se/ca/${CA_FILE}"
        
        New-Item -Type Directory -Force $SSL_DIR
        
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
        
        [Environment]::SetEnvironmentVariable("SSL_CERT_FILE", "${SSL_DIR}\${CA_FILE}", "User")
        $Env:SSL_CERT_FILE = [Environment]::GetEnvironmentVariable("SSL_CERT_FILE", "User")
        
        (New-Object System.Net.WebClient).DownloadFile($CA_URL, "${SSL_DIR}\${CA_FILE}")
        
        Write-Output "Latest ${CA_FILE} from ${CA_URL} has been downloaded to ${SSL_DIR}"
        Write-Output "Environment variable SSL_CERT_FILE set to $($Env:SSL_CERT_FILE)"
        Write-Output "Ruby for Windows should now be able to verify remote SSL connections"
    }
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

function updateBundle{

    if(-not (isOnPath "bundler"))
    {
        Invoke-ExternalCommand "gem" @("install", "bundler") | Out-Null
    }

    $bundle = Start-Process -FilePath "bundle" -ArgumentList "check" -Wait -NoNewWindow -RedirectStandardOutput stdout -PassThru
    Remove-Item stdout
    if($bundle.Exitcode -ne 0)
    {
        Invoke-ExternalCommand "bundle" @("install","--path", ".bundle")
    }
}

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

    Invoke-ExternalCommand $paketBin $args

    clearPaketFiles

    Pop-Location

}

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
        TemplatePath = "$PSScriptRoot\plaster-powershell-dsc-resource";
        DestinationPath = "DSCResources\${ResourceName}";
        project_name = $ResourceName;
        company =  $metadata.CompanyName;
        project_short_description = $ModuleName;
        full_name = $metadata.Author;
        version = "1.0.0";
    }

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

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
        $env:AZURERM_SUBSCRIPTION = $prompt
    }

    $KitchenParams = @($Action)

    if($Debug)
    {
        $KitchenParams += @("--log-level","Debug")
    }

    updateBundle

    Invoke-Paket update
    Invoke-ExternalCommand "bundle" (@("exec", "kitchen") + ${KitchenParams})

    Pop-Location

}

function Get-DSCModuleGlobalConfig
{
    $configFile = "$HOME/DSCWorkflowConfig.json"

    if(-Not (Test-Path $configFile))
    {
        $config = @{}
    }
    else
    {
        $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json
    }

    if(!$config.username)
    {
        $defaultValue = [Environment]::UserName
        $username = Read-Host "What is your username? [$($defaultValue)]"
        $username = ($defaultValue,$username)[[bool]$username]
        Set-DSCModuleGlobalConfig "username" "$username"
        $config["username"] = "$username"
    }

    if(!$config.company)
    {
        $defaultValue = "None"
        $company = Read-Host "What is your company name? [$($defaultValue)]"
        $company = ($defaultValue,$company)[[bool]$company]
        Set-DSCModuleGlobalConfig "company" "$company"
        $config["company"] = "$company"
    }

    return $config

}

function Set-DSCModuleGlobalConfig
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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
    $json = ConvertTo-Json -depth 100 -InputObject $json
    $json | Out-File $configFile -encoding utf8

}

function BootstrapPaket
{
    Push-Location "$PSScriptRoot\paket"
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

function BootstrapDSCModule
{

    $Activity = "Bootstrapping Powershell DSC Module"

    installRuby
    checkDependencies

    if(!(Test-Path ".\.git"))
    {
        Write-Progress -Activity $Activity -Status "Initialising local Git repository" -percentComplete 60
        Invoke-ExternalCommand "git" @("init") | Out-Null
    }

    Write-Progress -Activity $Activity -percentComplete 100 -Completed

}

function clearPaketFiles
{
    Remove-Item -Recurse -Force .paket -ErrorAction SilentlyContinue
    Remove-Item -Force paket.dependencies -ErrorAction SilentlyContinue
    Remove-Item -Force paket.template -ErrorAction SilentlyContinue
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

    Copy-Item -Recurse $PSScriptRoot\paket .\.paket | Out-Null

    ForEach($nugetFeed in $dependenciesManifest.NugetFeeds)
    {
        "source $nugetFeed" | Out-File paket.dependencies -Append -Encoding utf8
    }

    ForEach($nugetPackage in $dependenciesManifest.NugetPackages)
    {
        "nuget $nugetPackage" | Out-File paket.dependencies -Append -Encoding utf8
    }

    GeneratePaketTemplate $moduleName $moduleManifest
    GeneratePaketTemplate $moduleName $moduleManifest | Out-File  paket.template -Append -Encoding utf8

    ForEach($nugetPackage in $dependenciesManifest.NugetPackages)
    {

        "    $(($nugetPackage -Split " ")[0]) == LOCKEDVERSION" | Out-File paket.template -Append -Encoding utf8
    }

}

Export-ModuleMember -function *-*
