@{
RootModule = 'PSForge.psm1'
ModuleVersion = '1.2.1'
GUID = '1804f94e-69ec-4f43-ae0c-68c237bc22ff'
Author = 'Edmund Dipple'
CompanyName = 'DevOpsGuys'
Copyright = '(c) 2017 DevOpsGuys. All rights reserved.'
Description = 'Cmdlets to aid in authoring DSC modules and resources'
FunctionsToExport = @(
    'New-DSCModule'
    'New-DSCResource'
    'Export-DSCModule'
    'Test-DSCModule'
    'Get-DSCModuleGlobalConfig'
    'Set-DSCModuleGlobalConfig'
)
CmdletsToExport = '*'
VariablesToExport = '*'
AliasesToExport = '*'
RequiredModules = @(
    @{ModuleName = 'Plaster'; ModuleVersion = '1.1.3'; },
    @{ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.16.1'; }
    @{ModuleName = 'Pester'; ModuleVersion = '4.0.8'; }
)
PrivateData = @{
    PSData = @{
    } # End of PSData hashtable
} # End of PrivateData hashtable
}
