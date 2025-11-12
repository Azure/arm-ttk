return {
  subscriptionId: getVariable("deploymentRequest").subscriptionId,
  subscriptionName: getVariable("deploymentRequest").subscriptionName,
  resourceGroupName: '',
  managedResourceGroupName: getVariable("deploymentRequest").managedResourceGroup,
  webAppName: getVariable("deploymentRequest").webAppName,
  slotName: '',
  kuduUser: getVariable("deploymentRequest").kuduUsername,
  kuduPassword: getVariable("deploymentRequest").kuduPassword
}
