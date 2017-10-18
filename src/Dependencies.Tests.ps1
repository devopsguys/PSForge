InModuleScope PSForge {
    Describe "Dependency checking"{
        
        Mock Invoke-ExternalCommand { "ruby 2.3.3p222 (2016-11-21 revision 56859) [x86_64-darwin16]" } -ParameterFilter { $Command -eq "ruby" }

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

    Describe "InstallRuby" {
        
        Mock Push-Location {}
        Mock Pop-Location {}
        
        Mock addToPath {}
        Mock Invoke-ExternalCommand {}
        Mock Invoke-WebRequest {}
        Mock New-Item {}
        Mock Remove-Item {}
        Mock fixRubyCertStore {}
        Mock Test-Path { $False }
        Mock Write-Debug {}
        
        Context "Windows" {
            Mock isWindows { $True }
            installRuby
            It "Should run installers on Unix" {
                Assert-MockCalled addToPath -Exactly 1 -Scope Context
                Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope Context
                Assert-MockCalled Invoke-ExternalCommand -Exactly 2 -Scope Context
                Assert-MockCalled Write-Debug -ParameterFilter { $InputObject -eq "Using system ruby on non-windows platforms" } -Exactly 0 -Scope Context
            }
        }

        Context "Unix" {
            Mock isWindows { $False }
            installRuby
            It "Should not run any installers on Unix" {
                Assert-MockCalled addToPath -Exactly 0 -Scope Context
                Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope Context
                Assert-MockCalled Invoke-ExternalCommand -Exactly 0 -Scope Context
                Assert-MockCalled Write-Debug -ParameterFilter { $Message -eq "Using system ruby on non-windows platforms" } -Exactly 1 -Scope Context
            }
        }
    }

    Describe "fixRubyCertStore" {

        Class FakeWebClient { DownloadFile($arg1, $arg2) {} }
        $fakeWebClient = New-Object FakeWebClient

        Mock isWindows { $True }
        Mock New-Item {}
        Mock New-Object { $fakeWebClient } -ParameterFilter { $TypeName -eq "System.Net.WebClient" }

        fixRubyCertStore

        It "Should create the directory to host the CACERT" {
            Assert-MockCalled New-Item -ParameterFilter { $Path -eq "C:\RUBY_SSL" } -Exactly 1 -Scope Describe
        }

        It "Should download the CACERT file" {
            Assert-MockCalled New-Object -ParameterFilter { $TypeName -eq "System.Net.WebClient" } -Exactly 1 -Scope Describe
        }
    }

    Describe "updateBundle" {

        . $PSScriptRoot\PesterHelpers.ps1

        Mock isOnPath { $false } -ParameterFilter { $cmd -eq "bundler" }
        Mock Invoke-ExternalCommand {}
        Mock Invoke-ExternalCommandRealtime {}
        Mock Start-Process { return @{"ExitCode" = 1} }
        Mock Remove-Item {}

        
        It "Should install bundler gem if not on the path" {
            updateBundle
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter {  $Command -eq "gem" -and (Compare-Array $Arguments @("install", "bundler")) } -Exactly 1 -Scope It
        }

        It "Should check for updates to bundled gems" {
            Mock Start-Process { return @{"ExitCode" = 1} }
            updateBundle
            Assert-MockCalled Start-Process -ParameterFilter { $FilePath -eq "bundle" -and $ArgumentList -eq "check" } -Exactly 1 -Scope It
        }

        It "Should not update bundle if there are no pending updates" {
            Mock Start-Process { return @{"ExitCode" = 0} }
            updateBundle
            Assert-MockCalled Invoke-ExternalCommandRealtime -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("install", "--path", ".bundle")) } -Exactly 0 -Scope It
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

}