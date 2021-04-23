param(
    [String] [Parameter (Mandatory=$true)] $TemplatePath,
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$true)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$true)] $ResourceGroup,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $VirtualNetworkName,
    [String] [Parameter (Mandatory=$true)] $VirtualNetworkRG,
    [String] [Parameter (Mandatory=$true)] $VirtualNetworkSubnet
)

if (-not (Test-Path $TemplatePath))
{
    Write-Error "'-TemplatePath' parameter is not valid. You have to specify correct Template Path"
    exit 1
}

$Image = [io.path]::GetFileNameWithoutExtension($TemplatePath)
$TempResourceGroupName = "${ResourcesNamePrefix}_${Image}"
$InstallPassword = [System.GUID]::NewGuid().ToString().ToUpper()
$ManagedImageName = "devops-image"

packer validate -syntax-only $TemplatePath

$SensitiveData = @(
    'OSType',
    'StorageAccountLocation',
    'OSDiskUri',
    'OSDiskUriReadOnlySas',
    'TemplateUri',
    'TemplateUriReadOnlySas',
    ':  ->'
)

Write-Host "Show Packer Version"
packer --version

Write-Host "Build $Image VM"
packer build    -var "client_id=$ClientId" `
                -var "client_secret=$ClientSecret" `
                -var "install_password=$InstallPassword" `
                -var "location=$Location" `
                -var "managed_image_resource_group_name=$ResourceGroup" `
                -var "managed_image_name=$ManagedImageName" `
                -var "subscription_id=$SubscriptionId" `
                -var "temp_resource_group_name=$TempResourceGroupName" `
                -var "tenant_id=$TenantId" `
                -var "virtual_network_name=$VirtualNetworkName" `
                -var "virtual_network_resource_group_name=$VirtualNetworkRG" `
                -var "virtual_network_subnet_name=$VirtualNetworkSubnet" `
                -var "run_validation_diskspace=$env:RUN_VALIDATION_FLAG" `
                $TemplatePath `
        | Where-Object {
            #Filter sensitive data from Packer logs
            $currentString = $_
            $sensitiveString = $SensitiveData | Where-Object { $currentString -match $_ }
            $sensitiveString -eq $null
        }