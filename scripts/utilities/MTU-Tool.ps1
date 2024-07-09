<#
MIT License

Copyright (c) 2024 RioPlay

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function Show-CommonMTUStandards {
    Write-Host "Common MTU Standards:"
    Write-Host "  1. Ethernet (Standard) - 1500 bytes"
    Write-Host "  2. Ethernet (Jumbo Frames) - 9000 bytes"
    Write-Host "  3. PPPoE - 1492 bytes"
    Write-Host "  4. VPN - 1400 bytes"
    Write-Host "  5. Wireless - 2272 bytes"
    Write-Host "  6. FDDI - 4352 bytes"
    Write-Host "  7. ATM - 9180 bytes"
    Write-Host "  8. IPv4 Minimum MTU - 576 bytes"
    Write-Host "  9. IPv6 Minimum MTU - 1280 bytes"
    Write-Host "  10. Enter custom MTU value"
    Write-Host ""
}

function Get-NetworkAdapters {
    return Get-NetAdapter
}

function Get-AdapterMTU {
    param ([string]$AdapterName)

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }
    $persistentMTU = (Get-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -PolicyStore PersistentStore | Select-Object -ExpandProperty NlMtu -ErrorAction SilentlyContinue)
    $activeMTU = (Get-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -PolicyStore ActiveStore | Select-Object -ExpandProperty NlMtu -ErrorAction SilentlyContinue)

    return [PSCustomObject]@{
        AdapterName           = $adapter.Name
        InterfaceDescription  = $adapter.InterfaceDescription
        Status                = $adapter.Status
        ActiveMTU             = if ($activeMTU -is [System.Array]) { $activeMTU[0] } else { $activeMTU }
        PersistentMTU         = if ($persistentMTU -is [System.Array]) { $persistentMTU[0] } else { $persistentMTU }
    }
}

function Show-MTUSettings {
    $adapters = Get-NetworkAdapters

    if ($adapters.Count -eq 0) {
        Write-Host "No network adapters found."
        return
    }

    $adapterMTUs = $adapters | ForEach-Object { Get-AdapterMTU -AdapterName $_.Name }
    $adapterMTUs | Format-Table AdapterName, InterfaceDescription, Status, ActiveMTU, PersistentMTU
}

function Set-AdapterMTU {
    param (
        [string]$AdapterName,
        [int]$MTU,
        [bool]$Persistent
    )

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }

    try {
        if ($Persistent) {
            Write-Host "Setting MTU for adapter '$AdapterName' to $MTU bytes persistently."
            Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore PersistentStore
        } else {
            Write-Host "Setting MTU for adapter '$AdapterName' to $MTU bytes for this session."
            Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore ActiveStore
        }

        # Verify the MTU value
        Start-Sleep -Seconds 2  # Wait a moment to ensure the setting is applied
        $currentActiveMTU = (Get-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -PolicyStore ActiveStore).NlMtu
        $currentPersistentMTU = (Get-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -PolicyStore PersistentStore).NlMtu

        if ($currentActiveMTU -eq $MTU) {
            Write-Host "Active MTU set successfully to $MTU bytes."
        } else {
            Write-Host "Failed to set Active MTU to $MTU bytes. Current Active MTU is $currentActiveMTU bytes. This might indicate an invalid value."
        }

        if ($Persistent -and $currentPersistentMTU -ne $MTU) {
            Write-Host "Failed to set Persistent MTU to $MTU bytes. Current Persistent MTU is $currentPersistentMTU bytes. This might indicate an invalid value."
        } elseif ($Persistent) {
            Write-Host "Persistent MTU set successfully to $MTU bytes."
        }
    } catch {
        Write-Host "Failed to set MTU: $_"
    }
}

function Enable-NetworkAdapter {
    param ([string]$AdapterName)

    Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }

    try {
        Write-Host "Enabling network adapter '$AdapterName'."
        Enable-NetAdapter -Name $AdapterName -Confirm:$false
        Write-Host "Network adapter '$AdapterName' enabled successfully."
    } catch {
        Write-Host "Failed to enable network adapter '$AdapterName': $_"
    }
}

function Disable-NetworkAdapter {
    param ([string]$AdapterName)

    Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }

    try {
        Write-Host "Disabling network adapter '$AdapterName'."
        Disable-NetAdapter -Name $AdapterName -Confirm:$false
        Write-Host "Network adapter '$AdapterName' disabled successfully."
    } catch {
        Write-Host "Failed to disable network adapter '$AdapterName': $_"
    }
}

