# CHANGELOG

## 1.2.2

* Fixed compatibility issue with Powershell Core 6.0.0-beta.9

## 1.2.1

* When running Test-DSCModule, don't fetch nuget dependencies and run tests unless the test kitchen action requires them
* Prevented the .git and ruby folders from being included in the nuget package

## 1.2.0

* Added support for PSScriptAnalyzer
* Run unit tests that are stored in  ./DSCResources
* Updated dependencies

## 1.1.0

* Automatically install Ruby on Windows
* Faster module generation
* Use a global Paket installation, rather than bootstrapping a new executable for each project

## 1.0.0

* Initial Release
* Create a skeleton Powershell module or DSC resource
* Run integration tests using Test Kitchen in an Azure environment
* Create an exportable Nuget package
