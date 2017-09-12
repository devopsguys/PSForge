InModuleScope PSForge {

    Describe "Smoke tests" {
        
        $fakeConfigFile = @'
{
"username": "Test User",
"company": "None"
}
'@
        
        Mock Test-Path { $True } -ParameterFilter { $Path -eq "$HOME/DSCWorkflowConfig.json"}
        Mock Get-Content { $fakeConfigFile } -ParameterFilter { $Path -eq "$HOME/DSCWorkflowConfig.json"}

        Push-Location $TestDrive
        New-DSCModule test-module
        Push-Location $TestDrive/test-module
        $modulePath = [io.path]::combine($TestDrive, 'test-module') 

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

        Context "GetProjectRoot" {
            It "Output same folder if you're in root already" {
                getProjectRoot | should be $modulePath
            }

            It "Output correct folder if you're in a subfolder" {
                Push-Location $TestDrive/test-module/DSCResources
                getProjectRoot | should be $modulePath 
                Pop-Location
            }

            It "Throws an exception if you're not in a module folder" {
                Push-Location $TestDrive
                { getProjectRoot } | Should Throw "No .git directory found in"
                Pop-Location
            }

            
        }

        Pop-Location
        Pop-Location

    }
}