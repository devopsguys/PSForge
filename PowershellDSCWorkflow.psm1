Import-Module Plaster

function Invoke-Paket
{

    $isWindows = Test-Path env:windir

    if(-not (Test-Path ".\.paket\paket.exe"))
    {
        if($isWindows)
        {
            Invoke-Expression ".\.paket\paket.bootstrapper.exe"
        }
        else
        {
            Invoke-Expression "mono .\.paket\paket.bootstrapper.exe"
            Move-Item ".\paket.exe" ".\.paket\paket.exe"
        }
    }

    if($isWindows)
    {
        $paketBin = ".paket\paket.exe"
    }
    else
    {
        $paketBin = "mono .paket\paket.exe"
    }

    $commandArgs = $args -join " "

    Invoke-Expression "$paketBin $commandArgs"
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

    foreach ($resource in $ResourceNames)
    {
        $PlasterParams = @{
         TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-resource";
         DestinationPath = "$ModuleName\packages\$ModuleName\DSCResources\$resource"
         project_name = $resource
        }
        Write-Output "Scaffolding new DSC resource: $resource"
        Invoke-Plaster @PlasterParams -NoLogo
    }

    pushd $ModuleName
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
        $exception = New-Object System.Exception ("Create an azure credentials file at $env:HOME/.azure/.credentials as described here: https://github.com/test-kitchen/kitchen-azurerm")
        throw $exception
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
    & gem install bundler
    & bundle install
    & git init
}

Export-ModuleMember -function *-*
