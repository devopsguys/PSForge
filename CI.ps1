$env:PSModulePath = "${PWD}\packages;" + $env:PSModulePath

.\paket\paket.bootstrapper.exe
.\paket\paket.exe restore

Import-Module .\PSForge.psm1

Invoke-Pester -Path .\PSForge.Tests.ps1 -CodeCoverage .\PSForge.psm1 -OutputFormat NUnitXml -OutputFile TestResults.xml -CodeCoverageOutputFile coverage.xml -PassThru
