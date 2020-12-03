Writing TTK Unit Tests
=======

Once you write a new TTK test, you'll want to make sure it flags what you'd like to flag.

To do this, we want to write a few unit tests.

Let's take a look at a simple example, a unit test for "Parameters-Must-Be-Referenced".

### Unit Test Structure

Unit Tests for TTK are located in the root of the repository, within [/unit-tests](../unit-tests).

Each TTK rule has a folder for it's unit tests, and 
each folder name within /unit_tests should match the name of a test.  

For example, the rule defined in [/arm_ttk/testcases/deploymentTemplate/Parameters-Must-Be-Referenced.ps1](./testcases/deploymentTemplate/Parameters-Must-Be-Referenced.ps1)
has tests in [/unit_tests/Parameters-Must-Be-Referenced/](../unit-tests/Parameters-Must-Be-Referenced).

Each test folder should have exactly two subfolders and one file:

/Pass
/Fail
/[folder-name].tests.ps1

This file is a boilerplate, and can be copied from directory to directory.  The name of the file must match the pattern above for the folder it's contained in. [See the boilerplate](../unit-tests/Parameters-Must-Be-Referenced/Parameters-Must-Be-Referenced.tests.ps1) 

#### Pass Subfolder

As the name suggests, the Pass subfolder should contain positive test cases.

The TTK rule will run against any .json file within the Pass folder or any subfolder containing templates.
A .txt file within the Pass folder is treated as a pointer to another test file in the case where a test file can be shared with another test. This is commonly used in passing test cases;  most Pass subfolders will ensure that a marketplace sample template will not throw an error.

If a passing case _produces an error_, the test will be marked as a failure.

#### Fail Subfolder

As the name suggests, the Fail subfolder should contain negative test cases.

Once again, the TTK rule will run against any .json files or subfolders containing templates.

If the failure case _does not produce an error_, the test will be marked as a failure.

**Note:** As a best practice a unit test for a negative case, must contain exactly one failure or violation.  This is to ensure that each case is caught independently. 

#### Testing mainTemplate.json or azuredeploy.json

Any test that must be run against the *mainTemplate* of a project may result in the need for more than one file with the same name.  In this case, simply create a subfolder for the test case.
