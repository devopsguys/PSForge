InModuleScope PSForge {
    Describe "Set-DSCModuleGlobalConfig" {
        Mock Get-DSCModuleGlobalConfig {}
        Mock Out-File {return "I am not Out-File"}
   
        Set-DSCModuleGlobalConfig "a" "b"

        It "Fetches the current config" {
            Assert-MockCalled Get-DSCModuleGlobalConfig -Exactly 1 -Scope Describe
        }
    }
}