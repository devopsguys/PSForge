

if([Environment]::OSVersion.Platform -eq "Unix"){
    $env:PSModulePath = "${PWD}/packages:" + $env:PSModulePath
    mono .nuget/nuget.exe install -ExcludeVersion
}else{
    $env:PSModulePath = "${PWD}\packages;" + $env:PSModulePath
    .nuget\nuget.exe install -ExcludeVersion
}

Import-Module .\PSForge.psm1

Import-LocalizedData -BaseDirectory "." -FileName "PSForge.psd1" -BindingVariable metadata

$moduleVersion = $metadata.ModuleVersion
$buildNumber = "$moduleVersion-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "##vso[task.setvariable variable=moduleversion]${moduleVersion}"
Write-Host "##vso[build.updatebuildnumber]${buildNumber}"

$testResults = "TestResults-$([Environment]::OSVersion.Platform).xml"
$coverage = "coverage-$([Environment]::OSVersion.Platform).xml"

$result = Invoke-Pester -Path .\PSForge.Tests.ps1 -CodeCoverage .\PSForge.psm1 -OutputFormat NUnitXml -OutputFile $testResults -CodeCoverageOutputFile $coverage -PassThru

Exit $result.FailedCount