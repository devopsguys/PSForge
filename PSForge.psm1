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

function Invoke-PlasterWrapper {
    param (
        $parameters
    )
    Invoke-Plaster $parameters -NoLogo *> $null
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

. $PSScriptRoot\src\NewDSCModule.ps1
. $PSScriptRoot\src\NewDSCResource.ps1
. $PSScriptRoot\src\TestDSCModule.ps1
. $PSScriptRoot\src\ExportDSCModule.ps1
. $PSScriptRoot\src\GetDSCModuleGlobalConfig.ps1
. $PSScriptRoot\src\SetDSCModuleGlobalConfig.ps1
. $PSScriptRoot\src\InvokePaket.ps1

Export-ModuleMember -function *-*
