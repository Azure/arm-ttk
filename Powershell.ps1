pool:
  name: Hosted Windows 2019 with VS2019
  demands: githubreps

steps:
- task: AzurePowerShell@3
  inputs:
    azureSubscription: 'Pay-As-You-Go'
    ScriptPath: 'AzureResourceGroupDemo/Deploy-AzureResourceGroup.ps1'
    ScriptArguments: -ResourceGroupName 'vbk' -ResourceGroupLocation 'Southeast Asia'
    azurePowerShellVersion: LatestVersion
