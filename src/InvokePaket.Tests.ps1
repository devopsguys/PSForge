InModuleScope PSForge {

    Describe "BootstrapPaket" {
        Mock Push-Location {} 
        Mock Pop-Location {}
        Mock Test-Path { $False } -ParameterFilter { $Path -eq ".\paket.exe" }
        Mock Invoke-ExternalCommand {}

        Context "Windows" {
            It "Runs the paket bootrapper natively on Windows" {
                Mock isWindows { $True }
                BootstrapPaket
                Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq ".\paket.bootstrapper.exe" } -Exactly 1
                Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "mono" -and $Arguments -eq @(".\paket.bootstrapper.exe")} -Exactly 0
            }
        }

        Context "Unix" {
            It "Runs the paket bootrapper using Mono on Unix" {
                Mock isWindows { $False }
                BootstrapPaket
                Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq ".\paket.bootstrapper.exe" } -Exactly 0
                Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "mono" -and $Arguments -eq @(".\paket.bootstrapper.exe")} -Exactly 1
            }
        }
    }
    
    Describe "Invoke-Paket" {
        Mock getOSPlatform { "windows" }
        Mock generatePaketFiles {}
        Mock getProjectRoot {}
        Mock Invoke-ExternalCommand {} -ParameterFilter { $Command -eq ".paket\paket.exe" }
        Mock clearPaketFiles {}
        Mock Test-Path { $True } -ParameterFilter { $Path -eq ".\.paket\paket.exe" }
        Mock BootstrapDSCModule {}
        Mock BootstrapPaket {}

        It "Should bootstrap Paket executable" {
            Invoke-Paket
            Assert-MockCalled BootstrapPaket -Exactly 1 -Scope It
        }

        It "Should run Bootstrap by default" {
            Invoke-Paket
            Assert-MockCalled BootstrapDSCModule -Exactly 1 -Scope It
        }

        It "Should generate Paket files" {
            Invoke-Paket
            Assert-MockCalled generatePaketFiles -Exactly 1 -Scope It
        }

        It "Should try and change directory to project root" {
            Invoke-Paket
            Assert-MockCalled getProjectRoot -Exactly 1 -Scope It
        }

        It "Should execute Paket with mono on Unix" {
            Mock getOSPlatform { "unix" }
            Mock Invoke-ExternalCommand { } -ParameterFilter { $Command -eq "mono .paket\paket.exe" } 
            Mock Invoke-ExternalCommand { "linux" } -ParameterFilter { $Command -eq "uname" } 
            Invoke-Paket
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "mono .paket\paket.exe" } -Exactly 1 -Scope It
        }

        It "Should execute Paket directly on Windows" {
            Mock getOSPlatform { "windows" } 
            Mock Invoke-ExternalCommand {} -ParameterFilter { $Command -eq ".paket\paket.exe" } 
            Invoke-Paket
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq ".paket\paket.exe" } -Exactly 1 -Scope It
        }

    }

    Describe "generatePaketFiles" {
        
        $moduleManifest = @{
            "ModuleVersion" = "1.0.0";
            "Author" = "Edmund Dipple";
            "Description" = "Test Module";
        }

        $dependenciesManifest = @{
            "NugetFeeds" = @("http://nuget.org/api/v2","http://powershellgallery.com/api/v2");
            "NugetPackages" = @("package1 == 1.0.0.0","package2 == 2.0.0.0");
        }

        Mock GetModuleName { return "TestModule" }
        Mock GetModuleManifest {return $moduleManifest}
        Mock GetDependenciesManifest { return $dependenciesManifest }
        
        Mock clearPaketFiles {}
        Mock New-Item {}
        Mock Copy-Item {} 
        Mock Out-File {}
        
        generatePaketFiles
        
        it "Should create a paket.dependencies file" {
            Assert-MockCalled New-Item -ParameterFilter { $Path -eq "paket.dependencies"} -Exactly 1 -Scope Describe
        }
         
        it "Should copy paket executables over" {
            Assert-MockCalled Copy-Item -Exactly 1 -Scope Describe
        }

        it "Should add nuget feeds to paket.dependencies" {
            Assert-MockCalled Out-File -ParameterFilter { $InputObject -eq "source http://nuget.org/api/v2" } -Exactly 1 -Scope Describe
            Assert-MockCalled Out-File -ParameterFilter { $InputObject -eq "source http://powershellgallery.com/api/v2" } -Exactly 1 -Scope Describe
        }

        it "Should add nuget feeds to paket.dependencies" {
            Assert-MockCalled Out-File -ParameterFilter { $InputObject -eq "nuget package1 == 1.0.0.0" } -Exactly 1 -Scope Describe
            Assert-MockCalled Out-File -ParameterFilter { $InputObject -eq "nuget package2 == 2.0.0.0" } -Exactly 1 -Scope Describe
        }

        it "Should set up the paket.template file" {
            $paketTemplateString = `
@"
type file
id TestModule
version 1.0.0
authors Edmund Dipple
description
    Test Module
files
    TestModule.psd1 ==> .
    DSCResources ==> DSCResources
dependencies
"@
            GeneratePaketTemplate "TestModule" $moduleManifest | should -eq $paketTemplateString
            Assert-MockCalled Out-File -ParameterFilter { $InputObject -eq $paketTemplateString } -Exactly 1 -Scope Describe
        }
                              
    }
    Describe "clearPaketFiles" {
        Mock Remove-Item {}

        clearPaketFiles

        It "Should remove all paket files" {
            Assert-MockCalled Remove-Item -ParameterFilter { $Path -eq ".paket" -and $Recurse -eq $True } -Exactly 1 -Scope Describe
            Assert-MockCalled Remove-Item -ParameterFilter { $Path -eq "paket.template" } -Exactly 1 -Scope Describe
            Assert-MockCalled Remove-Item -ParameterFilter { $Path -eq "paket.dependencies" } -Exactly 1 -Scope Describe
        }
    }

}