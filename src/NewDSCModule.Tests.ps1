InModuleScope PSForge {
    Describe "New-DSCModule" {
        Mock Invoke-PlasterWrapper {}
        Mock Push-Location {}
        Mock Pop-Location {}
        Mock New-DSCResource {}
        Mock Get-DSCModuleGlobalConfig {}
        Mock Get-Item {}
        Mock BootstrapDSCModule {}
        

        It "Should fetch the global configuration" {
            New-DSCModule -ModuleName "test"
            Assert-MockCalled Get-DSCModuleGlobalConfig -Exactly 1 -Scope It
        }

        it "Should bootstrap the module dependencies" {
            New-DSCModule -ModuleName "test"
            Assert-MockCalled BootstrapDSCModule -Exactly 1 -Scope It
        }

        It "Should use Plaster to create the file structure" {
            New-DSCModule -ModuleName "test"
            Assert-MockCalled Invoke-PlasterWrapper -Exactly 1 -Scope It
        }

        It "Should create a new resource for each defined in parameters" {
            New-DSCModule -ModuleName "test" -ResourceNames @("a","b","c")            
            Assert-MockCalled New-DscResource -ParameterFilter { $ResourceName -eq "a" } -Exactly 1 -Scope It
            Assert-MockCalled New-DscResource -ParameterFilter { $ResourceName -eq "b" } -Exactly 1 -Scope It
            Assert-MockCalled New-DscResource -ParameterFilter { $ResourceName -eq "c" } -Exactly 1 -Scope It
        }
    }

    Describe "Smoke tests" {
        
        Push-Location $TestDrive

        It 'Should be able to create a module' {
           { New-DSCModule "test-module" } | Should not Throw
           Test-Path $TestDrive\test-module\test-module.psm1 | Should be $True
        }

        Pop-Location

    }

}