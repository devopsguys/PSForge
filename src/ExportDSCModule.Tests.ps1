InModuleScope PSForge {
    Describe "Export-DSCModule" {

        . $PSScriptRoot\PesterHelpers.ps1

        $version = "1.0.0"
        Mock getProjectRoot {return "a" }
        Mock Push-Location {} -ParameterFilter { $path -eq "a" } -Verifiable
        Mock Pop-Location {} -Verifiable
        Mock BootstrapDSCModule {} -Verifiable
        Mock Invoke-Paket {} -ParameterFilter { $args -eq "update" } -Verifiable
        Mock Invoke-Paket {} -ParameterFilter { Compare-Array $args @("pack", "output", ".\output", "version", $version) } -Verifiable

        Export-DSCModule $version
        It "Should update dependencies and export a nuget package" {
            Assert-VerifiableMocks
        }
       
    } 
}