InModuleScope PSForge {
    Describe "Get-DSCModuleGlobalConfig" {
        
        Mock Set-DSCModuleGlobalConfig {}
        Mock Test-Path { $False }

        Context "No configuration available" {

            It "Should set username to new value if missing" {
                Mock Read-Host { "test_username"}
                Get-DSCModuleGlobalConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "username" -and $Value -eq "test_username" }  -Exactly 1 -Scope It
            }
    
            It "Should set username to default value if value not provided" {
                Mock Read-Host {}
                Get-DSCModuleGlobalConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "username" -and $Value -eq [Environment]::UserName }  -Exactly 1 -Scope It
            }
    
            It "Should set company if missing" {
                Mock Read-Host { "test_company"}
                Get-DSCModuleGlobalConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "company" -and $Value -eq "test_company" }  -Exactly 1 -Scope It
            }
    
            It "Should set company to default value if value not provided" {
                Mock Read-Host {}
                Get-DSCModuleGlobalConfig
                Assert-MockCalled Set-DSCModuleGlobalConfig -ParameterFilter { $Key -eq "company" -and $Value -eq "None" }  -Exactly 1 -Scope It
            }

        }

        Context "Configuration already set up" {

            Mock Get-Content { '{"username":"test_username","company":"test_company"}' }

            It "Should not prompt for information it already has" {
                Assert-MockCalled Set-DSCModuleGlobalConfig -Exactly 0
            }

        }
        
    }
}