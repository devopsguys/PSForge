$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")


InModuleScope PSForge {

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

        . $PSScriptRoot\PesterHelpers.ps1
        
        Mock Invoke-ExternalCommand { "ruby 2.2.2p222 (2016-11-21 revision 56859) [x86_64-win32]"} -ParameterFilter { $Command -eq "ruby" -and $Arguments -eq @("--version")}
        
        Mock Invoke-ExternalCommand { return "/fake-path" } -ParameterFilter { $Command -eq "git" -and (Compare-Array $Arguments @("rev-parse", "--show-toplevel"))}
        Mock Test-Path { return $True } -ParameterFilter { $Path -eq "/fake-path" }
       
        It "Should output the git root" {
            getProjectRoot | should -eq "/fake-path"
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

}
