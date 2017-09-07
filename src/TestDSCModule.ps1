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