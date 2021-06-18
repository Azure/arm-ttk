@{
    name = 'Checkout TTK'
    uses = 'actions/checkout@v2'
    id = 'CheckoutTTK'
    with = @{
        # Exclude = '*.tests.ps1;*.psdevops.ps1'
        repository = 'Azure/arm-ttk'
        path = 'ttk'
    }
}