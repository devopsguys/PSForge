$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")


InModuleScope PSForge {
    # http://www.indented.co.uk/2014/04/02/compare-array/
    function Compare-Array {
        $($args[0] -join ",") -eq $($args[1] -join ",")
    }

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
                $env:PATH = $PATH
            }
        }
       

        Context "Unix" {
            Mock getOSPlatform { return "unix"}

            It "Should be able to add to the PATH variable" {
                $PATH = $env:PATH
                addToPath "test"
                $env:PATH | should -BeLike "test:*"
                $env:PATH = $PATH
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
        Mock getProjectRoot {return "a" }
        Mock Push-Location {} -ParameterFilter { $path -eq "a" } -Verifiable
        Mock Pop-Location {} -Verifiable
        Mock BootstrapDSCModule {} -Verifiable
        Mock Invoke-Paket {} -ParameterFilter { $args -eq "update" } -Verifiable
        Mock Invoke-Paket {} -ParameterFilter { Compare-Array $args @("pack", "output", ".\output", "version", $version) } -Verifiable

        Export-DSCModule $version
        It "Should update dependencies and export a nuget package" {
            Assert-VerifiableMocks
        }
       
    } 

    Describe "CheckUserConfig" {
        Mock Set-DSCModuleGlobalConfig {}
        Mock Get-DSCModuleGlobalConfig {}

        Context "No configuration available" {

            It "Should set username to new value if missing" {
                Mock Read-Host { "test_username"}
                CheckUserConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "username" -and $Value -eq "test_username" }  -Exactly 1 -Scope It
            }
    
            It "Should set username to default value if value not provided" {
                Mock Read-Host {}
                CheckUserConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "username" -and $Value -eq [Environment]::UserName }  -Exactly 1 -Scope It
            }
    
            It "Should set company if missing" {
                Mock Read-Host { "test_company"}
                CheckUserConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "company" -and $Value -eq "test_company" }  -Exactly 1 -Scope It
            }
    
            It "Should set company to default value if value not provided" {
                Mock Read-Host {}
                CheckUserConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "company" -and $Value -eq "None" }  -Exactly 1 -Scope It
            }

        }

        Context "Configuration already set up" {
            Mock Get-DSCModuleGlobalConfig {
                @{ "username" = "test_username";
                   "company" = "test_company"
                }
            }

            It "Should not prompt for information it already has" {
                Assert-MockCalled Set-DSCModuleGlobalConfig -Exactly 0
            }

        }
        
    }

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
    
    Describe "InstallRuby" {

        Mock addToPath {}
        Mock Invoke-ExternalCommand {}
        Mock Invoke-WebRequest {}
        Mock New-Item {}
        Mock Remove-Item {}
        Mock fixRubyCertStore {}
        Mock Test-Path { $False }
        Mock Write-Output {}
        
        Context "Windows" {
            Mock isWindows { $True }
            installRuby
            It "Should run installers on Unix" {
                Assert-MockCalled addToPath -Exactly 1 -Scope Context
                Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope Context
                Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope Context
                Assert-MockCalled Write-Output -ParameterFilter { $InputObject -eq "Using system ruby on non-windows platforms" } -Exactly 0 -Scope Context
            }
        }

        Context "Unix" {
            Mock isWindows { $False }
            installRuby
            It "Should not run any installers on Unix" {
                Assert-MockCalled addToPath -Exactly 0 -Scope Context
                Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope Context
                Assert-MockCalled Invoke-ExternalCommand -Exactly 0 -Scope Context
                Assert-MockCalled Write-Output -ParameterFilter { $InputObject -eq "Using system ruby on non-windows platforms" } -Exactly 1 -Scope Context
            }
        }
    }

    Describe "fixRubyCertStore" {

        Class FakeWebClient { DownloadFile($arg1, $arg2) {} }
        $fakeWebClient = New-Object FakeWebClient

        Mock isWindows { $True }
        Mock New-Item {}
        Mock New-Object { $fakeWebClient }

        fixRubyCertStore

        It "Should create the directory to host the CACERT" {
            Assert-MockCalled New-Item -ParameterFilter { $Path -eq "C:\RUBY_SSL" } -Exactly 1 -Scope Describe
        }

        It "Should download the CACERT file" {
            Assert-MockCalled New-Object -ParameterFilter { $TypeName -eq "System.Net.WebClient" } -Exactly 1 -Scope Describe
        }
    }

    Describe "Test-DSCModule" {
        Mock getProjectRoot { "/fake-path"}
        Mock Push-Location {}
        Mock Pop-Location {}
        Mock BootstrapDSCModule {}
        Mock Invoke-ExternalCommand {}
        Mock updateBundle {}
        Mock Invoke-Paket {}
        Mock Read-Host {}
       
        it "Should throw an exception if the credentials file is missing" {
            Mock Test-Path { $False } -ParameterFilter { $Path -eq "$HOME/.azure/credentials" }
            { Test-DSCModule } | Should Throw "Create an azure credentials file at /Users/edmundd/.azure/.credentials as described here: https://github.com/test-kitchen/kitchen-azurerm"
        }

        it "Should prompt the user if the subscription environment variable has not been set" {
            Mock Test-Path { $True } -ParameterFilter { $Path -eq "$HOME/.azure/credentials" }
            Mock Test-Path { $False } 
            
            Test-DSCModule

            Assert-MockCalled Read-Host -Exactly 1 -Scope It
        }

        it "Should bootstrap the module dependencies" {
            Test-DSCModule
            Assert-MockCalled BootstrapDSCModule -Exactly 1 -Scope It
        }

        it "Should update the ruby bundle" {
            Test-DSCModule
            Assert-MockCalled updateBundle -Exactly 1 -Scope It
        }

        it "Should pass the correct argument to Test Kitchen by default" {
            Test-DSCModule
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("exec", "kitchen", "verify")) } -Scope It
        }

        it "Should pass the correct argument to Test Kitchen if different action is specified" {
            Test-DSCModule converge
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("exec", "kitchen", "converge")) } -Scope It
        }

        it "Should throw an exception if invalid action is specified" {
            { Test-DSCModule invalid } | Should Throw 
        }

        it "Should pass the correct argument to Test Kitchen if -Debug is used" {
            Test-DSCModule -Debug
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("exec", "kitchen", "verify", "--log-level","Debug")) } -Scope It
        }

    }
}
