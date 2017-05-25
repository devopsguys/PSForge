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
            Mock -ModuleName PSForge -CommandName getEnvironmentOSVersion { @{"Platform" = "Windows" }}
            It "Should detect Windows installation" {
                getOSPlatform | should be "windows"
                isWindows | should be $True
                isUnix | should be $False
            }
        }

        Context "Linux" {
            Mock -ModuleName PSForge -CommandName getEnvironmentOSVersion { @{"Platform" = "Unix" }}
            
            Mock Invoke-Expression { "Linux" } -Verifiable -ParameterFilter {$Command -eq "uname"}
            It "Should detect Linux installation" {
                getOSPlatform | should be "linux"
                isWindows | should be $False
                isUnix | should be $True
                Assert-VerifiableMocks
            }
        }

        Context "MacOS" {
            Mock -ModuleName PSForge -CommandName getEnvironmentOSVersion { @{"Platform" = "Unix" }}
            
            Mock Invoke-Expression { "Darwin" } -Verifiable -ParameterFilter {$Command -eq "uname"}
            It "Should detect Linux installation" {
                getOSPlatform | should be "mac"
                isWindows | should be $False
                isUnix | should be $True
                Assert-VerifiableMocks
            }
        }
           
    }

}
