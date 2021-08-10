Import-Module ExchangeOnlineManagement

    [string]$cAdmin = "brandon_burkhardtadmin@cabotcmp.com"
    [string]$cPass = "./twerp.derp-00"
    [securestring]$sStringCMC = ConvertTo-SecureString -AsPlainText $cPass -Force
    [pscredential]$cmcCredObj = New-Object System.Management.Automation.PSCredential ($cAdmin, $sStringCMC)

Connect-ExchangeOnline -Credential $cmcCredObj

$mseGroup = Get-DistributionGroup "CMC Hillsboro Postmaster"
$msegroupMembers = Get-DistributionGroupMember "CMC Hillsboro Postmaster"

#Get-DynamicDistributionGroup "CMC Hillsboro Employees"

