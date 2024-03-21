Function Format-Json {
    <#
    .SYNOPSIS
        Takes results from ARMTTK and exports them as a JSON blob.
    .DESCRIPTION
        Takes results from ARMTTK and exports them as JSON. The test cases include the filename, name of the test,
        whether the test was successful, and help text for how to resolve the error if the test failed.
    #>
    [CmdletBinding()]
    Param (
        # Object containing a single test result or an array of test results
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]$TestResult
    )

    Begin {
        # Initialize the array to collect processed test cases
        $TestCases = @()
    }

    Process {
        # Process each TestResult item one by one as they come from the pipeline
        $TestCase = @{
            filepath = $TestResult.file.fullpath
            name = $TestResult.name
            success = $TestResult.Passed
        }

        if ($TestResult.Passed) {
            $TestCase.optional = $false
        }
        elseif ($null -ne $($TestResult.Warnings)) {
            $TestCase.optional = $true
            $TestCase.message = "$($TestResult.Warnings.Message.Replace('"', '\"')) in template file $($TestResult.file.name)"
        }
        elseif ($null -ne $($TestResult.Errors)) {
            $TestCase.optional = $false
            $TestCase.message = "$($TestResult.Errors.Exception.Message.Replace('"', '\"')) in template file $($TestResult.file.name)"
        }
        else {
            $TestCase.optional = $true
            $TestCase.message = "Unknown error in template file " + $TestResult.file.name
        }

        $TestCases += $TestCase
    }

    End {
        # Convert the array of hashtables to JSON
        $JSON = $TestCases | ConvertTo-Json

        # Print the JSON string to the console
        Write-Output $JSON
    }
}