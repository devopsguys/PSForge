# PSForge

*Compatible with Windows, OSX and Linux*

## What is it for?

Our goal is to refactor our monolithic Powershell DSC configurations into a series of smaller, reusable modules that can be tested in isolation. The root configuration for each project should mostly just contain references to custom DSC modules we've created.

In order to achieve this goal, PSForge was created to make it easier to set up a blank module, and resolve dependencies that each module may have - in addition to pulling the custom modules into the root project.

### Setting up a new DSC Module and associated DSC resources

We have a requirement that the modules be tested on environments in Azure with Pester tests, so we needed a way of scaffolding a new DSC module that includes sensible defaults for Test Kitchen configuration files. Under the hood, PSForge makes use of the Plaster project.

### Fetching transitive dependencies for deployment

We needed a way of downloading transitive dependencies (ie. dependencies of dependencies) into a single folder so that the dependencies can be packaged via Nuget. Paket was chosen for this task, as it does an excellent job of handling transitive dependencies.

## How do you use it?

Creating a new module is as simple as running `New-DSCModule` - PSForge will create the module's folder structure for you, as well as the folder structure for any DSC resources that you define in the `-ResourceNames` parameter.

You can create new resources after the initial setup with the `New-DSCResource` command.

Once the module is created, PSForge will bootstrap your development environment by;
* Initialising a local Git repository
* Installing Ruby gem dependencies (for integration testing)
* Installing [Paket](https://fsprojects.github.io/Paket/) within the module root directory

## Installation

1. Clone this repository
2. Install [Ruby 2.3+](https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.4.tar.gz)
3. Install [Plaster](https://github.com/PowerShell/Plasters)
4. Set up your Azure credentials file and Service Principal
3. Run `Import-Module .\PSForge\PSForge.psm1`

In future this installation process will have fewer steps and be set up automatically.

## Integration Testing with Pester

A [Test Kitchen](http://kitchen.ci) configuration file (.kitchen.yml) is placed in the root of the project,
which allows you to test your module on a clean environment in Microsoft Azure.

Running `Test-DSCModule` will use Test Kitchen to create a single Windows server, run the example configuration (Examples\dsc_configuration.ps1) on the server
and execute any [Pester](https://github.com/pester/Pester) tests that you have defined.

If you would prefer to use AWS or any other cloud supported by Test Kitchen, please refer to the Test Kitchen documentation and update `.kitchen.yml` accordingly.

## Dependency Management

PSForge will fetch 3rd party module dependencies for you and place them in the `packages` folder. When running `Test-DSCModule`, [Nuget](https://www.nuget.org/) dependencies that are listed in `dependencies.psm1` will be resolved and downloaded automatically.

Test Kitchen will then upload the `packages` folder and place them onto the `PSModulePath`

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

You will need to complete this step

## Available commands
- `New-DSCModule [-ModuleName] <name> [-ResourceNames <resource1> <resourceN-1>]`
- `New-DSCResource [-ResourceName] <name>`
- `Export-DSCModule -Version <version>`
- `Test-DSCModule [-Action] (create,converge,verify,test,destroy)`
