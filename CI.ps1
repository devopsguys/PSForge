

if([Environment]::OSVersion.Platform -eq "Unix"){
    $env:PSModulePath = "${PWD}/packages:" + $env:PSModulePath
    mono .nuget/nuget.exe install -ExcludeVersion
}else{
    $env:PSModulePath = "${PWD}\packages;" + $env:PSModulePath
    .nuget\nuget.exe install -ExcludeVersion
}

# Fix Pester on Unix
$mockFile = "./Packages/Pester/Functions/Mock.ps1"
(Get-Content $mockFile).replace('if ($PSVersionTable.PSVersion -ge ''5.0.10586.122'')', 'if (''5.0.10586.122'' -le $PSVersionTable.PSVersion)') | Set-Content $mockFile

Remove-Module Pester -ErrorAction SilentlyContinue
Remove-Module PSForge -ErrorAction SilentlyContinue
Import-Module .\PSForge.psm1
Import-Module .\packages\Pester\Pester.psd1

Import-LocalizedData -BaseDirectory "." -FileName "PSForge.psd1" -BindingVariable metadata

$moduleVersion = $metadata.ModuleVersion
$buildNumber = "$moduleVersion-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "##vso[task.setvariable variable=moduleversion]${moduleVersion}"
Write-Host "##vso[build.updatebuildnumber]${buildNumber}"

$result = Invoke-Pester -Path .\PSForge.Tests.ps1 -OutputFormat NUnitXml -OutputFile TestResults.xml -PassThru -CodeCoverage .\PSForge.psm1 -CodeCoverageOutputFile coverage.xml 

Exit $result.FailedCount