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

    if($popd){
        popd
    }

}

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

    Write-Output "Scaffolding new DSC module: $resource"
    Invoke-Plaster @PlasterParams -NoLogo

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

    Write-Output "Scaffolding new DSC resource: $resource"

    if(!$ModuleName)
    {
        $ModuleName = (Get-Item -Path ".\" -Verbose).BaseName
    }

    if(-not (Test-Path "packages\${ModuleName}"))
    {
        throw New-Object System.Exception ("Directory 'packages\${ModuleName}' not found. Are you in the module root?")
    }

    $PlasterParams = @{
        TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-resource";
        DestinationPath = "packages\${ModuleName}\DSCResources\${ResourceName}"
        project_name = $ResourceName
    }

    Import-LocalizedData -BaseDirectory "packages\${ModuleName}" -FileName "${ModuleName}.psd1" -BindingVariable metadata

    $PlasterParams.company = $metadata.CompanyName
    $PlasterParams.project_short_description = $ModuleName
    $PlasterParams.full_name = $metadata.Author
    $PlasterParams.version = "1.0.0"

    Invoke-Plaster @PlasterParams -NoLogo

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

function BootstrapDSCModule
{
    Invoke-Paket install
    if(-Not (Get-Command "bundler" -ErrorAction SilentlyContinue)){
        Invoke-Expression "gem install bundler"
    }
    Invoke-Expression "bundle install"
    Invoke-Expression "git init"
}

Export-ModuleMember -function *-*
