function Get-StartupConfiguration {
    $tasks=@(Get-ScheduledTask -ErrorAction Stop | Where-Object {$_.TaskPath -eq '\' -and $_.TaskName -in @('Virtual Display Manager','Virtual Display Manager Recovery')})
    $start=$tasks|Where-Object TaskName -eq 'Virtual Display Manager'
    $recovery=$tasks|Where-Object TaskName -eq 'Virtual Display Manager Recovery'
    [pscustomobject]@{Installed=([bool]$start -and [bool]$recovery);StartEnabled=([bool]$start -and $start.Settings.Enabled);RecoveryEnabled=([bool]$recovery -and $recovery.Settings.Enabled)}
}
function Set-StartupConfiguration {
    param($Context)
    if(-not $Context.Embedded -or -not (Test-Path -LiteralPath $Context.Embedded)){throw 'Use the portable CMD package to configure Windows startup.'}
    $installer=[scriptblock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__INSTALLER_B64__')))
    & $installer -PackagePath ([string]$Context.Embedded) -StartEnabled ([bool]$Context.StartEnabled) -RecoveryEnabled ([bool]$Context.RecoveryEnabled)|Out-Null
    $state=Get-StartupConfiguration
    if($state.StartEnabled -ne [bool]$Context.StartEnabled -or $state.RecoveryEnabled -ne [bool]$Context.RecoveryEnabled){throw 'Startup settings could not be verified.'}
    return $state
}
