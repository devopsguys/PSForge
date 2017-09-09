InModuleScope PSForge {
    Describe "New-DSCResource" {
        
        $moduleManifest = @{
            "ModuleVersion" = "1.0.0";
            "Author" = "Edmund Dipple";
            "Description" = "Test Module";
        }

        Mock Pop-Location {}
        Mock Push-Location {}
        Mock getProjectRoot {}
        Mock Invoke-PlasterWrapper {}
        Mock BootstrapDSCModule {}
        Mock GetModuleManifest {return $moduleManifest}
        Mock Get-Item {} -ParameterFilter { $Path -like "DSCResources\*"}

        New-DSCResource -ResourceName "test"

        It "Should use Plaster to create the file structure" {
            Assert-MockCalled Invoke-PlasterWrapper -Exactly 1 -Scope Describe
        }

        it "Should bootstrap the module dependencies" {
            Assert-MockCalled BootstrapDSCModule -Exactly 1 -Scope Describe
        }

        it "Should pop after pushing" {
            Assert-MockCalled Push-Location -Exactly 1 -Scope Describe
            Assert-MockCalled Pop-Location -Exactly 1 -Scope Describe
        }
    }

    Describe "Smoke tests" {
        
        Push-Location $TestDrive

        It 'Should be able to create a module' {
           { New-DSCModule "test-module" -ResourceNames "test-resource" } | Should not Throw
           Test-Path $TestDrive\test-module\DSCResources\test-resource\test-resource.psd1 | Should be $True
        }

        Pop-Location

    }
}