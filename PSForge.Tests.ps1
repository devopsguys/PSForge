$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

InModuleScope PSForge {

    Describe "PSForge" {
        It "PSForge is available to be imported when called" {
            Get-Module  –ListAvailable | where { $_.Name –eq 'PSForge' } | should not be $null  
        }
    }

    Describe "OS Detection" {
    
        Context "Windows" {
            Mock getEnvironmentOSVersion { @{"Platform" = "Windows" }}
            It "Should detect Windows installation" {
                getOSPlatform | should be "windows"
                isWindows | should be $True
                isUnix | should be $False
            }
        }

        Context "Linux" {
            Mock getEnvironmentOSVersion { @{"Platform" = "Unix" }}
            
            Mock Invoke-Expression { "Linux" } -Verifiable -ParameterFilter {$Command -eq "uname"}
            It "Should detect Linux installation" {
                getOSPlatform | should be "linux"
                isWindows | should be $False
                isUnix | should be $True
                Assert-VerifiableMocks
            }
        }

        Context "MacOS" {
            Mock getEnvironmentOSVersion { @{"Platform" = "Unix" }}
            
            Mock Invoke-Expression { "Darwin" } -Verifiable -ParameterFilter {$Command -eq "uname"}
            It "Should detect Linux installation" {
                getOSPlatform | should be "mac"
                isWindows | should be $False
                isUnix | should be $True
                Assert-VerifiableMocks
            }
        }
           
    }

    Describe "Dependency checking"{

        Context "Mono is not installed" {
            
            It "Should throw exception if Mono not installed on Unix" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Unix" }}
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "mono" }
                 { CheckDependencies } | Should Throw "PSForge has a dependency on 'mono' on Linux and MacOS - please install mono via the system package manager."
            }

            It "Should not throw exception if Mono not installed on Windows" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Windows" }}
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "mono" }
                 { CheckDependencies } | Should not Throw
            }
        
        }

        Context "Ruby is not installed" {
            
            $rubyException = "PSForge has a dependency on 'ruby' 2.3 or higher - please install ruby via the system package manager."
            $rubyVersionException = "PSForge has a dependency on 'ruby' 2.3 or higher. Current version of ruby is 2.2.2p222 - please update ruby via the system package manager."

            It "Should throw exception if Ruby not installed on Unix" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Unix" }}
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "ruby" }
                 { CheckDependencies } | Should Throw $rubyException
            }

            It "Should not throw exception if Ruby not installed on Windows" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Windows" }}
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "ruby" }
                 { CheckDependencies } | Should Throw $rubyException
            }

            It "Should throw exception if wrong Ruby installed on Unix" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Unix" }}
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }
                Mock Invoke-Expression { "ruby 2.2.2p222 (2016-11-21 revision 56859) [x86_64-darwin16]"} -ParameterFilter { $Command -eq "ruby --version" }
                 { CheckDependencies } | Should Throw $rubyVersionException
            }

            It "Should not throw exception if wrong Ruby installed on Windows" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Windows" }}
                Mock isOnPath { $True } -ParameterFilter { $cmd -eq "ruby" }
                Mock Invoke-Expression { "ruby 2.2.2p222 (2016-11-21 revision 56859) [x86_64-darwin16]"} -ParameterFilter { $Command -eq "ruby --version" }
                 { CheckDependencies } | Should Throw $rubyVersionException
            }
        
        }

        Context "Git is not installed" {
            
            $gitException = "PSForge has a dependency on 'git' - please install git via the system package manager."

            It "Should throw exception if Git not installed on Unix" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Unix" }}
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "git" }
                 { CheckDependencies } | Should Throw $gitException
            }

            It "Should not throw exception if Git not installed on Windows" {
                Mock getEnvironmentOSVersion { @{"Platform" = "Windows" }}
                Mock isOnPath { $False } -ParameterFilter { $cmd -eq "git" }
                 { CheckDependencies } | Should Throw $gitException
            }
        
        }

    }

}
