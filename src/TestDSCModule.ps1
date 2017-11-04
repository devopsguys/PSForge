function Test-DSCModule
{
param (
    [ValidateSet('create', 'converge', 'verify', 'test','destroy','login')]
    [string] $Action = 'verify',
    [switch] $Debug,
    [switch] $SkipScriptAnalyzer,
    [switch] $SkipUnitTests,
    [switch] $SkipIntegrationTests
)

    Push-Location "$(getProjectRoot)"

    Write-Output "Action: $Action"

    BootstrapDSCModule

    if(-not $SkipScriptAnalyzer -and ($Action -in @("setup","converge","create","test","verify"))) {
        if(isWindows){
          Write-Output "[PSForge] Running PSScriptAnalyzer on resources"
          $result = Invoke-ScriptAnalyzer -Path .\DSCResources -Recurse
            if($result.count -gt 0){
                Write-Output $result
                Throw "One or more issues found by PSScriptAnalyzer"
            }
        }else {
            Write-Output "INFO: PSScriptAnalyzer only runs reliably on Windows at the moment, so it is disabled on Unix."
        }
    }

    if(-not $SkipUnitTests -and ($Action -in @("setup","converge","create","test","verify"))){
      Write-Output "[PSForge] Running unit tests on resources"
      $testFiles = Get-Item ".\DSCResources\**\*.Tests.ps1" -ErrorAction SilentlyContinue
      $sourceFiles = Get-Item ".\DSCResources\**\*.Tests.ps1" -Exclude *.Tests.ps1 -ErrorAction SilentlyContinue
      
      $result = Invoke-Pester -Path $testFiles -OutputFormat NUnitXml -OutputFile TestResults.xml -PassThru -CodeCoverage $sourceFiles -CodeCoverageOutputFile CodeCoverage.xml
      
      if($result.FailedCount -gt 0){
        Throw "One or more unit tests failed"
      }      
    }

    if(-not $SkipIntegrationTests) {
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

      $BundleExec = @('exec','kitchen')
      $KitchenParams = @($Action)

      if($Debug)
      {
          $KitchenParams += @("--log-level","Debug")
      }

      $BundleExec += $KitchenParams
      updateBundle

      if($Action -in @("setup","converge","create","test","verify")){
          Invoke-Paket update
      }
      
      Invoke-ExternalCommandRealtime "bundle" $BundleExec
    }

    Pop-Location

}