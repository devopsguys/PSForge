$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")


InModuleScope PSForge {

    Describe "GetPSForgeModuleRoot" {
        
        It "Should be able to work out the module root" {
            (Get-Module PSForge).ModuleBase | Should be (GetPSForgeModuleRoot)
        }

    }

}
