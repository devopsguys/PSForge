$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

InModuleScope PSForge {

    # Describe "PSForge" {
    #     It "PSForge is available to be imported when called" {
    #         Get-Module  –ListAvailable | where { $_.Name –eq 'PSForge' } | should not be $null  
    #     }
    # }

    Describe "OS Detection" {

        It "Should fetch OS platform from Powershell" {
            $platform = [Environment]::OSVersion.Platform
            getOSPlatform | should be $platform
        }

        Context "Windows" {
            Mock getOSPlatform { "windows" }
            It "Should detect Windows installation" {
                isWindows | should be $True
                isUnix | should be $False
                Assert-VerifiableMocks
            }
        }

        Context "Unix" {
            Mock getOSPlatform { "unix" }
            
            It "Should detect Unix installation" {
                isWindows | should be $False
                isUnix | should be $True
                Assert-VerifiableMocks
            }
        }
           
    }

    Describe "Dependency checking"{

        Context "Mono is not installed" {
            
            It "Should throw exception if Mono not installed on Unix" {
                Mock getOSPlatform { "unix" }
                
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }
                 
                { CheckDependencies } | Should Throw "PSForge has a dependency on 'mono' on Linux and MacOS - please install mono via the system package manager."
            }

            It "Should not throw exception if Mono not installed on Windows" {
                Mock getOSPlatform { "windows" }
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }
            
                { CheckDependencies } | Should not Throw
            }
        
        }

        Context "Ruby is not installed" {
            
            $rubyException = "PSForge has a dependency on 'ruby' 2.3 or higher - please install ruby via the system package manager."
            $rubyVersionException = "PSForge has a dependency on 'ruby' 2.3 or higher. Current version of ruby is 2.2.2p222 - please update ruby via the system package manager."

            It "Should throw exception if Ruby not installed on Unix" {
                Mock getOSPlatform { "unix" }
                
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "ruby" }
                   
                { CheckDependencies } | Should Throw $rubyException
            }

            It "Should not throw exception if Ruby not installed on Windows" {
                Mock getOSPlatform { "windows" }
                
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "ruby" }
                
                { CheckDependencies } | Should Throw $rubyException
            }

            It "Should throw exception if wrong Ruby installed on Unix" {
                Mock getOSPlatform { "unix" }

                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }
                Mock Invoke-ExternalCommand { "ruby 2.2.2p222 (2016-11-21 revision 56859) [x86_64-darwin16]"} -ParameterFilter { $Command -eq "ruby" -and $Arguments -eq @("--version") }
                
                { CheckDependencies } | Should Throw $rubyVersionException
            }

            It "Should throw exception if wrong Ruby installed on Windows" {
                Mock getOSPlatform { "windows" }
                
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }
                Mock Invoke-ExternalCommand { "ruby 2.2.2p222 (2016-11-21 revision 56859) [x86_64-win32]"} -ParameterFilter { $Command -eq "ruby" -and $Arguments -eq @("--version")}
                
                { CheckDependencies } | Should Throw $rubyVersionException
            }
        
        }

        Context "Git is not installed" {
            
            $gitException = "PSForge has a dependency on 'git' - please install git via the system package manager."

            It "Should throw exception if Git not installed on Unix" {
                Mock getOSPlatform { "unix" }
                
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }
                
                { CheckDependencies } | Should Throw $gitException
            }

            It "Should not throw exception if Git not installed on Windows" {
                Mock getOSPlatform { "windows" }
                
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "mono" }
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "git" }
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }

                { CheckDependencies } | Should Throw $gitException
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
        
        $dependenciesManifest = @{
            "NugetFeeds" = @("http://nuget.org/api/v2","http://powershellgallery.com/api/v2");
            "NugetPackages" = @("package1 == 1.0.0.0","package2 == 2.0.0.0")
        }

        Mock GetModuleManifest {}
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
                                            
    }

}
