@{
    "runs-on" = "ubuntu-latest"
    steps = @(
        'Checkout',
        'AzureLogin', 
        'UpdateTTKCache'
    )
}

