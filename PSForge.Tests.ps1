$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")


InModuleScope PSForge {
    # http://www.indented.co.uk/2014/04/02/compare-array/
    function Compare-Array {
        param(
            [Parameter(Mandatory = $true)]
            [Object[]]$Subject,
        
            [Parameter(Mandatory = $true)]
            [Object[]]$Object,
            
            [Switch]$ManualLoop,
            
            [Switch]$Sort
        )
        
        if ($ManualLoop) {
            # If the arrays are not the same length they cannot be equal.
            if ($Subject.Length -ne $Object.Length) {
            return $false
            }
            
            # If Sort is set and the arrays are of equal length ensure both arrays are similarly ordered.
            if ($Sort) {
            $Subject = $Subject | Sort-Object
            $Object = $Object | Sort-Object
            }
            
            $Length = $Subject.Length
            $Equal = $true
            for ($i = 0; $i -lt $Length; $i++) {
            # Exit when the first match fails.
            if ($Subject[$i] -ne $Object[$i]) {
                return $false
            }
            }
            return $true
        } else {
            # If Sort is set and the arrays are of equal length ensure both arrays are similarly ordered.
            if ($Sort) {
            $Subject = $Subject | Sort-Object
            $Object = $Object | Sort-Object
            }
        
            ([Collections.IStructuralEquatable]$Subject).Equals(
            $Object,
            [Collections.StructuralComparisons]::StructuralEqualityComparer
            )
        }
    }
        
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

        Context "Windows" {
            Mock getOSPlatform { return "windows"}

            It "Should be able to add to the PATH variable" {
                $PATH = $env:PATH
                addToPath "test"
                $env:PATH | should -BeLike "test;*"
            }
        }
       

        Context "Unix" {
            Mock getOSPlatform { return "unix"}

            It "Should be able to add to the PATH variable" {
                $PATH = $env:PATH
                addToPath "test"
                $env:PATH | should -BeLike "test:*"
            }
        }

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

    Describe "isOnPath" {
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq "installed_binary" }
        Mock Get-Command { return $False } -ParameterFilter { $Name -eq "non_installed_binary" }

        it "Should return true if a binary is on the path" {
            isOnPath "installed_binary" | should -eq $True
        }

        it "Should return false if a binary is not on the path" {
            isOnPath "non_installed_binary" | should -eq $True
        }
        
    }

    Describe "getProjectRoot" {
        Mock Invoke-ExternalCommand { "ruby 2.2.2p222 (2016-11-21 revision 56859) [x86_64-win32]"} -ParameterFilter { $Command -eq "ruby" -and $Arguments -eq @("--version")}
        
        Mock Invoke-ExternalCommand { return "/fake-path" } -ParameterFilter { $Command -eq "git" -and (Compare-Array $Arguments @("rev-parse", "--show-toplevel"))}
        Mock Test-Path { return $True } -ParameterFilter { $Path -eq "/fake-path" }
       
        It "Should output the git root" {
            getProjectRoot | should -eq "/fake-path"
        }

    }

    Describe "Export-DSCModule" {
        $version = "1.0.0"
        Mock Push-Location {}
        Mock Pop-Location {}
        Mock BootstrapDSCModule {}
        # Mock Invoke-Paket {}
        Mock Invoke-Paket {} -ParameterFilter { $args -eq "update" } -Verifiable
        Mock Invoke-Paket {} -ParameterFilter { Compare-Array $args @("pack", "output", ".\output", "version", $version) } -Verifiable

        Export-DSCModule $version
        It "Should update dependencies and export a nuget package" {
            Assert-VerifiableMocks
        }
       
    }

}
