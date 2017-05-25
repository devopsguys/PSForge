configuration default
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    Import-Module <%=${PLASTER_PARAM_project_name}%>
    Import-DSCResource -ModuleName <%=${PLASTER_PARAM_project_name}%>

    Node $NodeName
    {

        $moduleRoot = [io.path]::GetDirectoryName((Get-Module <%=${PLASTER_PARAM_project_name}%>).Path)
        $examples = "$moduleRoot\Examples"

        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

    }
}
