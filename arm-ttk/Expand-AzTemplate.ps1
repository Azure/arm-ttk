function Expand-AzTemplate
{
    <#
    .Synopsis
        Expands the contents of an Azure Resource Manager template.
    .Description
        Expands an Azure Resource Manager template and related files into a set of well-known parameters

        Or

        Expands an Azure Resource Manager template expression
    .Notes
        Expand-AzTemplate -Expression expands expressions the resolve to a top-level property (e.g. variables or parameters).

        It does not expand recursively, and it does not attempt to evaluate complex expressions.
    #>
    [CmdletBinding(DefaultParameterSetName='SpecificTemplate')]
    [OutputType([string],[PSObject])]
    param(
    # The path to an Azure resource manager template
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='SpecificTemplate')]
    [Alias('Fullname','Path')]
    [string]
    $TemplatePath,

    # An Azure Template Expression, for example [parameters('foo')].bar.
    # If this expression was expanded, it would look in -InputObject for a .Parameters object containing the property 'foo'.
    # Then it would look in that result for a property named bar.
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='Expression')]
    [string]
    $Expression,

    # A whitelist of top-level properties to expand.
    # For example, passing -Include Parameters will only expand out the [Parameters()] function
    [Parameter(ParameterSetName='Expression')]
    [string[]]
    $Include,

    # A blacklist of top-level properties that will not be expanded.
    # For example, passing -Exclude Parameters will not expand any [Parameters()] function.
    [Parameter(ParameterSetName='Expression')]
    [string[]]
    $Exclude,

    # The object that will be used to evaluate the expression.
    [Parameter(ValueFromPipeline=$true,ParameterSetName='Expression')]
    [PSObject]
    $InputObject
    )

    begin {
        function Expand-Resource (
            [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
            [Alias('Resources')]
            [PSObject[]]
            $Resource,

            [PSObject[]]
            $Parent
        ) {
            process {
                foreach ($r in $Resource) {
                    $r |
                        Add-Member NoteProperty ParentResources $parent -Force -PassThru

                    if ($r.resources) {
                        $r | Expand-Resource -Parent (@($r) + @(if ($parent) { $parent }))
                    }
                }
            }
        }

        $TemplateLanguageExpression = "
\s{0,} # optional whitespace
\[ # opening bracket
(?<Function>\S{1,}) # the top-level function name
(?<Parameters>\( # the opening parenthesis
    (?>[^\(\)]+|\((?<Depth>)|\)(?<-Depth>))*(?(Depth)(?!)) # anything until we're balanced
\)) # the closing parenthesis
(?<Index>\[\d{1,}\]){0,1} # an optional index
(?<Property>\. # a property
    (?<PropertyName>[^\.\[\]\s]{1,}){1,1}
    (?<PropertyIndex>\[\d{1,}\]){0,1} # One or more optional properties
){0,}
\] # closing bracket
\s{0,} # optional whitespace
"

        $TemplateParametersExpression = "
(
    (?<Quote>') # a single quote
        (?<StringLiteral>([^']|(?<=')'){1,}) # anything until the next quote (including '')
    \k<Quote>| # a closing quote OR
    (?<Boolean>true|false)| # the literal values true and false OR
    (?<Number>\d[\d\.]{1,})| # a number OR
    (
        (?<Function>\S{1,}) # the top-level function name
        (?<Parameters>\( # the opening parenthesis
            (?>[^\(\)]+|\((?<Depth>)|\)(?<-Depth>))*(?(Depth)(?!)) # anything until we're balanced
        \)) # the closing parenthesis
    )
    (?<Index>\[\d{1,}\]){0,} # One or more indeces
    (?<Property>\.[^\.\s]{1,}){0,} # One or more optional properties
)\s{0,}
"

        $regexOptions = 'Multiline,IgnoreCase,IgnorePatternWhitespace'
        $regexTimeout = [Timespan]::FromSeconds(5)
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'SpecificTemplate') {
            # Now let's try to resolve the template path.
            $resolvedTemplatePath =
                # If the template path doesn't appear to be a path to a json file,
                if ($TemplatePath -notmatch '\.json(c)?$') {
                    # see if it looks like a file
                    if ( test-path -path $templatePath -PathType leaf) {
                        $TemplatePath = $TemplatePath | Split-Path # if it does, reassign template path to it's directory.
                    }
                    # Then, go looking beneath that template path
                    $preferredJsonFile = $TemplatePath |
                        Get-ChildItem -Filter *.json |
                        # for a file named azuredeploy.json, prereq.azuredeploy.json or mainTemplate.json
                        Where-Object { 'azuredeploy.json', 'mainTemplate.json', 'prereq.azuredeploy.json' -contains $_.Name } |
                        Select-Object -First 1 -ExpandProperty Fullname
                    # If no file was found, write an error and return.
                    if (-not $preferredJsonFile) {
                        Write-Error "No azuredeploy.json or mainTemplate.json found beneath $TemplatePath"
                        return
                    }
                    $preferredJsonFile
                } else {
                    $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($templatePath)
                }

            # If we couldn't find a template file, return (an error should have already been written).
            if (-not $resolvedTemplatePath) {  return }


            # Next, we want to pre-populate a number of well-known variables.
            # These variables will be available to every test case.   They are:
            $WellKnownVariables = 'TemplateFullPath','TemplateText','TemplateObject','TemplateFileName',
                'CreateUIDefinitionFullPath','createUIDefinitionText','CreateUIDefinitionObject',
                'FolderName', 'HasCreateUIDefinition', 'IsMainTemplate','FolderFiles',
                'MainTemplatePath', 'MainTemplateObject', 'MainTemplateText',
                'MainTemplateResources','MainTemplateVariables','MainTemplateParameters', 'MainTemplateOutputs', 'TemplateMetadata',
                'isParametersFile', 'ParameterFileName', 'ParameterObject', 'ParameterText',
                'InnerTemplates', 'InnerTemplatesText', 'InnerTemplatesNames','InnerTemplatesLocations','ParentTemplateText', 'ParentTemplateObject',
                'ExpandedTemplateText', 'ExpandedTemplateObject','OriginalTemplateText','OriginalTemplateObject'

            foreach ($_ in $WellKnownVariables) {
                $ExecutionContext.SessionState.PSVariable.Set($_, $null)
            }

            #*$templateFullPath (the full path to the .json file)
            $TemplateFullPath = "$resolvedTemplatePath"
            #*$TemplateFileName (the name of the azure template file)
            $templateFileName = $TemplateFullPath | Split-Path -Leaf
            #*$IsMainTemplate (if the TemplateFileName is named mainTemplate.json)
            $isMainTemplate = 'mainTemplate.json', 'azuredeploy.json', 'prereq.azuredeploy.json' -contains $templateFileName
            $templateFile = Get-Item -LiteralPath "$resolvedTemplatePath"
            $templateFolder = $templateFile.Directory
            #*$FolderName (the name of the root folder containing the template)
            $TemplateName = $templateFolder.Name
            #*$TemplateText (the text contents of the template file)
            $TemplateText = [IO.File]::ReadAllText($resolvedTemplatePath)
            #*$TemplateObject (the template text, converted from JSON)
            $TemplateObject = Import-Json -FilePath $TemplateFullPath
            #*$ParentTemplateText (the parent or original template (will be the same if no nested deployments is found))
            $ParentTemplateText = [IO.File]::ReadAllText($resolvedTemplatePath)
            #*$ParentTemplateObject (the parent or original template (will be the same if no nested deployments is found))
            $ParentTemplateObject = Import-Json -FilePath $TemplateFullPath

            if($TemplateObject.metadata -ne $null){
                $TemplateMetadata = $($TemplateObject.metadata)
            } else {
                $TemplateMetadata = @{}
            }

            $isParametersFile = $resolvedTemplatePath -like '*.parameters.json'

            if ($resolvedTemplatePath -match '\.json(c)?$' -and 
                $TemplateObject.'$schema' -like '*CreateUIDefinition*') {
                $createUiDefinitionFullPath = "$resolvedTemplatePath"
                $createUIDefinitionText = [IO.File]::ReadAllText($createUiDefinitionFullPath)
                $createUIDefinitionObject = Import-Json -FilePath $createUiDefinitionFullPath
                $HasCreateUIDefinition = $true
                $isMainTemplate = $false
                $templateFile =  $TemplateText = $templateObject = $TemplateFullPath = $templateFileName = $null
            } elseif ($isParametersFile) {
                #*$parameterText (the text contents of a parameters file (*.parameters.json)
                $ParameterText = $TemplateText
                #*$parameterObject (the text, converted from json)
                $ParameterObject =  $TemplateObject
                #*$HasParameter (indicates if parameters file exists (*.parameters.json))
                $HasParameters = $true   
                $ParameterFileName = $templateFileName
                $templateFile =  $TemplateText = $templateObject = $TemplateFullPath = $templateFileName = $null
            } else {
                #*$CreateUIDefinitionFullPath (the path to CreateUIDefinition.json)
                $createUiDefinitionFullPath = 
                    Get-ChildItem -Path $templateFolder | 
                    Where-Object Name -eq 'createUiDefinition.json' | 
                    Select-Object -ExpandProperty FullName
                if ($createUiDefinitionFullPath -and (Test-Path $createUiDefinitionFullPath)) {
                    #*$CreateUIDefinitionText (the text contents of CreateUIDefinition.json)
                    $createUIDefinitionText = [IO.File]::ReadAllText($createUiDefinitionFullPath)
                    #*$CreateUIDefinitionObject (the createuidefinition text, converted from json)
                    $createUIDefinitionObject =  Import-Json -FilePath $createUiDefinitionFullPath
                    #*$HasCreateUIDefinition (indicates if a CreateUIDefinition.json file exists)
                    $HasCreateUIDefinition = $true
                } else {
                    $HasCreateUIDefinition = $false
                    $createUiDefinitionFullPath = $null
                }
            }

            #*$FolderFiles (a list of objects of each file in the directory)
            $FolderFiles =
                @(Get-ChildItem -Path $templateFolder.FullName -Recurse |
                    Where-Object { -not $_.PSIsContainer } |
                    ForEach-Object {
                        $fileInfo = $_
                        if ($resolvedTemplatePath -like '*.json' -and -not $isMainTemplate -and 
                            $fileInfo.FullName -ne $resolvedTemplatePath) { return }

                        if ($fileInfo.DirectoryName -eq '__macosx') {
                            return # (excluding files as side-effects of MAC zips)
                        }
                        
                        # All FolderFile objects will have the following properties:

                        if ($fileInfo.Extension -in '.json', '.jsonc') {
                            $fileObject = [Ordered]@{
                                Name = $fileInfo.Name #*Name (the name of the file)
                                Extension = $fileInfo.Extension #*Extension (the file extension)
                                Text = [IO.File]::ReadAllText($fileInfo.FullName)#*Text (the file content as text)
                                FullPath = $fileInfo.Fullname#*FullPath (the full path to the file)
                            }
                            # If the file is JSON, two additional properties may be present:
                            #* Object (the file's text, converted from JSON)
                            $fileObject.Object = Import-Json $fileObject.FullPath
                            #* Schema (the value of the $schema property of the JSON object, if present)
                            $fileObject.schema = $fileObject.Object.'$schema'
                            #* InnerTemplates (any inner templates found within the object)
                            $fileObject.InnerTemplates = @(if ($fileObject.Text -and $fileObject.Text.Contains('"template"')) {
                                Find-JsonContent -InputObject $fileObject.Object -Key template |
                                    Where-Object { $_.expressionEvaluationOptions.scope -eq 'inner' -or $_.jsonPath -like '*.policyRule.*' } |
                                    Sort-Object JSONPath -Descending
                            })                            
                            #* InnerTemplatesText     (an array of the text of each inner template)
                            $fileObject.InnerTemplatesText = @()
                            #* InnerTemplateNames     (an array of the name of each inner template)
                            $fileObject.InnerTemplatesNames = @()
                            #* InnerTemplateLocations (an array of the resolved locations of each inner template)
                            $fileObject.InnerTemplatesLocations = @()
                            if ($fileObject.innerTemplates) {
                                $anyProblems = $false                                
                                foreach ($it in $fileObject.innerTemplates) {
                                    $foundInnerTemplate = $it | Resolve-JSONContent -JsonText $fileObject.Text
                                    if (-not $foundInnerTemplate) { $anyProblems = $true; continue }
                                    $fileObject.InnerTemplatesText += $foundInnerTemplate.Content -replace '^\s{0,}"template"\s{0,}\:\s{0,}'
                                    $fileObject.InnerTemplatesNames += $it.ParentObject[0].Name
                                    $fileObject.InnerTemplatesLocations += $foundInnerTemplate
                                }
                                
                                if ($anyProblems) {
                                    Write-Error "Could not extract inner templates for '$TemplatePath'." -ErrorId InnerTemplate.Extraction.Error
                                }
                            }
                            $fileObject
                        }

                    })

            if ($isMainTemplate) { # If the file was a main template,
                # we set a few more variables:
                #*MainTemplatePath (the path to the main template file)
                $MainTemplatePath = "$TemplateFullPath"
                #*MainTemplateText (the text of the main template file)
                $MainTemplateText = [IO.File]::ReadAllText($MainTemplatePath)
                #*MainTemplateObject (the main template, converted from JSON)
                $MainTemplateObject = Import-Json -FilePath $MainTemplatePath
                #*MainTemplateResources (the resources and child resources in the main template)
                # TODO this was removed from the only test using it (it wasn't working, can probably remove from the fw)
                $MainTemplateResources = if ($mainTemplateObject.Resources) {
                    Expand-Resource -Resource $MainTemplateObject.resources
                } else { $null }
                #*MainTemplateParameters (a hashtable of parameters in the main template)
                $MainTemplateParameters = [Ordered]@{}
                foreach ($prop in $MainTemplateObject.parameters.psobject.properties) {
                    $MainTemplateParameters[$prop.Name] = $prop.Value
                }
                #*MainTemplateVariables (a hashtable of variables in the main template)
                $MainTemplateVariables = [Ordered]@{}
                foreach ($prop in $MainTemplateObject.variables.psobject.properties) {
                    $MainTemplateVariables[$prop.Name] = $prop.Value
                }
                #*MainTemplateOutputs (a hashtable of outputs in the main template)
                $MainTemplateOutputs = [Ordered]@{}
                foreach ($prop in $MainTemplateObject.outputs.psobject.properties) {
                    $MainTemplateOutputs[$prop.Name] = $prop.Value
                }
            }

            # If we've found a CreateUIDefinition, we'll want to process it first.
            if ($HasCreateUIDefinition) {
                # Loop over the folder files and get every file that isn't createUIDefinition
                $otherFolderFiles = @(foreach ($_ in $FolderFiles) {
                    if ($_.Name -ne 'CreateUIDefinition.json') {
                        $_
                    } else {
                        $createUIDefFile = $_
                    }
                })
                # Then recreate the list with createUIDefinition that the front.
                $FolderFiles = @(@($createUIDefFile) + @($otherFolderFiles) -ne $null)
            }

            
            $innerTemplates = @(if ($templateText -and $TemplateText.Contains('"template"')) {
                Find-JsonContent -InputObject $templateObject -Key template |
                    Where-Object { $_.expressionEvaluationOptions.scope -eq 'inner' -or $_.jsonPath -like '*.policyRule.*' } |
                    Sort-Object JSONPath -Descending
            })

            $innerTemplatesText =@()

            if ($innerTemplates) {
                $anyProblems = $false
                $originalTemplateText = "$TemplateText"
                $OriginalTemplateObject = $TemplateObject
                foreach ($it in $innerTemplates) {
                    $foundInnerTemplate = $it | Resolve-JSONContent -JsonText $TemplateText
                    if (-not $foundInnerTemplate) { $anyProblems = $true; break }
                    $innerTemplatesText += $foundInnerTemplate.Content -replace '"template"\s{0,}\:\s{0,}'
                    $TemplateText = $TemplateText.Remove($foundInnerTemplate.Index, $foundInnerTemplate.Length)
                    $TemplateText = $TemplateText.Insert($foundInnerTemplate.Index, '"template": {}')
                }

                if (-not $anyProblems) {
                    $TemplateObject = $TemplateText | ConvertFrom-Json
                } else {
                    Write-Error "Could not extract inner templates for '$TemplatePath'." -ErrorId InnerTemplate.Extraction.Error
                }
            } else {
                $originalTemplateText = $TemplateText
                $OriginalTemplateObject = $TemplateObject   
            }
            
            
            if ($TemplateText) {
                $variableReferences = $TemplateText | ?<ARM_Variable> 
                $expandedTemplateText = $TemplateText | ?<ARM_Variable> -ReplaceEvaluator {
                    param($match)

                    $templateVariableValue = $templateObject.variables.$($match.Groups['VariableName'])
                    if ($match.Groups["Property"].Success) {
                    
                        $v = $templateVariableValue
                        foreach ($prop in $match.Groups["Property"] -split '\.' -ne '') {
                            if ($prop -match '\[(?<Index>\d+)]$') {
                                $v.($prop.Replace("$($matches.0)", ''))[[int]$matches.Index]
                            } else {
                                $v  = $v.$prop
                            }
                        }
                        return "'$("$v".Replace("'","\'"))'"
                    } else {
                        if ($templateVariableValue -isnot [string]) { # If the value is not a string                            
                            return "json('$(($templateVariableValue | ConvertTo-Json -Depth 100 -Compress) -replace '\\u0027b', "'" -replace '"','\"'))'"
                            # make it JSON
                        }
                        if ("$templateVariableValue".StartsWith('[')) { # If the value is a subexpression
                            if ("$templateVariableValue".EndsWith(']')) { 
                                return "$templateVariableValue" -replace '^\[' -replace '\]$' -replace '"', '\"' # Escape the brackets and quotes
                            } else {
                                return $templateVariableValue
                            }
                        } else {
                            return "'" + "$templateVariableValue".Replace("'","\'") + "'"
                        }
                    
                        return "$($templateObject.variables.$($match.Groups['VariableName']))".Replace("'","\'")
                    }
                }

                if ($expandedTemplateText -ne $TemplateText) {
                    $expandedTemplateObject = try { $expandedTemplateText | ConvertFrom-Json -ErrorAction Stop -ErrorVariable err } catch {
                        "$_" | Write-Debug
                    }
                } else {
                    $expandedTemplateObject = $null
                }
            }

            $out = [Ordered]@{}
            foreach ($v in $WellKnownVariables) {
                $out[$v] = $ExecutionContext.SessionState.PSVariable.Get($v).Value
            }
            $out
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Expression') {

            # First, we need to see if the expression provided looks like a template language expression
            $matched? =
                [Regex]::Match($Expression, $TemplateLanguageExpression, $regexOptions, $regexTimeout)
            if (-not $matched?.Success) { # If it wasn't
                Write-Verbose "$Expression is not an expression" # Write to the verbose stream
                return $Expression # and return the original expression
            }



            $functionName = $matched?.Groups["Function"].Value

            if (-not $InputObject.$functionName) { # If there wasn't a property on the inputobject
                return $matched?.Value # Return the expression
            }

            # Get the parameters
            $parametersExpression = $matched?.Groups["Parameters"].Value
            # strip off the () (don't use trim, or we might hurt subexpressions)
            $parametersExpression = $parametersExpression.Substring(1,$parametersExpression.Length - 1)

            $functionParameters = @([Regex]::Matches($parametersExpression, $TemplateParametersExpression, $regexOptions, $regexTimeout))
            if (-not $functionParameters) { # If there were no parameters
                return $matched?.Value      # return the partially resolved expression.
            }

            if (-not $functionParameters[0].Groups["StringLiteral"].Success) { # If we didn't get a literal value
                return $matched?.Value     # return the partially resolved expression.
            }

            if ($Include -and $Include -notcontains $functionName) { # If we have a whitelist, and the function isn't in it.
                return $Expression # don't evaluate.
            }

            if ($Exclude -and $Exclude -contains $functionName) { # If we have a blacklist, and the function is in it.
                return $Expression # don't evaluate.
            }


            # Find the target property
            $targetProperty = $functionParameters[0].Groups["StringLiteral"].Value

            # and resolve the target object.
            $targetObject = $InputObject.$functionName.$targetProperty


            if (-not $targetObject) {  # If the object didn't resolve,
                Write-Error ".$functionName.$targetProperty not found" # error out.
                return
            }


            if ($matched?.Groups["Index"].Success) {  # Assuming it did, we have to check for indices
                $index = $matched?.Groups["Index"].Value -replace '[\[\]]', '' -as [int]

                if (-not $targetObject[$index]) {
                    Write-Error "Index $index not found"
                    return
                } else {
                    $targetObject = $targetObject[$index]
                }
            }
            # Since we can nest properties and indices, we just have to work thru each remaining one.
            $propertyMatchGroup = $matched?.Groups["Property"]
            if ($propertyMatchGroup.Success) {
                foreach ($cap in $propertyMatchGroup.Captures) {
                    $propName, $propIndex = $cap.Value -split '[\.\[\]]' -ne ''

                    if (-not $targetObject.$propName) {
                        Write-Error "Property $propName not found"
                        return
                    }

                    $targetObject = $targetObject.$propName
                    if ($propIndex -and $propIndex -as [int] -ne $null) {
                        if (-not $targetObject[$propIndex -as [int]]) {
                            Write-Error "Index $propIndex not found"
                            return
                        } else {
                            $targetObject = $targetObject[$propIndex -as [int]]
                        }
                    }
                }
            }

            # and at last, we can return whatever was resolved.
            return $targetObject
        }
    }
}
