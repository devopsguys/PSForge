

if([Environment]::OSVersion.Platform -eq "Unix"){
    $env:PSModulePath = "${PWD}/packages:" + $env:PSModulePath
    mono .nuget/nuget.exe install -ExcludeVersion
}else{
    $env:PSModulePath = "${PWD}\packages;" + $env:PSModulePath
    .nuget\nuget.exe install -ExcludeVersion
}

# Fix Pester on Unix
if([environment]::OSVersion.platform -eq "Unix"){
    $TestPlasterManifest = "./packages/Plaster/TestPlasterManifest.ps1"
    (Get-Content $TestPlasterManifest).replace('$schemaPath = "$PSScriptRoot\Schema\PlasterManifest-v1.xsd"', '$schemaPath = [io.path]::combine($PSScriptRoot, "Schema", "PlasterManifest-v1.xsd")') | Set-Content $TestPlasterManifest  
    $mockFile = "./packages/Pester/Functions/Mock.ps1"
    (Get-Content $mockFile).replace('if ($PSVersionTable.PSVersion -ge ''5.0.10586.122'')', 'if (''5.0.10586.122'' -le $PSVersionTable.PSVersion)') | Set-Content $mockFile    
}

Get-Module | Remove-Module -Force -ErrorAction SilentlyContinue 
Get-ChildItem -Recurse *.psm1 | Import-Module -Force

Import-LocalizedData -BaseDirectory "." -FileName "PSForge.psd1" -BindingVariable metadata

$moduleVersion = $metadata.ModuleVersion
$buildNumber = "$moduleVersion-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "##vso[task.setvariable variable=moduleversion]${moduleVersion}"
Write-Host "##vso[build.updatebuildnumber]${buildNumber}"

$excludeTag = "not" + [environment]::OSVersion.Platform

$testFiles = Get-Item "${PSScriptRoot}\src\*.Tests.ps1"
$sourceFiles = Get-Item "${PSScriptRoot}\src\*.ps1" -Exclude *.Tests.ps1
# $sourceFiles += Get-Item "${PSScriptRoot}\PSForge.psm1"

$result = Invoke-Pester -Path $testFiles -OutputFormat NUnitXml -OutputFile TestResults.xml -PassThru -CodeCoverage $sourceFiles -CodeCoverageOutputFile coverage.xml -ExcludeTag $excludeTag
    
Exit $result.FailedCount