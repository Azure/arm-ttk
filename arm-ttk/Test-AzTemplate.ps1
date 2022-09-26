function Test-AzTemplate
{
    [Alias('Test-AzureRMTemplate')] # Added for backward compat with MP
    <#
    .Synopsis
Tests an Azure Resource Manager Template
    .Description
Validates one or more Azure Resource Manager Templates.
    .Notes
Test-AzTemplate validates an Azure Resource Manager template using a number of small test scripts.

Test scripts can be found in /testcases/GroupName, or provided with the -TestScript parameter.

Each test script has access to a set of well-known variables:

* TemplateFullPath (The full path to the template file)
* TemplateFileName (The name of the template file)
* TemplateText (The template text)
* TemplateObject (The template object)
* FolderName (The name of the directory containing the template file)
* FolderFiles (a hashtable of each file in the folder)
* IsMainTemplate (a boolean indicating if the template file name is mainTemplate.json)
* CreateUIDefintionFullPath (the full path to createUIDefintion.json)
* CreateUIDefinitionText (the text of createUIDefintion.json)
* CreateUIDefinitionObject ( the createUIDefintion object)
* HasCreateUIDefintion (a boolean indicating if the directory includes createUIDefintion.json)
* MainTemplateText (the text of the main template file)
* MainTemplateObject (the main template file, converted from JSON)
* MainTemplateResources (the resources and child resources of the main template)
* MainTemplateParameters (a hashtable containing the parameters found in the main template)
* MainTemplateVariables (a hashtable containing the variables found in the main template)
* MainTemplateOutputs (a hashtable containing the outputs found in the main template)
* InnerTemplates (indicates if the template contained or was in inner templates)
* IsInnerTemplate (indicates if currently testing an inner template)
* ExpandedTemplateText (the text of a template, with variables expanded)
* ExpandedTemplateOjbect (the object of a template, with variables expanded)

    .Example
        Test-AzTemplate -TemplatePath ./FolderWithATemplate
        # Tests all files in /FolderWithATemplate
    .Example
        Test-AzTemplate -TemplatePath ./Templates/NameOfTemplate.json
        # Tests the file at the location ./Templates/NameOfTemplate.json.
    .Example
        Test-AzTemplate -TemplatePath ./FolderWithATemplate -Test 'DeploymentTemplate-Schema-Is-Correct' 
        # Runs the test 'DeploymentTemplate-Schema-Is-Correct' on all files in the folder /FolderWithATemplate
    .Example
        Test-AzTemplate -TemplatePath ./FolderWithATemplate -Skip 'DeploymentTemplate-Schema-Is-Correct'
        # Skips the test 'DeploymentTemplate-Schema-Is-Correct'
    .Example
        Test-AzTemplate -TemplatePath ./FolderWithATemplate -SkipByFile @{
            '*azureDeploy*' = '*apiVersions*'
            '*' = '*schema*'
        }
        # Skips tests named like *apiversions* on files with the text "azureDeploy" in the filename, and skips with the text "schema" in the test name for all files.
    .Example
        Test-AzTemplate -TemplatePath ./FolderWithATemplate | Export-Clixml ./Results.clixml
        # Tests all template files in ./FolderWithATemplate, and exports their results to clixml.
    .Example
        Test-AzTemplate -TemplatePath ./DirectoryWithTemplates -GroupName AllFiles
        # Runs all tests included in the group "AllFiles" on all the files located in ./DirectoryWithTemplates
    
    #>
    [CmdletBinding(DefaultParameterSetName='NearbyTemplate')]
    param(
    # The path to an Azure resource manager template
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='SpecificTemplate')]
    [Alias('Fullname','Path')]
    [string]
    $TemplatePath,

    # One or more test cases or groups.  If this parameter is provided, only those test cases and groups will be run.
    [Parameter(Position=1)]
    [Alias('Tests')]
    [string[]]
    $Test,

    # If provided, will only validate files in the template directory matching one of these wildcards.
    [Parameter(Position=2)]
    [Alias('Files')]
    [string[]]
    $File,

    # A set of test cases.  If not provided, the files in /testcases will be used as input.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        foreach ($k in $_.Keys) {
            if ($k -isnot [string]) {
                throw "All keys must be strings"
            }
        }
        foreach ($v in $_.Values) {
            if ($v -isnot [ScriptBlock] -and $v -isnot [string]) {
                throw "All values must be script blocks or strings"
            }
        }
        return $true
    })]
    [Alias('TestCases')]
    [Collections.IDictionary]
    $TestCase = [Ordered]@{},

    # A set of test groups.  Test groups will be automatically populated by the directory names in /testcases.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        foreach ($k in $_.Keys) {
            if ($k -isnot [string]) {
                throw "All keys must be strings"
            }
        }
        foreach ($v in $_.Values) {
            if ($v -isnot [string]) {
                throw "All values must be strings"
            }
        }
        return $true
    })]
    [Collections.IDictionary]
    [Alias('TestGroups')]
    $TestGroup = [Ordered]@{},


    # The name of one or more test groups.  This will run tests only from this group.
    # Built-in valid groups are:  All, MainTemplateTests, DeploymentTemplate, DeploymentParameters, CreateUIDefinition.    
    [string[]]
    $GroupName,

    # Any additional parameters to pass to each test.
    # This can be used to supply custom information to validate.
    # For example, passing -TestParameter @{testDate=[DateTime]::Now.AddYears(-1)} 
    # will pass a a custom value to any test with the parameter $TestDate.
    # If the parameter does not exist for a given test case, it will be ignored.
    [Collections.IDictionary]
    [Alias('TestParameters')]
    $TestParameter,    

    # If provided, will skip any tests in this list.
    [string[]]
    $Skip,

    # If provided, will skip tests on a file-by-file basis.
    # The key of this dictionary is a wildcard on a filename.
    # The value of this dictionary is a list of wildcards to exclude.
    [Collections.IDictionary]
    $SkipByFile,

    # If provided, will use this file as the "main" template.
    [string]
    $MainTemplateFile,

    # If set, will run tests in Pester.
    [switch]
    $Pester)

    begin {
        
        # First off, let's get all of the built-in test scripts.
        $testCaseSubdirectory = 'testcases'
        $myLocation =  $MyInvocation.MyCommand.ScriptBlock.File
        $myModule   = $myInvocation.MyCommand.ScriptBlock.Module
        $testScripts= @($myLocation| # To do that, we start from the current file,
            Split-Path | # get the current directory,
            Get-ChildItem -Filter $testCaseSubdirectory | # get the cases directory,
            Get-ChildItem -Filter *.test.ps1 -Recurse)  # and get all test.ps1 files within it.


        $builtInTestCases = @{}
        $script:PassFailTotalPerRun = @{Pass=0;Fail=0;Total=0}
        # Next we'll define some human-friendly built-in groups.
        $builtInGroups = @{
            'all' = 'deploymentTemplate', 'createUIDefinition', 'deploymentParameters'
            'mainTemplateTests' = 'deploymentTemplate', 'deploymentParameters'
        }


        # Now we loop over each potential test script
        foreach ($testScript  in $testScripts) {
            # The test file name (minus .test.ps1) becomes the name of the test.
            $TestName = $testScript.Name -ireplace '\.test\.ps1$', '' -replace '_', ' ' -replace '-', ' '
            $testDirName = $testScript.Directory.Name
            if ($testDirName -ne $testCaseSubdirectory) { # If the test case was in a subdirectory
                if (-not $builtInGroups.$testDirName) {
                    $builtInGroups.$testDirName = @()
                }
                # then the subdirectory name is the name of the test group.
                $builtInGroups.$testDirName += $TestName
            } else {
                # If there was no subdirectory, put the test in a special group called "ungrouped".
                if (-not $builtInGroups.Ungrouped) {
                    $builtInGroups.Ungrouped = @()
                }
                $builtInGroups.Ungrouped += $TestName
            }
            $builtInTestCases[$testName] = $testScript.Fullname
        }

        # This lets our built-in groups be automatically defined by their file structure.

        if (-not $script:AlreadyLoadedCache) { $script:AlreadyLoadedCache = @{} }
        # Next we want to load the cached items
        $cacheDir = $myLocation | Split-Path | Join-Path -ChildPath cache
        $cacheItemNames = @(foreach ($cacheFile in (Get-ChildItem -Path $cacheDir -Filter *.cache.json)) {
            $cacheName = $cacheFile.Name -replace '\.cache\.json', ''
            if (-not $script:AlreadyLoadedCache[$cacheFile.Name]) {
                $script:AlreadyLoadedCache[$cacheFile.Name] =
                    [IO.File]::ReadAllText($cacheFile.Fullname) | Microsoft.PowerShell.Utility\ConvertFrom-Json

            }
            $cacheData = $script:AlreadyLoadedCache[$cacheFile.Name]
            $ExecutionContext.SessionState.PSVariable.Set($cacheName, $cacheData)
            $cacheName
        })


        # Next we want to declare some internal functions:
        
        #*Test-Case (executes a test, given a set of parameters)
        function Test-Case($TheTest, $TestParameters = @{}) {
            $testCommandParameters =
                if ($TheTest -is [ScriptBlock]) {
                    $function:f = $TheTest
                    ([Management.Automation.CommandMetaData]$function:f).Parameters
                    Remove-Item function:f
                } elseif ($TheTest -is [string]) {
                    $testCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand($TheTest, 'ExternalScript')
                    if (-not $testCmd) { return }
                    ([Management.Automation.CommandMetaData]$testCmd).Parameters
                } else {
                    return
                }

            $parentTemplateText = $testInput.TemplateText
            $testInput = @{IsInnerTemplate=$false} + $TestParameters
            $IsInnerTemplate = $false

            foreach ($k in @($testInput.Keys)) {
                if (-not $testCommandParameters.ContainsKey($k)) {
                    $testInput.Remove($k)
                }
            }

            :IfNotMissingMandatory do {
                foreach ($tcp in $testCommandParameters.GetEnumerator()) {
                    foreach ($attr in $tcp.Value.Attributes) {
                        if ($attr.Mandatory -and -not $testInput[$tcp.Key]) {
                            Write-Warning "Skipped because $($tcp.Key) was missing"
                            break IfNotMissingMandatory
                        }
                    }
                }

                if (-not $Pester) {
                    . $myModule $TheTest @testInput 2>&1 3>&1
                } else {
                    . $myModule $TheTest @testInput
                }

                if ($TestParameters.InnerTemplates.Count) { # If an ARM template has inner templates                    
                    $isInnerTemplate = $testInput['IsInnerTemplate'] = $true
                    if (-not $testCommandParameters.ContainsKey('IsInnerTemplate')) {
                        $testInput.Remove('IsInnerTemplate')
                    }
                    $innerTemplateNumber = 0
                    foreach ($innerTemplate in $testParameters.InnerTemplates) {
                        
                        $usedParameters = $false
                        # Map TemplateText to the inner template text by converting to JSON (if the test command uses -TemplateText)
                        if ($testCommandParameters.ContainsKey("TemplateText")) { 
                            $templateText   = $testInput['TemplateText']   = $TestParameters.InnerTemplatesText[$innerTemplateNumber]
                            $usedParameters = $true
                        }
                        # And Map TemplateObject to the converted json (if the test command uses -TemplateObject)
                        if ($testCommandParameters.ContainsKey("TemplateObject")) { 
                            $templateObject = $testInput['TemplateObject'] = $innerTemplate.template                            
                            $usedParameters = $true
                        }

                        if ($usedParameters) {
                            if (-not $Pester) {
                                $itn = 
                                    if ($TestParameters.InnerTemplatesNames) {
                                        $TestParameters.InnerTemplatesNames[$innerTemplateNumber]
                                    } else { ''}
                                
                                $itl =
                                    if ($TestParameters.InnerTemplatesLocations){
                                        $testParameters.InnerTemplatesLocations[$innerTemplateNumber]
                                    } else { '' }
                                . $myModule $TheTest @testInput 2>&1 3>&1 | # Run the test, and add data about the inner template context it was in.
                                    Add-Member NoteProperty InnerTemplateName $itn -Force -PassThru |
                                    Add-Member NoteProperty InnerTemplateStart $itl.index -Force -PassThru |
                                    Add-Member NoteProperty InnerTemplateLocation $itl  -Force -PassThru |
                                    Add-Member NoteProperty InnerTemplateInput (@{} + $testInput) -Force -PassThru |
                                    Add-Member NoteProperty InnerTemplateText $templateText -Force -PassThru
                            } else {
                                . $myModule $TheTest @testInput
                            }           
                        }
                        $innerTemplateNumber++
                    }
                }
            } while ($false)
        }

        #*Test-Group (executes a group of tests)
        function Test-Group {            
            $testQueue = [Collections.Queue]::new(@($GroupName))
            :nextTestInGroup while ($testQueue.Count) {
                $dq = $testQueue.Dequeue()
                if ($TestGroup.$dq) {
                    foreach ($_ in $TestGroup.$dq) {
                        $testQueue.Enqueue($_)
                    }
                    continue
                }

                if ($ValidTestList -and $ValidTestList -notcontains $dq) {
                    continue
                }

                if ($SkipByFile) {
                    foreach ($sbp in $SkipByFile.GetEnumerator()) {
                        if ($fileInfo.Name -notlike $sbp.Key) { continue }
                        foreach ($v in $sbp.Value) {
                            if ($dq -like $v) { continue nextTestInGroup }
                        }
                    }                    
                }

                if (-not $Pester) {
                    $testStartedAt = [DateTime]::Now
                    $testCaseOutput = Test-Case $testCase.$dq $TestInput 2>&1 3>&1
                    $testTook = [DateTime]::Now - $testStartedAt

                                        
                    $InnerTemplateStartLine = 0
                    $InnerTemplateEndLine   = 0
                    
                    $outputByInnerTemplate = $testCaseOutput | 
                        Group-Object InnerTemplateName | 
                        Sort-Object { $($_.Group.InnerTemplateStart) }
                    if (-not $outputByInnerTemplate) {
                        # If there's no output, the test has passed.
                        $script:PassFailTotalPerRun.Total++ # update the totals
                        $script:PassFailTotalPerRun.Pass++
                        [PSCustomObject][Ordered]@{         # And output the object
                            pstypename = 'Template.Validation.Test.Result'
                            Errors = @()
                            Warnings = @()
                            Output = @()
                            AllOutput = $testCaseOutput
                            Passed = $true
                            Group = $dq                        
                            Name = $dq
                            Timespan = $testTook
                            File = $fileInfo
                            TestInput = @{} + $TestInput
                            Summary = if ($isLastFile -and -not $testQueue.Count) {
                                [PSCustomObject]$script:PassFailTotalPerRun    
                            }
                        }
                        continue nextTestInGroup
                    }
                    foreach ($testOutputGroup in $outputByInnerTemplate) {
                        $testErrors = [Collections.ArrayList]::new()
                        $testWarnings = [Collections.ArrayList]::new()
                        $testOutput = [Collections.ArrayList]::new()

                        $innerGroup = 
                            if ($testOutputGroup.Group.InnerTemplateStart) {
                                $innerTemplateStartIndex = ($($testOutputGroup.Group | Where-Object InnerTemplateStart | Select-Object -First 1).InnerTemplateStart) -as [int]
                                $innerTemplateLength     = ($($testOutputGroup.Group | Where-Object InnerTemplateEnd | Select-Object -First 1).InnerTemplateLength) -as [int]
                                    try {
                                        $InnerTemplateStartLine = 
                                                [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Matches(
                                                    $parentTemplateText, $innerTemplateStartIndex
                                                ).Count
                                        $InnerTemplateEndLine = 
                                                $InnerTemplateStartLine - 1 + [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Matches(
                                                    $testInput.TemplateText, $testInput.TemplateText.Length - 1
                                                ).Count
                                    } catch {
                                        $ex = $_
                                        Write-Error "Error Isolating Nested Template Lines in $templateFileName " -TargetObject $ex
                                    }
                                " NestedTemplate $($testOutputGroup.Name) [ Lines $InnerTemplateStartLine - $InnerTemplateEndLine ]"
                            } else {''}
                        $displayGroup = if ($innerGroup) { $innerGroup } else { $dq }
                        $null= foreach ($testOut in $testOutputGroup.Group) {
                            if ($testOut -is [Exception] -or $testOut -is [Management.Automation.ErrorRecord]) {
                                $testErrors.Add($testOut)
                                if ($testOut.TargetObject -is [Text.RegularExpressions.Match]) {
                                    $wholeText = $testOut.TargetObject.Result('$_')
                                    $lineNumber = 
                                        [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Matches(
                                            $wholeText, $testOut.TargetObject.Index
                                        ).Count + $(if ($InnerTemplateStartLine) { $InnerTemplateStartLine - 1 })

                                    $columnNumber = 
                                        $testOut.TargetObject.Index -
                                        $(
                                            $m = [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Match(
                                                $wholeText, $testOut.TargetObject.Index)
                                            $m.Index + $m.Length
                                        ) + 1
                                    $testOut | Add-Member NoteProperty Location ([PSCustomObject]@{Line=$lineNumber;Column=$columnNumber;Index=$testOut.TargetObject.Index;Length=$testOut.TargetObject.Length}) -Force
                                }
                                elseif ($testOut.TargetObject.PSTypeName -eq 'JSON.Content' -or $testOut.TargetObject.JSONPath) {
                                    $jsonPath = "$($testOut.TargetObject.JSONPath)".Trim()
                                    $location = 
                                        if ($GroupName -eq 'CreateUIDefinition') {                                                         
                                            Resolve-JSONContent -JSONPath $jsonPath -JSONText $createUIDefinitionText
                                        } elseif ($GroupName -eq 'DeploymentParameters') {
                                            Resolve-JSONContent -JSONPath $jsonPath -JSONText $parameterText
                                        } elseif ($testOut.InnerTemplateLocation) {                                            
                                            Resolve-JSONContent -JSONPath $jsonPath -JSONText $testOut.InnerTemplateText                                            
                                        } else {
                                            $resolvedLocation = Resolve-JSONContent -JSONPath $jsonPath -JSONText $TemplateText
                                            if (-not $resolvedLocation) {
                                                Write-Verbose "Unable to Resolve location in $($jsonPath) in $($fileInfo.Name)"
                                            } else {
                                                $resolvedLocation.Line += $(if ($InnerTemplateStartLine) { $InnerTemplateStartLine - 1 })
                                                $resolvedLocation
                                            }
                                        }

                                    if ($testOut.InnerTemplateLocation -and $location) {
                                        $location.Line += $testOut.InnerTemplateLocation.Line - 1
                                    }

                                    if ($location) {
                                        $testOut | Add-Member NoteProperty Location $location -Force
                                    }
                                }
                            }
                            elseif ($testOut -is [Management.Automation.WarningRecord]) {
                                $testWarnings.Add($testOut)
                            } else {
                                $testOutput.Add($testOut)
                            }
                        }
                    
                        $script:PassFailTotalPerRun.Total++
                        if ($testErrors.Count -lt 1) {
                            $script:PassFailTotalPerRun.Pass++
                        } else {
                            $script:PassFailTotalPerRun.Fail++
                        }

                        [PSCustomObject][Ordered]@{
                            pstypename = 'Template.Validation.Test.Result'
                            Errors = $testErrors
                            Warnings = $testWarnings
                            Output = $testOutput
                            AllOutput = $testOutputGroup.Group
                            Passed = $testErrors.Count -lt 1
                            Group = $displayGroup
                        
                            Name = $dq
                            Timespan = $testTook
                            File = $fileInfo
                            TestInput = @{} + $TestInput
                            Summary = if ($isLastFile -and -not $testQueue.Count) {
                                [PSCustomObject]$script:PassFailTotalPerRun    
                            }
                        }
                    }
                    

                    
                } else {
                    it $dq {
                        # Pester tests only fail on a terminating error,
                        $errorMessages = Test-Case $testCase.$dq $TestInput 2>&1 |
                            Where-Object { $_ -is [Management.Automation.ErrorRecord] } |
                            # so collect all non-terminating errors.
                            Select-Object -ExpandProperty Exception |
                            Select-Object -ExpandProperty Message

                        if ($errorMessages) { # If any were found,
                            throw ($errorMessages -join ([Environment]::NewLine)) # throw.
                        }
                    }
                }
            }
        }

        #*Test-FileList (tests a list of files)
        function Test-FileList {
            $lastFile = $FolderFiles[-1]
            $isFirstFile = $true                        
            $mainInnerTemplates = $InnerTemplates
            $mainInnerTemplatesText = $InnerTemplatesText
            $MainInnerTemplatesNames = $InnerTemplatesNames
            $MainInnerTemplatesLocations = $innerTemplatesLocations
            foreach ($fileInfo in $FolderFiles) { # We loop over each file in the folder.
                $isLastFile = $fileInfo -eq $lastFile
                $matchingGroups =
                    @(if ($fileInfo.Schema) { # If a given file has a schema,
                        if ($isFirstFile) {   # see if it's the first file.
                            'AllFiles'        # If it is, add it to the group 'AllFiles'.
                            $isFirstFile = $false
                        }
                        
                        foreach ($key in $TestGroup.Keys) { # Then see if the schema matches the name of the testgroup
                            if ("$key".StartsWith("_") -or "$key".StartsWith('.')) { continue }
                            if ($fileInfo.Schema -match $key) {
                                $key # then run that group of tests.
                            }
                        }
                        
                    } else {
                        foreach ($key in $TestGroup.Keys) { # If it didn't have a schema
                            if ($key -eq 'AllFiles') {
                                $key; continue
                            }
                            if ($fileInfo.Extension -eq '.json') { # and it was a JSON file
                                $fn = $fileInfo.Name -ireplace '\.json$',''
                                if ($fn -match $key) { # check to see if it's name matches the key
                                    $key; continue # (this handles CreateUIDefinition.json, even if no schema is present).
                                }
                                if ($key -eq 'DeploymentParameters' -and # checking the deploymentParamters and file pattern
                                   $fn -like '*.parameters') { # and the file name is something we _know_ will be an ARM parameters template
                                   $key; continue # then run the deployment tests regardless of schema.
                                }
                                if ($key -eq 'DeploymentTemplate' -and # Otherwise, if we're checking the deploymentTemplate
                                    'maintemplate', 'azuredeploy', 'prereq.azuredeploy' -contains $fn) { # and the file name is something we _know_ will be an ARM template
                                    $key; continue # then run the deployment tests regardless of schema.
                                } elseif (
                                    $key -eq 'DeploymentTemplate' -and # Otherwise, if we're checking for the deploymentTemplate
                                    $fileInfo.Object.resources # and the file has a .resources property.                                    
                                ) {
                                    Write-Warning "File '$($fileInfo.Name)' has no schema, but has .resources.  Treating as a DeploymentTemplate."
                                    $key; continue # then run the deployment tests regardless of schema.
                                }                                
                            }
                            if (-not ("$key".StartsWith('_') -or "$key".StartsWith('.'))) { continue } # Last, check if the test group is for a file extension.
                            if ($fileInfo.Extension -eq "$key".Replace('_', '.')) { # If it was, run tests associated with that extension.
                                $key
                            }
                        }
                    })

                if ($TestGroup.Ungrouped) {
                    $matchingGroups += 'Ungrouped'
                }

                if (-not $matchingGroups) { continue }

                if ($fileInfo.Schema -like '*deploymentParameters*' -or $fileInfo.Name -like '*.parameters.json') { #  
                    $isMainTemplateParameter = 'maintemplate.parameters.json', 'azuredeploy.parameters.json', 'prereq.azuredeploy.parameters.json' -contains $fileInfo.Name
                    $parameterFileName = $fileInfo.Name
                    $parameterObject = $fileInfo.Object
                    $parameterText = $fileInfo.Text
                }
                if ($fileInfo.Schema -like '*deploymentTemplate*') {
                    $isMainTemplate = 
                        if ($MainTemplateFile) {
                            $(
                                $MainTemplateFile -eq $fileInfo.Name -or
                                $MainTemplateFile -eq $fileInfo.Fullname
                            )
                        } else {
                            'mainTemplate.json', 'azureDeploy.json', 'prereq.azuredeploy.json' -contains $fileInfo.Name
                        }
                        
                    $templateFileName = $fileInfo.Name                    
                    $TemplateObject = $fileInfo.Object
                    $TemplateText = $fileInfo.Text
                    # If the file had inner templates
                    if ($fileInfo.InnerTemplates) {
                        # use the inner templates from just this file
                        $InnerTemplates          = $fileInfo.InnerTemplates
                        $InnerTemplatesText      = $fileInfo.InnerTemplatesText
                        $InnerTemplatesNames     = $fileInfo.InnerTemplatesNames
                        $innerTemplatesLocations = $fileInfo.InnerTemplatesLocations
                    }
                    elseif ($fileInfo.Name -match '^(?>parameters|prereq|CreateUIDefinition)\.') {
                        $InnerTemplates, $InnerTemplateText, $InnerTemplatesNames, $innerTemplatesLocations = $null                         
                    }
                    else 
                    {
                        # Otherwise, use the inner templates from the main file
                        $InnerTemplates = $mainInnerTemplates
                        $InnerTemplatesText = $mainInnerTemplatesText
                        $InnerTemplatesNames = $MainInnerTemplatesNames
                        $innerTemplatesLocations = $MainInnerTemplatesLocations
                    }
                    if ($InnerTemplates.Count) {
                        $anyProblems = $false
                            foreach ($it in $innerTemplates) {
                                $foundInnerTemplate = $it | Resolve-JSONContent -JsonText $TemplateText
                                if (-not $foundInnerTemplate) { $anyProblems = $true; break }
                                $TemplateText = $TemplateText.Remove($foundInnerTemplate.Index, $foundInnerTemplate.Length)
                                $TemplateText = $TemplateText.Insert($foundInnerTemplate.Index, '"template": {}')
                            }

                            if (-not $anyProblems) {
                                $TemplateObject = $TemplateText | ConvertFrom-Json
                            } else {
                                Write-Error "Could not extract inner templates for '$TemplatePath'." -ErrorId InnerTemplate.Extraction.Error
                            }
                    }
                }
                foreach ($groupName in $matchingGroups) {
                    $testInput = @{}
                    foreach ($_ in $WellKnownVariables) {
                        $testInput[$_] = $ExecutionContext.SessionState.PSVariable.Get($_).Value
                    }
                    $ValidTestList = 
                        if ($test) {
                            $testList = @(Get-TestGroups ($test -replace '[_-]',' ') -includeTest)
                            if (-not $testList) {
                                Write-Warning "Test '$test' was not found, all tests will be run"
                            }
                            if ($skip) {
                                foreach ($tl in $testList) {
                                    if ($skip -replace '[_-]', ' ' -notcontains $tl) {
                                        $tl
                                    }
                                }
                            } 
                            else {
                                $testList
                            }
                        } elseif ($skip) {
                            $testList = @(Get-TestGroups -GroupName $groupName -includeTest)
                            foreach ($tl in $testList) {
                                if ($skip -replace '[_-]', ' ' -notcontains $tl) {
                                    $tl
                                }
                            }
                        } else {
                            $null
                        }

                    
                    if (-not $Pester) {
                        $context = "$($fileInfo.Name)->$groupName"
                        Test-Group
                    } else {
                        context "$($fileInfo.Name)->$groupName" ${function:Test-Group}
                    }
                }
            }

        }

        #*Get-TestGroups (expands nested test groups)
        function Get-TestGroups([string[]]$GroupName, [switch]$includeTest) {
            foreach ($gn in $GroupName) {
                if ($TestGroup[$gn]) {
                    Get-TestGroups $testGroup[$gn] -includeTest:$includeTest
                } elseif ($IncludeTest -and $TestCase[$gn]) {
                    $gn
                }
            }
        }

        $accumulatedTemplates = [Collections.Arraylist]::new()
    }

    process {
        # If no template was passed,
        if ($PSCmdlet.ParameterSetName -eq 'NearbyTemplate') {
            # attempt to find one in the current directory and it's subdirectories
            $possibleJsonFiles = @(Get-ChildItem -Filter *.json -Recurse |
                Sort-Object Name -Descending | # (sort by name descending so that MainTemplate.json comes first).
                Where-Object {
                    'azureDeploy.json', 'mainTemplate.json' -contains $_.Name
                })


            # If more than one template was found, warn which one we'll be testing.
            if ($possibleJsonFiles.Count -gt 1) {
                Write-Error "More than one potential template file found beneath '$pwd'.  Please have only azureDeploy.json or mainTemplate.json, not both."
                return
            }


            # If no potential files were found, write and error and return.
            if (-not $possibleJsonFiles) {
                Write-Error "No potential templates found beneath '$pwd'.  Templates should be named azureDeploy.json or mainTemplate.json."
                return
            }


            # If we could find a potential json file, recursively call yourself.
            $possibleJsonFiles |
                Select-Object -First 1 |
                Test-AzTemplate @PSBoundParameters

            return
        }

        # First, merge the built-in groups and test cases with any supplied by the user.
        foreach ($kv in $builtInGroups.GetEnumerator()) {
            if ($GroupName -and $GroupName -notcontains $kv.Key) { continue }
            if (-not $testGroup[$kv.Key]) {
                $TestGroup[$kv.Key] = $kv.Value
            }
        }
        foreach ($kv in $builtInTestCases.GetEnumerator()) {
            if (-not $testCase[$kv.Key]) {
                $TestCase[$kv.Key]= $kv.Value
            }
        }

        $null = $accumulatedTemplates.Add($TemplatePath)
    }

    end {
        $c, $t = 0, $accumulatedTemplates.Count
        $progId = Get-Random

        foreach ($TemplatePath in $accumulatedTemplates) {
            $C++
            $p = $c * 100 / $t
            $templateFileName = $TemplatePath | Split-Path -Leaf
            Write-Progress "Validating Templates" "$templateFileName" -PercentComplete $p -Id $progId
            $expandedTemplate =Expand-AzTemplate -TemplatePath $templatePath
            if (-not $expandedTemplate) { continue }
            foreach ($kv in $expandedTemplate.GetEnumerator()) {
                $ExecutionContext.SessionState.PSVariable.Set($kv.Key, $kv.Value)
            }
            
            $wellKnownVariables = @($expandedTemplate.Keys) + $cacheItemNames

            if ($testParameter) {
                $wellKnownVariables += foreach ($kv in $testParameter.GetEnumerator()) {
                    $ExecutionContext.SessionState.PSVariable.Set($kv.Key, $kv.Value)
                    $kv.Key
                }
            }

            # If a file list was provided,
            if ($PSBoundParameters.File) {
                $FolderFiles = @(foreach ($ff in $FolderFiles) { # filter the folder files.
                    $matched = @(foreach ($_ in $file) {
                        $ff.Name -like $_ # If file the name matched any of valid patterns.
                    })
                    if ($matched -eq $true)
                    {
                        $ff # then we include it.
                    }
                })
            }



            # Now that the filelist and test groups are set up, we use Test-FileList to test the list of files.
            if ($Pester) {
                $IsPesterLoaded? = $(
                    $loadedModules = Get-module
                    foreach ($_ in $loadedModules) {
                        if ($_.Name -eq 'Pester') {
                            $true
                            break
                        }
                    }
                )
                $DoesPesterExist? =
                    if ($IsPesterLoaded?) {
                        $true
                    } else {

                        if ($PSVersionTable.Platform -eq 'Unix') {
                            $delimiter = ':' # used for bash
                        } else {
                            $delimiter = ';' # used for windows
                        }

                        $env:PSModulePath -split $delimiter |
                        Get-ChildItem -Filter Pester |
                        Import-Module -Global -PassThru
                    }

                if (-not $DoesPesterExist?){
                    Write-Warning "Pester not found.  Please install Pester (Install-Module Pester)"
                    $Pester = $false
                }
            }

            if (-not $Pester) { # If we're not running Pester,
                Test-FileList # we just call it directly.
            }
            else {
                # If we're running Pester, we pass the function defintion as a parameter to describe.
                describe "Validating Azure Template $TemplateName" ${function:Test-FileList}
            }

        }

        Write-Progress "Validating Templates" "Complete" -Completed -Id $progId
    }
}
