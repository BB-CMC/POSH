#----------------------------------------------------------------#
#v#v#v# BEGIN SCRIPT #v#v#v#
#----------------------------------------------------------------#
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false
Import-Module ActiveDirectory
$lOU = "OU=Live Users,OU=Users,OU=CMC,DC=cabotcmp,DC=com"
$csvPath = "C:\Users\BBURKHARDT\Desktop\branding.csv"
#----------------------------------------------------------------#
$brandingCSV = Import-Csv -Path $csvPath -Header "email"

$bulkEnable = @()
$bulkEnable = $brandingCSV | ForEach-Object {
    $UPN = $_.email
    Get-ADUser -Filter {userPrincipalName -eq $UPN} -Properties Name, CanonicalName, Title, SamAccountName, `
    Description, EmailAddress, Enabled, AccountExpirationDate, MemberOf, Office, givenName, Surname, userPrincipalName, DistinguishedName | Select-Object Name, CanonicalName, `
    Title, SamAccountName, Description, EmailAddress, Enabled, AccountExpirationDate, MemberOf, Office, givenName, Surname, userPrincipalName, DistinguishedName
}

$importCheck = $bulkEnable.Count

$bulkEnable | ForEach-Object {
    $SM = @()
    $SM = $bulkEnable.SamAccountName
    $email_UPN = @()
    $email_UPN = $bulkEnable.userPrincipalName
    $properUPN = $email_UPN.tolower()
    $sam = $bulkEnable.SamAccountName
}

$description = "Test Account"
$office = "NA"

for ($i = 0; $i -le $importCheck; $i++) {
    $bulkEnable | ForEach-Object {
        $primaryGroup = Get-ADGroup -Filter "Name -like 'Domain Users'" -Properties @("primaryGroupToken") -ErrorAction SilentlyContinue
        Add-ADGroupMember -Identity $primaryGroup.SamAccountName -Members $SM.Item($i) -Confirm:$false
        Set-ADUser -Identity $SM.Item($i) -Replace @{primarygroupid=$primaryGroup.primaryGroupToken} -Confirm:$false -ErrorAction SilentlyContinue
        }
}

Try {
    for ($i = 0; $i -le $importCheck; $i++) {
        Set-ADUser -Identity $SM.Item($i) -EmailAddress $properUPN.Item($i) -Enabled $true -Description $description -Office $office -Confirm:$false -ErrorAction SilentlyContinue
        Clear-ADAccountExpiration -Identity $SM.Item($i) -Confirm:$false -ErrorAction SilentlyContinue
        $adGroups = Get-ADPrincipalGroupMembership -Identity $SM.Item($i) 
                
                                ForEach ($group in $adGroups){
                                    if ($group.name -notlike "*Domain Users*"){
                                        Remove-ADGroupMember -Identity $group.name -Members $SM.Item($i) -Confirm:$false -ErrorAction SilentlyContinue
                                    }#end if

                                }#end foreach

        Add-ADGroupMember -Identity 'Int-US' -Members $SM.Item($i) -Confirm:$false -ErrorAction SilentlyContinue
        Add-ADGroupMember -Identity 'Int-Users' -Members $SM.Item($i) -Confirm:$false -ErrorAction SilentlyContinue

        $distName = $bulkEnable.DistinguishedName
        Move-ADObject -Identity $distName.Item($i) -TargetPath $lOU -Confirm:$false -ErrorAction SilentlyContinue
                            }#end for loop
} Catch [Exception] {}