function Test-IPv4IPv6Support {
    param ([string]$AdapterName)

    $adapter = Get-NetAdapter -Name $AdapterName
    $ipv4Enabled = $false
    $ipv6Enabled = $false

    try {
        $ipv4Interfaces = $adapter | Get-NetIPInterface -AddressFamily IPv4 -ErrorAction Stop
        if ($ipv4Interfaces) { $ipv4Enabled = $true }
    } catch { $ipv4Enabled = $false }

    try {
        $ipv6Interfaces = $adapter | Get-NetIPInterface -AddressFamily IPv6 -ErrorAction Stop
        if ($ipv6Interfaces) { $ipv6Enabled = $true }
    } catch { $ipv6Enabled = $false }

    return @{
        IPv4 = $ipv4Enabled
        IPv6 = $ipv6Enabled
    }
}

function Get-AdapterIPAddress {
    param ([string]$AdapterName)

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }
    $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex | Where-Object { $_.AddressFamily -eq 'IPv4' }

    return $ipConfig.IPAddress
}

function Test-MTU {
    param (
        [string[]]$TestServers,
        [int]$StartMTU,
        [bool]$Randomize,
        [bool]$IsIPv6
    )

    $maxMTU = $StartMTU
    $minMTU = 576
    $warning1280Shown = $false
    $warning576Shown = $false

    for ($currentMTU = $maxMTU; $currentMTU -ge $minMTU; $currentMTU--) {
        if ($IsIPv6 -and $currentMTU -eq 1280 -and -not $warning1280Shown) {
            $continue1280 = Read-Host "MTU has reached 1280 bytes. Are you sure you want to continue? (y/n)"
            if ($continue1280 -ne 'y') {
                return $currentMTU + 1
            }
            $warning1280Shown = $true
        }

        if ($currentMTU -eq 576 -and -not $warning576Shown) {
            $continue576 = Read-Host "MTU has reached 576 bytes. You risk losing your network connection if the byte size becomes too small. Do you want to continue? (y/n)"
            if ($continue576 -ne 'y') {
                return $currentMTU + 1
            }
            $warning576Shown = $true
        }

        if ($Randomize) {
            $TestServer = $TestServers | Get-Random
        } else {
            $TestServer = $TestServers[0]
        }

        Write-Host "Testing MTU: $currentMTU with server: $TestServer"

        $pingResult = & ping.exe -f -l $currentMTU -n 1 -w 500 $TestServer 2>&1
        if ($pingResult -notcontains "Packet needs to be fragmented but DF set.") {
            return $currentMTU
        }
    }

    return $minMTU
}

function Set-AdapterMTUSetting {
    param ([string]$SettingType)

    $persistent = $SettingType -eq "persistent"
    Write-Host "Setting $SettingType MTU..."

    $adapters = Get-NetworkAdapters
    if ($adapters.Count -eq 0) {
        Write-Host "No network adapters found."
        return
    }

    $adapters | ForEach-Object { $i = [array]::IndexOf($adapters, $_) + 1; Write-Host "$i. $($_.Name) - $($_.InterfaceDescription) - $($_.Status)" }

    Write-Host ""
    $adapterIndex = [int](Read-Host "Select a network adapter to set $SettingType MTU setting (enter the number)")
    $selectedAdapter = $adapters[$adapterIndex - 1]

    if ($null -eq $selectedAdapter) {
        Write-Host "Invalid selection. Exiting."
        return
    }

    $standardMTU = Get-StandardMTU
    if ($null -eq $standardMTU) { return }

    Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $standardMTU -Persistent $persistent
}

