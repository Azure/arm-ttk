
# Azure Resource Manager Template Toolkit (arm-ttk)

The code in this repository can be used for analyzing and testing [Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/templates/).  The tests will check a template or set of templates for coding best practices.  There are some checks for simple syntactical errors but the intent is not to re-implement tests or checks that are provided by the platform (e.g. the /validate api).  

## Using the TTK
For detailed instruction on how to use the arm-ttk, see this [readme](/arm-ttk/README.md).  More information can be found in the [documentation](http://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/test-toolkit).

## Philosophy

A little bit about the tests...  These are the tests that are used to validate templates for the [Azure QuickStart Repo](https://github.com/Azure/azure-quickstart-templates) and the [Azure Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/).  The purpose is to ensure a standard or consistent set of coding practices to make it easier to develop expertise using the template language (easy to read, write, debug).

As for the type, number and  nature of the tests a test should check for something in the following categories (add more as you think of them :))

- Validating the author's intent (unused parameters or variables)
- Security practices for the language (outputting secrets in plain text)
- Using the appropriate language construct for the task at hand (using environmental functions instead of hard-coding values)

Not everthing is appropriate for a universal set of tests and not every test will apply to every scenario, so the framework allows for easy expansion and individual selection of tests.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
