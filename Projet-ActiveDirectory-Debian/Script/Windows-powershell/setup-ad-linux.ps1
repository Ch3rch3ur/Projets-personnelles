# ===============================
# AD Linux Integration – Windows
# ===============================

Import-Module ActiveDirectory

# --- Variables ---
$DomainDN = "DC=homelab,DC=local"
$OU = "CN=Users,$DomainDN"

# --- Groupes Linux ---
$Groups = @("linux-users", "linux-admins")

foreach ($Group in $Groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$Group'" -ErrorAction SilentlyContinue)) {
        New-ADGroup `
            -Name $Group `
            -SamAccountName $Group `
            -GroupScope Global `
            -GroupCategory Security `
            -Path $OU
        Write-Host "Groupe créé : $Group"
    }
}

# --- Exemple utilisateur non admin ---
if (-not (Get-ADUser -Filter "SamAccountName -eq 'simple-user'" -ErrorAction SilentlyContinue)) {
    New-ADUser `
        -Name "simple-user" `
        -SamAccountName "simple-user" `
        -AccountPassword (Read-Host "Mot de passe simple-user" -AsSecureString) `
        -Enabled $true `
        -PasswordNeverExpires $true
    Add-ADGroupMember -Identity linux-users -Members simple-user
    Write-Host "Utilisateur simple-user créé et ajouté à linux-users"
}

# --- Exemple admin Linux ---
Add-ADGroupMember -Identity linux-admins -Members Administrateur

Write-Host "Configuration AD Linux terminée."

