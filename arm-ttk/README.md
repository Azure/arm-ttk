# Running Tests

Tests can be run directly in PowerShell, or run from the command line using a wrapper script.

You can run the full suite of tests by using Test-AzTemplate.cmd (on Windows) or Test-AzTemplate.sh (on Linux), and passing in the path to a template.

This will run the full suite of applicable tests on your template.  To run a specific group of tests, use:

    Test-AzTemplate -TemplatePath $thePathToYourTemplate -Test deploymentTemplate 
    # This will run deployment template tests on all appropriate files
    <# There are currently four groups of tests:
        * deploymentTemplate (aka MainTemplateTests)
        * deploymentParameters
        * createUIDefinition
        * all
    #>
    
    Test-AzTemplate -TemplatePath $thePathToYourTemplate -Test "Resources Should Have Location" 
    # This will run the specific test, 'Resources Should have Location', on all appropriate files

    Test-AzTemplate -TemplatePath $thePathToYourTemplate -Test "Resources Should Have Location" -File MyNestedTemplate.json 
    # This will run the specific test, 'Resources Should have Location', but only on MyNestedTemplate.json        

You can also skip tests any tests:

    Test-AzTemplate -TemplatePath $thePathToYourTemplate -Skip apiVersions-Should-Be-Recent 
    # This will exclude the tests indicated by the -Skip parameter from the test run and results    

You can also change the output format to get detailed test result descriptions in JSON:

    Test-AzTemplate -TemplatePath $thePathToYourTemplate | Format-Json
    # This will output the test results from Test-AzTemplate to the console in JSON format
    Test-AzMarketplacePackage -TemplatePath $thePathToYourTemplate | Format-Json
    # This will output the test results from AzMarketplacePackage to the console in JSON format

## Running Tests on Linux

Before you run the tests on Linux, you'll need to [install PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-6).

## Running Tests on macOS

Before you run the tests on macOS, you'll need to [install PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-6) and `coreutils`.

```
brew install coreutils
```

## Running Tests in PowerShell

To run the tests in PowerShell, you'll need to import the module.

    Import-Module .\arm-ttk.psd1 # assuming you're in the same directory as .\arm-ttk.psd1

You can then test a particular path by using:

    Test-AzTemplate -TemplatePath $TemplateFileOrFolder

## Running Tests from the Command Line

You can use a BASH file or Command Script to run on the command line.  To do so, simply call Test-AzTemplate.sh (or .cmd).  This will pass the arguments down to the PowerShell script.  To get help, pass a -?

## Inspecting Test Results

By default, tests are run in Pester, which displays output in a colorized format, but does not return individual failures to the pipeline.  
To inspect the results, assign the results to a variable:

    $TestResults = Test-AzTemplate -TemplatePath $TemplateFileOrFolder

To see each failure in that variable, use Where-Object to filter the results

    $TestFailures =  $TestResults | Where-Object { -not $_.Passed }

Many test failures will return a TargetObject, for instance, the exact property within a template that had an issue.  To extract out target objects from an error, use:

    $FailureTargetObjects = $TestFailures |
        Select-Object -ExpandProperty Errors | 
        Select-Object -ExpandProperty TargetObject

Please note that not all test cases will return a target object.  If no target object is returned, the target should be clear from the text of the error.

## Running Tests in Azure DevOps Pipelines

To run the tests in an Azure DevOps pipeline the tests first need to be installed on the build machine.  Currently this can be done by cloning the repo or downloading from the latest build from [https://aka.ms/arm-ttk-latest](https://aka.ms/arm-ttk-latest) which is the location used by the Azure QuickStarts repo.

There is an extension published in the marketplace for running the TTK in a pipeline, more detail can be found [here](https://marketplace.visualstudio.com/items?itemName=Sam-Cogan.ARMTTKExtension) and the source is in [github](https://github.com/sam-cogan/arm-ttk-extension).

To create your own tasks, see the pipleline we use for the QuickStart repo - the step for downloading the TTK is [here](https://github.com/Azure/azure-quickstart-templates/blob/master/test/pipeline/pipeline.import.fork.json#L136-L160) and running the tests [here](https://github.com/Azure/azure-quickstart-templates/blob/master/test/pipeline/pipeline.import.fork.json#L286-L310).  If these line numbers don't look correct, the file has probably been updated, just [zoom out](https://github.com/Azure/azure-quickstart-templates/blob/master/test/pipeline/pipeline.import.fork.json).