function Test-AdapterMTUProcess {
    Write-Host "Note: Testing will only work for adapters that are up/enabled."
    $adapters = Get-NetworkAdapters
    if ($adapters.Count -eq 0) {
        Write-Host "No network adapters found."
        return
    }

    $adapters | ForEach-Object { $i = [array]::IndexOf($adapters, $_) + 1; Write-Host "$i. $($_.Name) - $($_.InterfaceDescription) - $($_.Status)" }
    Write-Host ""

    $adapterIndex = [int](Read-Host "Select a network adapter (enter the number)")
    $selectedAdapter = $adapters[$adapterIndex - 1]
    if ($null -eq $selectedAdapter) {
        Write-Host "Invalid selection. Exiting."
        return
    }

    if ($selectedAdapter.Status -ne 'Up') {
        Write-Host "Selected adapter is not up/enabled. Please enable the adapter before testing."
        return
    }

    $ipAddress = Get-AdapterIPAddress -AdapterName $selectedAdapter.Name
    if ($null -eq $ipAddress) {
        Write-Host "Could not retrieve the IP address of the selected adapter. Exiting."
        return
    }

    $support = Test-IPv4IPv6Support -AdapterName $selectedAdapter.Name

    Show-CommonMTUStandards
    $connectionType = [int](Read-Host "Select a connection type (enter the number)")

    $mtuValues = @{
        1 = 1500
        2 = 9000
        3 = 1492
        4 = 1400
        5 = 2272
        6 = 4352
        7 = 9180
        8 = 576
        9 = 1280
    }

    $startMTU = if ($connectionType -eq 10) { [int](Read-Host "Enter the custom MTU value") } else { $mtuValues[$connectionType] }

    if ($null -eq $startMTU) {
        Write-Host "Invalid selection. Exiting."
        return
    }

    $testServers = @(
        "1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4", "9.9.9.9",
        "149.112.112.112", "208.67.222.222", "208.67.220.220",
        "64.6.64.6", "64.6.65.6", "2606:4700:4700::1111", "2606:4700:4700::1001",
        "2001:4860:4860::8888", "2001:4860:4860::8844", "2620:fe::fe", 
        "2620:fe::9", "2620:119:35::35", "2620:119:53::53"
    )

    Write-Host "  1. Randomize (IPv4)"
    Write-Host "  2. Randomize (IPv6)"
    Write-Host "  3. Randomize (Both)"
    $testServers | ForEach-Object { $i = [array]::IndexOf($testServers, $_) + 4; Write-Host "$i. $_" }
    Write-Host ""

    $serverSelection = Read-Host "Choose a test server (enter the number) or enter a custom server IP"
    
    $testServerIPs = @()
    $isIPv6 = $false
    if ($serverSelection -eq "1") {
        if ($support.IPv4) {
            $testServerIPs = $testServers | Where-Object { $_ -notmatch ":" } | ForEach-Object { $_ }
        } else {
            Write-Host "IPv4 not supported. Exiting."
            return
        }
    } elseif ($serverSelection -eq "2") {
        if ($support.IPv6) {
            $testServerIPs = $testServers | Where-Object { $_ -match ":" } | ForEach-Object { $_ }
            $isIPv6 = $true
        } else {
            Write-Host "IPv6 not supported. Exiting."
            return
        }
    } elseif ($serverSelection -eq "3") {
        $testServerIPs = $testServers
        $isIPv6 = $support.IPv6
    } else {
        if ($serverSelection -match "^\d+$") {
            $selectedServer = $testServers[$serverSelection - 4]
            if ($null -eq $selectedServer) { Write-Host "Invalid selection. Exiting."; return }
            $testServerIPs += $selectedServer
            $isIPv6 = $selectedServer -match ":"
        } else {
            $testServerIPs += $serverSelection
            $isIPv6 = $serverSelection -match ":"
        }
    }

    if ($testServerIPs.Count -eq 0) {
        Write-Host "No test servers available. Exiting."
        return
    }

    $originalActiveMTU = (Get-AdapterMTU -AdapterName $selectedAdapter.Name).ActiveMTU
    $originalPersistentMTU = (Get-AdapterMTU -AdapterName $selectedAdapter.Name).PersistentMTU

    # Ensure $originalMTU is a single integer value
    if ($null -ne $originalActiveMTU -and $originalActiveMTU.GetType().IsArray) {
        $originalActiveMTU = [int]$originalActiveMTU[0]
    } else {
        $originalActiveMTU = [int]$originalActiveMTU
    }

    if ($null -ne $originalPersistentMTU -and $originalPersistentMTU.GetType().IsArray) {
        $originalPersistentMTU = [int]$originalPersistentMTU[0]
    } else {
        $originalPersistentMTU = [int]$originalPersistentMTU
    }

    # Temporarily set the adapter MTU to the starting MTU for the test
    if ($startMTU -ge 576) {
        Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $startMTU -Persistent $false
    } else {
        Write-Host "The MTU value $startMTU is below the minimum acceptable MTU value of 576 bytes. Exiting."
        return
    }

    $maxMTU = Test-MTU -TestServers $testServerIPs -StartMTU $startMTU -Randomize ($serverSelection -match "1|2|3") -IsIPv6 $isIPv6

    Write-Host "The maximum MTU without fragmentation for adapter '$($selectedAdapter.Name)' with IP address '$ipAddress' using test servers: $($testServerIPs -join ", ") is $maxMTU bytes."
    $setMTU = Read-Host "Would you like to set this MTU value for the adapter? (y/n)"
    if ($setMTU -eq 'y') {
        $persistent = Read-Host "Do you want to set it persistently? (y/n)"
        Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $maxMTU -Persistent $false
        if ($persistent -eq 'y') {
            Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $maxMTU -Persistent $true
        }
    } else {
        Write-Host "Reverting MTU to original values."
        Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $originalActiveMTU -Persistent $false
        Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $originalPersistentMTU -Persistent $true
        Write-Host "Reverted to the original MTU: $originalActiveMTU bytes (Active), $originalPersistentMTU bytes (Persistent)."
    }
}

