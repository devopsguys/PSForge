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

    Describe "Smoke tests" {
        
        Push-Location $TestDrive
        New-DSCModule test-module
        Push-Location $TestDrive/test-module

        Context "GetDependenciesManifest" {
            It 'Should have created a dependency manifest' {
                Test-Path $TestDrive/test-module/dependencies.psd1 | Should be $True
            }
    
            It 'Should not throw an exception when fetching the dependency manifest' {
                { GetDependenciesManifest } | Should not Throw
            }        
    
            It 'Should be able to fetch the dependencies manifest as a hashtable' {
               GetDependenciesManifest | Should not be $null
            }

            It 'Should have no dependencies by default' {
                (GetDependenciesManifest).nugetPackages | Should be @()
            }

            It 'Should have default nuget feeds' {
                (GetDependenciesManifest).nugetFeeds | Should be @("http://nuget.org/api/v2", "http://powershellgallery.com/api/v2")
            }
        }



        Pop-Location
        Pop-Location

    }

}
