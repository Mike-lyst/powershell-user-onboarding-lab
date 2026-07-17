

Import-Module ActiveDirectory

# Import CSV
$Users = Import-Csv ".\Employee.csv"

# Ask for temporary password
$Password = Read-Host `
"Enter Temporary Password For New Users" `
-AsSecureString

# Log file
$Log = ".\Logs\UserCreation.log"

if (!(Test-Path ".\Logs"))
{
    New-Item `
    -ItemType Directory `
    -Path ".\Logs"
}

Add-Content $Log "========== $(Get-Date) =========="

foreach ($User in $Users)
{
    $FirstName = $User.FirstName.Trim()
    $LastName = $User.LastName.Trim()
    $Department = $User.Department.Trim()

    $Username = (
        $FirstName + "." + $LastName
    ).ToLower()

    $DisplayName = "$FirstName $LastName"

    $UPN = "$Username@raletcloud.local"

    # Department Mapping
    switch ($Department)
    {
        "HR"
        {
            $OU = "OU=Users,OU=HR,DC=raletcloud,DC=local"
            $Group = "GG-HR-Users"
        }

        "Finance"
        {
            $OU = "OU=Users,OU=FINANCE,DC=raletcloud,DC=local"
            $Group = "GG-Finance-Users"
        }

        "Sales"
        {
            $OU = "OU=Users,OU=SALES,DC=raletcloud,DC=local"
            $Group = "GG-Sales-Users"
        }

        "Operations"
        {
            $OU = "OU=Users,OU=OPERATIONS,DC=raletcloud,DC=local"
            $Group = "GG-Operations-Users"
        }

        "Management"
        {
            $OU = "OU=Users,OU=MANAGEMENT,DC=raletcloud,DC=local"
            $Group = "GG-Management-Users"
        }

        "IT"
        {
            $OU = "OU=Users,OU=IT ADMIN,DC=raletcloud,DC=local"
            $Group = "GG-IT-Admin"
        }

        Default
        {
            Write-Host "Department $Department not configured."

            Add-Content `
            $Log `
            "$(Get-Date) - Department $Department not configured."

            continue
        }
    }

    Write-Host ""
    Write-Host "Processing $DisplayName..."

    try
    {
        # Check if user exists
        $ExistingUser = Get-ADUser `
        -Filter "SamAccountName -eq '$Username'" `
        -ErrorAction SilentlyContinue

        if ($ExistingUser)
        {
            Write-Host "$Username already exists."

            Add-Content `
            $Log `
            "$(Get-Date) - $Username already exists."

            continue
        }

        # Create User
        New-ADUser `
        -Name $DisplayName `
        -GivenName $FirstName `
        -Surname $LastName `
        -SamAccountName $Username `
        -UserPrincipalName $UPN `
        -Department $Department `
        -Path $OU `
        -AccountPassword $Password `
        -Enabled $true `
        -ChangePasswordAtLogon $true

        Write-Host "User created."

        # Add user to security group
        if (Get-ADGroup `
            -Filter "Name -eq '$Group'" `
            -ErrorAction SilentlyContinue)
        {
            Add-ADGroupMember `
            -Identity $Group `
            -Members $Username

            Write-Host "Added to $Group"

            Add-Content `
            $Log `
            "$(Get-Date) - Created $Username and added to $Group."
        }
        else
        {
            Write-Host "Group $Group does not exist."

            Add-Content `
            $Log `
            "$(Get-Date) - Group $Group does not exist."
        }

        Write-Host "$Username created successfully."
    }
    catch
    {
        Write-Host "Failed to create $Username"

        Add-Content `
        $Log `
        "$(Get-Date) - Failed to create $Username : $_"
    }
}

Add-Content `
$Log `
"========== Script Completed =========="