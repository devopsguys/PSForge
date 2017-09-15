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

        It "Should be able to get a variable value from a string" {
            getVariableFromString -Name "PSHOME" | Should be $PSHOME
        }

        It "Should wrap the isOSX variable" {
            Mock getVariableFromString { $False } -ParameterFilter { $Variable -eq "isOSX" }
            isOSX | Should be $False
        }

        It "Should wrap the isLinux variable" {
            Mock getVariableFromString { $False } -ParameterFilter { $Variable -eq "isLinux" }
            isLinux | Should be $False
        }

        It "Should return false on older Powershel" {
            isOsx -Variable "no-variable" | Should be $False
            isLinux -Variable "no-variable" | Should be $False
        }

    }

}