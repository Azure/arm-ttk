This directory contains cached information about Azure that is available to all tests.

Files in this directory should match two patterns:

1. *.cache.json     - These files contain cached data in unminified JSON.
2. *.init.cache.ps1 - These files refresh a .cache.json file.

For example, AllResources.cache.json is created with AllResources.init.cache.json.

To use this cache within TTK /testcases, add a parameter $AllResources.  The test for [ApiVersions-Should-Be-Recent](../testcases/deploymentTemplate/apiVersions-Should-Be-Recent.test.ps1) contains an example.

You can use Update-TTKCache to run all *.init.cache.ps1 files within the directory.