function Get-StandardMTU {
    Write-Host ""
    Write-Host "Connection Types:"
    Write-Host "  1. Ethernet (Standard) - 1500 bytes"
    Write-Host "  2. Ethernet (Jumbo Frames) - 9000 bytes"
    Write-Host "  3. PPPoE - 1492 bytes"
    Write-Host "  4. VPN - 1400 bytes"
    Write-Host "  5. Wireless - 2272 bytes"
    Write-Host "  6. FDDI - 4352 bytes"
    Write-Host "  7. ATM - 9180 bytes"
    Write-Host "  8. IPv4 Minimum MTU - 576 bytes"
    Write-Host "  9. IPv6 Minimum MTU - 1280 bytes"
    Write-Host "  10. Enter custom MTU value"
    Write-Host ""

    $connectionType = [int](Read-Host "Select a connection type to reset MTU to (enter the number)")

    $mtuValues = @{
        1 = 1500
        2 = 9000
        3 = 1492
        4 = 1400
        5 = 2272
        6 = 4352
        7 = 9180
        8 = 576
        9 = 1280
    }

    if ($connectionType -eq 10) {
        return [int](Read-Host "Enter the custom MTU value")
    } elseif ($mtuValues.ContainsKey($connectionType)) {
        return $mtuValues[$connectionType]
    } else {
        Write-Host "Invalid selection. Exiting."
        return $null
    }
}

function Main {
    while ($true) {
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  1. Check MTU settings"
        Write-Host "  2. Test and set MTU"
        Write-Host "  3. Set active MTU setting"
        Write-Host "  4. Set persistent MTU setting"
        Write-Host "  5. Enable network adapter"
        Write-Host "  6. Disable network adapter"
        Write-Host "  7. Exit"
        Write-Host ""
        
        $option = [int](Read-Host "Select an option (enter the number)")
        
        switch ($option) {
            1 { Show-MTUSettings }
            2 { Test-AdapterMTUProcess }
            3 { Set-AdapterMTUSetting -SettingType "active" }
            4 { Set-AdapterMTUSetting -SettingType "persistent" }
            5 {
                $adapters = Get-NetworkAdapters
                if ($adapters.Count -eq 0) {
                    Write-Host "No network adapters found."
                    break
                }

                $adapters | ForEach-Object { $i = [array]::IndexOf($adapters, $_) + 1; Write-Host "$i. $($_.Name) - $($_.InterfaceDescription) - $($_.Status)" }
                Write-Host ""
                
                $adapterIndex = [int](Read-Host "Select a network adapter to enable (enter the number)")
                $selectedAdapter = $adapters[$adapterIndex - 1]
                
                if ($null -eq $selectedAdapter) {
                    Write-Host "Invalid selection. Exiting."
                } else {
                    Enable-NetworkAdapter -AdapterName $selectedAdapter.Name
                }
            }
            6 {
                $adapters = Get-NetworkAdapters
                if ($adapters.Count -eq 0) {
                    Write-Host "No network adapters found."
                    break
                }

                $adapters | ForEach-Object { $i = [array]::IndexOf($adapters, $_) + 1; Write-Host "$i. $($_.Name) - $($_.InterfaceDescription) - $($_.Status)" }
                Write-Host ""
                
                $adapterIndex = [int](Read-Host "Select a network adapter to disable (enter the number)")
                $selectedAdapter = $adapters[$adapterIndex - 1]
                
                if ($null -eq $selectedAdapter) {
                    Write-Host "Invalid selection. Exiting."
                } else {
                    Disable-NetworkAdapter -AdapterName $selectedAdapter.Name
                }
            }
            7 { Write-Host "Exiting..."; exit }
            default { Write-Host "Invalid selection. Please try again." }
        }
    }
}

Main
