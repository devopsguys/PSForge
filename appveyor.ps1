Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Pester -Scope CurrentUser
Install-Module Plaster -Scope CurrentUser
Import-Module .\PSForge.psm1
$res = Invoke-Pester -Path .\PSForge.Tests.ps1 -OutputFormat NUnitXml -OutputFile TestsResults.xml -PassThru
(New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path .\TestsResults.xml))
if ($res.FailedCount -gt 0) { throw "$($res.FailedCount) tests failed."}
