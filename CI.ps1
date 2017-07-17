

Try {

    if([Environment]::OSVersion.Platform -eq "Unix"){
        $env:PSModulePath = "${PWD}/packages:" + $env:PSModulePath
        if(-not (Test-Path .\paket\paket.exe)){
            mono .\paket\paket.bootstrapper.exe
        }
        mono .\paket\paket.exe restore
    }else{
        $env:PSModulePath = "${PWD}\packages;" + $env:PSModulePath
        if(-not (Test-Path .\paket\paket.exe)){
            .\paket\paket.bootstrapper.exe
        }
        .\paket\paket.exe restore
    }

    Import-Module .\PSForge.psm1

    Import-LocalizedData -BaseDirectory "." -FileName "PSForge.psd1" -BindingVariable metadata

    $moduleVersion = $metadata.ModuleVersion
    $buildNumber = "$moduleVersion-$(Get-Date -Format 'yyyyMMddHHmmss')"

    Write-Host "##vso[task.setvariable variable=moduleversion]${moduleVersion}"
    Write-Host "##vso[build.updatebuildnumber]${buildNumber}"

    Invoke-Pester -Path .\PSForge.Tests.ps1 -CodeCoverage .\PSForge.psm1 -OutputFormat NUnitXml -OutputFile TestResults.xml -CodeCoverageOutputFile coverage.xml -PassThru -EnableExit

} Catch {
    Exit 1
}