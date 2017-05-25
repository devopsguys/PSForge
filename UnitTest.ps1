Import-Module Pester

Remove-Module PSForge -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot/PSForge.psm1

Invoke-Pester $PSScriptRoot/PSForge.Tests.ps1
