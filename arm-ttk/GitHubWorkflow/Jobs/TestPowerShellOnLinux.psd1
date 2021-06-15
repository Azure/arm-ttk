@{
    "runs-on" = "ubuntu-latest"
    steps = @('InstallPester', 'Checkout','RunPester', 'PublishTestResults')
}