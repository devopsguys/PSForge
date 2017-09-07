InModuleScope PSForge {
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

}