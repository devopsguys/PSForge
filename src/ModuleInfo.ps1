
function getProjectRoot
{

    try {
        $relative = Invoke-ExternalCommand "git" @("rev-parse", "--show-cdup")
    }
    catch {
        throw New-Object System.Exception ("No .git directory found in ${PWD} or any of its parent directories.")
    }
    
    if(-not $relative){
        $relative = "."
    }

    return (Get-Item $relative)

}

function GetModuleName{
    return (Get-Item -Path ".\" -Verbose).BaseName
}
function GetModuleManifest
{
    $ModuleName = GetModuleName
    Import-LocalizedData -BaseDirectory "." -FileName "${ModuleName}.psd1" -BindingVariable moduleManifest
    return $moduleManifest
}
function GetDependenciesManifest
{
    Import-LocalizedData -BaseDirectory "." -FileName "dependencies.psd1" -BindingVariable dependenciesManifest
    return $dependenciesManifest
}
