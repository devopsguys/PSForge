Import-Module Plaster

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

    Invoke-Plaster @PlasterParams -NoLogo

    foreach ($resource in $ResourceNames)
    {
        $PlasterParams = @{
         TemplatePath = "$PSScriptRoot\paket-files\devopsguys\plaster-powershell-dsc-scaffolding\plaster-powershell-dsc-resource";
         DestinationPath = "$ModuleName\packages\DSCResources\"
         project_name = $resource
        }

        Invoke-Plaster @PlasterParams -NoLogo
    }

    cd $ModuleName
    Bootstrap-DSCModule

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

function Package-DSCModule
{
param
(
    [parameter(Mandatory = $true,Position=1)]
    [string]$version
)

if(-not (Test-Path ".paket\paket.exe"))
{
    $exception = "'.paket\paket.exe' not found. Are you in the module root?"
}

    Invoke-Expression ".paket\paket.exe pack output .\output version $version"

}

function Test-DSCModule
{
param (
    [ValidateSet('create', 'converge', 'verify', 'test','destroy')]
    [string] $action = 'verify'
)

    Write-Output "Action: $action"

    $azureRMCredentials = "$env:home/.azure/credentials"

    if( -not (Test-Path $azureRMCredentials))
    {
        Write-Output "Create an azure credentials file at $env:home/.azure/.credentials"
        Write-Output "as described here: https://github.com/test-kitchen/kitchen-azurerm"
        exit 1
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

     Invoke-Expression "bundle exec kitchen $action --log-level Debug"

}

function Bootstrap-DSCModule
{
    & .\paket install
    & gem install bundler
    & bundle install
}

Export-ModuleMember -Function * -Alias *
