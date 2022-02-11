<#
    .SYNOPSIS
        MFA is forced on all actions on all user accounts per 'Force_MFA' iam policy on the oraganization.
    .DESCRIPTION
        If you create access keys via GUI it does not use MFA; therefore, it will be denied for all 
        actions to resources per that policy. However, you will be able to create a MFA temporary access
        token to run aws cli commands.   

        Use this script to create your temporary access id, key, and token for the default 12 hours.
    .Example
        PS> .\Generate-MfaAccessToken
        You could automate this as a scheduled task on logon or when you open a terminal. 
    .LINK
        https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/
#>

function Find-Prerequisite {
    if ($null -ne (Get-Command aws -ErrorAction SilentlyContinue)){
        $checkContentFile = "$env:USERPROFILE\.aws\credentials"
        if ($null -ne (Get-Content $checkContentFile)){
            $true
        }
    } else {
        $false
    }
}

function Install-Prerequisite {
    # TODO download the item and install it in the future.
    Write-Host "1. Download and Install AWS CLI from: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor Yellow
    Write-Host "2. Create your AWS programmatic access keys from the 'Security credentials' tab of IAM." -ForegroundColor Yellow
    Write-Host "3. Add your programmatic access keys via the termial command 'aws configure'." -ForegroundColor Yellow
    Break
}

function Get-TempAcccess {
    $getUserName = Read-Host('AWS Username: ')
    $listMfaDevices = aws iam list-mfa-devices --user-name $getUserName
    $mfaJson = $listMfaDevices | ConvertFrom-Json
    $mfaVirtualDeviceArn = $mfaJson.MFADevices.SerialNumber
    $token = Read-Host('Please enter OTP from Virtual MFA Device')
    aws sts get-session-token --serial-number $mfaVirtualDeviceArn --token-code $token
}

function Set-MfaToken {
    aws configure set aws_access_key_id $accessKeyID --profile mfa
    aws configure set aws_secret_access_key $secretAccessKey --profile mfa
    aws configure set aws_session_token $sessionToken --profile mfa
}

# Need to wrap this all in a function so i can pass the two args
if (Find-Prerequisite){
    $json = Get-TempAcccess | ConvertFrom-Json
    if ($null -ne $json){ # should be able to move these variables into function Set-MfaToken ...
        $accessKeyID = $json.Credentials.AccessKeyID
        $secretAccessKey = $json.Credentials.SecretAccessKey
        $sessionToken = $json.Credentials.SessionToken
        $experationdate = $json.Credentials.Expiration 

        Set-MfaToken
        Write-Host "--profile mfa has been set. Credential expires: $experationdate" -ForegroundColor Green
    } else {
        Write-Host "Something went wrong during Get-TempAccess" -ForegroundColor Yellow
    }

}else {
    Install-Prerequisite
}