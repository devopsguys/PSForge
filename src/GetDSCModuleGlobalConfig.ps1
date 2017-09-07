function Get-DSCModuleGlobalConfig
{
    $configFile = "$HOME/DSCWorkflowConfig.json"

    if(-Not (Test-Path $configFile))
    {
        $config = @{}
    }
    else
    {
        $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json
    }

    if(!$config.username)
    {
        $defaultValue = [Environment]::UserName
        $username = Read-Host "What is your username? [$($defaultValue)]"
        $username = ($defaultValue,$username)[[bool]$username]
        Set-DSCModuleGlobalConfig "username" "$username"
        $config["username"] = "$username"
    }

    if(!$config.company)
    {
        $defaultValue = "None"
        $company = Read-Host "What is your company name? [$($defaultValue)]"
        $company = ($defaultValue,$company)[[bool]$company]
        Set-DSCModuleGlobalConfig "company" "$company"
        $config["company"] = "$company"
    }

    return $config

}