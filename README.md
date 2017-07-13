# PSForge

*Compatible with Windows, OSX and Linux*

## Installing a release

1. Run the powershell command `Install-Module PSForge`
2. [Set up your Azure credentials file and Service Principal](https://github.com/test-kitchen/kitchen-azurerm)

## What is it for?

PSForge was created to help refactor a monolithic Powershell DSC configuration into a set of small reusable modules that can be tested in isolation. The original project can then pull in these modules as dependencies.

PSForge orchestrates different tasks involved in creating a module, including;

* Scaffolding a new Powershell DSC module and resources
* Downloading dependencies to a local folder
* Testing the module on a VM in Azure
* Exporting the module as a nuget package

## How do I create a module?

Creating a new module is as simple as running `New-DSCModule` - PSForge will create the module's folder structure for you, as well as the folder structure for any DSC resources that you define in the `-ResourceNames` parameter.

You can create new resources after the initial setup with the `New-DSCResource` command. 


## Integration Testing with Pester

A [Test Kitchen](http://kitchen.ci) configuration file (.kitchen.yml) is placed in the root of the project,
which allows you to test your module on a clean environment in Microsoft Azure.

Running `Test-DSCModule` will use Test Kitchen to create a single Windows server, run the example configuration (Examples\dsc_configuration.ps1) on the server
and execute any [Pester](https://github.com/pester/Pester) tests that you have defined.

If you would prefer to use AWS or any other cloud supported by Test Kitchen, please refer to the Test Kitchen documentation and update `.kitchen.yml` accordingly.

## Dependency Management

PSForge will fetch 3rd party module dependencies for you and place them in the `packages` folder. When running `Test-DSCModule`, [Nuget](https://www.nuget.org/) dependencies that are listed in `dependencies.psm1` will be resolved and downloaded automatically.

Test Kitchen will then upload the `packages` folder and place them onto the `PSModulePath` of the VM.

`dependencies.psm1` contains the list of Nuget packages that the DSC module relies upon to run, and the list of Nuget feeds that hosts those packages.

A typical `dependencies.psm1` may look like this;

```
@{

NugetFeeds = @(
    "http://nuget.org/api/v2"
    "http://powershellgallery.com/api/v2"
)

NugetPackages = @(
    "xPSDesiredStateConfiguration == 6.0.0.0"
)

}
```

## Exporting a Package

Once a module has been written and tested, you may want to export it as a Nuget package, for consumption by another module.

`Export-DSCModule` will create a Nuget package that contains your module, resources and references to dependencies. You can then upload the package to [PSGallery](https://www.powershellgallery.com/) or your own Nuget feed

## Azure credentials

Please refer to the documentation for [kitchen-azurerm](https://github.com/test-kitchen/kitchen-azurerm) for instructions on how to set up a Service Principal and the local `${env:HOME}\.azure\credentials` configuration file.

You will need to complete this step in order to run integration tests.

## Available commands
- `New-DSCModule [-ModuleName] <name> [-ResourceNames <resource1> <resourceN-1>]`
- `New-DSCResource [-ResourceName] <name>`
- `Export-DSCModule -Version <version>`
- `Test-DSCModule [-Action] (create,converge,verify,test,destroy)`


## Manual Installation

1. Clone this repository
2. Set up your Azure credentials file and Service Principal
3. Run `Import-Module .\PSForge\PSForge.psm1`
