@{
    "runs-on" = "ubuntu-latest"
    steps = @('Checkout','InstallPester', 'RunPester', 'PublishTestResults')
}