<#
MIT License

Copyright (c) 2024 RioPlay

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

# Display common MTU standards
function Get-CommonMTUStandards {
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

# Get network adapters
function Get-NetworkAdapters {
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
}

# Get the MTU settings of a specific network adapter
function Get-AdapterMTU {
    param (
        [string]$AdapterName
    )

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }
    $persistentMTU = Get-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -PolicyStore PersistentStore | Select-Object -ExpandProperty NlMtu -ErrorAction SilentlyContinue
    $activeMTU = Get-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -PolicyStore ActiveStore | Select-Object -ExpandProperty NlMtu -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        AdapterName           = $adapter.Name
        InterfaceDescription  = $adapter.InterfaceDescription
        ActiveMTU             = $activeMTU
        PersistentMTU         = $persistentMTU
    }
}

# Get the IP address of a network adapter
function Get-AdapterIPAddress {
    param (
        [string]$AdapterName
    )

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }
    $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex | Where-Object { $_.AddressFamily -eq 'IPv4' }

    return $ipConfig.IPAddress
}

# Find the maximum MTU without fragmentation using ping.exe
function Test-MTU {
    param (
        [string[]]$TestServers,
        [int]$StartMTU,
        [bool]$Randomize
    )

    # Initial values
    $maxMTU = $StartMTU  # Starting from the specified MTU
    $minMTU = 1280  # Lower bound for IPv6

    for ($currentMTU = $maxMTU; $currentMTU -ge $minMTU; $currentMTU--) {
        if ($Randomize) {
            $TestServer = $TestServers | Get-Random
            Write-Host "Testing MTU: $currentMTU with randomized server: $TestServer"
        } else {
            $TestServer = $TestServers[0]
            Write-Host "Testing MTU: $currentMTU with server: $TestServer"
        }

        # Perform ping test using ping.exe
        $pingResult = & ping.exe -f -l $currentMTU -n 1 -w 500 $TestServer 2>&1

        if ($pingResult -notcontains "Packet needs to be fragmented but DF set.") {
            return $currentMTU
        }
    }

    return $minMTU
}

# Set the MTU for a network adapter
function Set-AdapterMTU {
    param (
        [string]$AdapterName,
        [int]$MTU,
        [bool]$Persistent
    )

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }

    if ($Persistent) {
        Write-Host "Setting MTU for adapter '$AdapterName' to $MTU bytes persistently."
        Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore PersistentStore
    } else {
        Write-Host "Setting MTU for adapter '$AdapterName' to $MTU bytes for this session."
        Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore ActiveStore
    }
}

# Check MTU settings
function Get-MTU {
    # Get all network adapters
    $adapters = Get-NetworkAdapters

    if ($adapters.Count -eq 0) {
        Write-Host "No active network adapters found."
        return
    }

    $adapterMTUs = $adapters | ForEach-Object {
        Get-AdapterMTU -AdapterName $_.Name
    }

    $adapterMTUs | Format-Table AdapterName, InterfaceDescription, ActiveMTU, PersistentMTU
}

# Process to test and set MTU
function Test-IPv4IPv6Support {
    param (
        [string]$AdapterName
    )

    $adapter = Get-NetAdapter -Name $AdapterName
    $ipv4Enabled = $false
    $ipv6Enabled = $false

    try {
        $ipv4Interfaces = $adapter | Get-NetIPInterface -AddressFamily IPv4 -ErrorAction Stop
        if ($ipv4Interfaces) {
            $ipv4Enabled = $true
        }
    } catch {
        $ipv4Enabled = $false
    }

    try {
        $ipv6Interfaces = $adapter | Get-NetIPInterface -AddressFamily IPv6 -ErrorAction Stop
        if ($ipv6Interfaces) {
            $ipv6Enabled = $true
        }
    } catch {
        $ipv6Enabled = $false
    }

    return @{
        IPv4 = $ipv4Enabled
        IPv6 = $ipv6Enabled
    }
}

function Get-MainMenu {
    Write-Host "    MTU Tool Main Menu"
    Write-Host "Options:"
    Write-Host "  1. Check MTU settings"
    Write-Host "  2. Test and set MTU"
    Write-Host "  3. Set persistent MTU setting"
    Write-Host "  4. Set active MTU setting"
    Write-Host "  5. Exit"
}

function Set-AdapterMTUSetting {
    param (
        [string]$SettingType
    )

    $persistent = $SettingType -eq "persistent"
    Write-Host "Setting $SettingType MTU..."

    # Get all network adapters
    $adapters = Get-NetworkAdapters

    if ($adapters.Count -eq 0) {
        Write-Host "No active network adapters found."
        return
    }

    # Display the adapters to the user with description
    $adapters | ForEach-Object {
        $i = [array]::IndexOf($adapters, $_) + 1
        Write-Host "$i. $($_.Name) - $($_.InterfaceDescription)"
    }

    # Print a newline after listing all adapters
    Write-Host ""

    # Prompt the user to select an adapter
    $adapterIndex = [int](Read-Host "Select a network adapter to set $SettingType MTU setting (enter the number)")
    $selectedAdapter = $adapters[$adapterIndex - 1]

    if ($null -eq $selectedAdapter) {
        Write-Host "Invalid selection. Exiting."
        return
    }

    # Prompt the user to select a connection type to reset MTU to
    $standardMTU = Get-StandardMTU
    if ($null -eq $standardMTU) {
        return
    }

    Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $standardMTU -Persistent $persistent
}

function Test-AdapterMTUProcess {
    # Get all network adapters
    $adapters = Get-NetworkAdapters

    if ($adapters.Count -eq 0) {
        Write-Host "No active network adapters found."
        return
    }

    # Display the adapters to the user with description
    $adapters | ForEach-Object {
        $i = [array]::IndexOf($adapters, $_) + 1
        Write-Host "$i. $($_.Name) - $($_.InterfaceDescription)"
    }

    # Print a newline after listing all adapters
    Write-Host ""

    # Prompt the user to select an adapter
    $adapterIndex = [int](Read-Host "Select a network adapter (enter the number)")
    $selectedAdapter = $adapters[$adapterIndex - 1]

    if ($null -eq $selectedAdapter) {
        Write-Host "Invalid selection. Exiting."
        return
    }

    # Get the IP address of the selected adapter
    $ipAddress = Get-AdapterIPAddress -AdapterName $selectedAdapter.Name

    if ($null -eq $ipAddress) {
        Write-Host "Could not retrieve the IP address of the selected adapter. Exiting."
        return
    }

    # Check IPv4 and IPv6 support
    $support = Test-IPv4IPv6Support -AdapterName $selectedAdapter.Name

    # Prompt the user to select a connection type
    Get-CommonMTUStandards
    $connectionType = [int](Read-Host "Select a connection type (enter the number)")

    # Set the starting MTU based on the connection type
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
        $startMTU = [int](Read-Host "Enter the custom MTU value")
    } elseif (-not $mtuValues.ContainsKey($connectionType)) {
        Write-Host "Invalid selection. Exiting."
        return
    } else {
        $startMTU = $mtuValues[$connectionType]
    }

    # List of available test servers with parent company names
    $testServers = @(
        @{IP="1.1.1.1"; Name="Cloudflare"},
        @{IP="1.0.0.1"; Name="Cloudflare"},
        @{IP="8.8.8.8"; Name="Google"},
        @{IP="8.8.4.4"; Name="Google"},
        @{IP="9.9.9.9"; Name="Quad9"},
        @{IP="149.112.112.112"; Name="Quad9 (Secure)"},
        @{IP="208.67.222.222"; Name="OpenDNS (Cisco)"},
        @{IP="208.67.220.220"; Name="OpenDNS (Cisco)"},
        @{IP="64.6.64.6"; Name="Verisign"},
        @{IP="64.6.65.6"; Name="Verisign"},
        @{IP="2606:4700:4700::1111"; Name="Cloudflare (IPv6)"},
        @{IP="2606:4700:4700::1001"; Name="Cloudflare (IPv6)"},
        @{IP="2001:4860:4860::8888"; Name="Google (IPv6)"},
        @{IP="2001:4860:4860::8844"; Name="Google (IPv6)"},
        @{IP="2620:fe::fe"; Name="Quad9 (IPv6)"},
        @{IP="2620:fe::9"; Name="Quad9 (Secure, IPv6)"},
        @{IP="2620:119:35::35"; Name="OpenDNS (Cisco, IPv6)"},
        @{IP="2620:119:53::53"; Name="OpenDNS (Cisco, IPv6)"}
    )

    # Display the test servers to the user
    Write-Host "  1. Randomize (IPv4)"
    Write-Host "  2. Randomize (IPv6)"
    Write-Host "  3. Randomize (Both)"
    $testServers | ForEach-Object {
        $i = [array]::IndexOf($testServers, $_) + 4
        Write-Host "$i. $($_.IP) ($($_.Name))"
    }

    # Print a newline after listing all servers
    Write-Host ""

    # Prompt the user to select a test server or enter a custom one
    while ($true) {
        $serverIndex = Read-Host "Choose a test server (enter the number) or enter a custom server IP"
        if ($serverIndex -eq "1") {
            if (-not $support.IPv4) {
                Write-Host "IPv4 is not supported or currently enabled on the selected adapter. Exiting."
                return
            }
            $randomize = "IPv4"
            $testServerIP = $null
            break
        } elseif ($serverIndex -eq "2") {
            if (-not $support.IPv6) {
                Write-Host "IPv6 is not supported or currently enabled on the selected adapter. Exiting."
                return
            }
            $randomize = "IPv6"
            $testServerIP = $null
            break
        } elseif ($serverIndex -eq "3") {
            $randomize = "Both"
            $testServerIP = $null
            break
        } elseif ($serverIndex -match "^\d+$") {
            $selectedServer = $testServers[$serverIndex - 4]
            if ($null -eq $selectedServer) {
                Write-Host "Invalid selection. Try again."
            } elseif ($selectedServer.IP -match ":") {
                if (-not $support.IPv6) {
                    Write-Host "IPv6 is not supported on the selected adapter. Try another server."
                } else {
                    $testServerIP = $selectedServer.IP
                    $randomize = $false
                    break
                }
            } else {
                if (-not $support.IPv4) {
                    Write-Host "IPv4 is not supported on the selected adapter. Try another server."
                } else {
                    $testServerIP = $selectedServer.IP
                    $randomize = $false
                    break
                }
            }
        } else {
            $testServerIP = $serverIndex
            if ($testServerIP -match ":") {
                if (-not $support.IPv6) {
                    Write-Host "IPv6 is not supported on the selected adapter. Try another server."
                } else {
                    $randomize = $false
                    break
                }
            } else {
                if (-not $support.IPv4) {
                    Write-Host "IPv4 is not supported on the selected adapter. Try another server."
                } else {
                    $randomize = $false
                    break
                }
            }
        }
    }

    # Select appropriate test servers based on randomization selection
    switch ($randomize) {
        "IPv4" {
            $testServerIPs = $testServers | Where-Object { $_.IP -notmatch ":" } | ForEach-Object { $_.IP }
            if ($testServerIPs.Count -eq 0) {
                Write-Host "No IPv4 servers available. Falling back to IPv6."
                $randomize = "IPv6"
                $testServerIPs = $testServers | Where-Object { $_.IP -match ":" } | ForEach-Object { $_.IP }
                if ($testServerIPs.Count -eq 0) {
                    Write-Host "No IPv6 servers available either. Cannot proceed with testing."
                    return
                }
            }
        }
        "IPv6" {
            $testServerIPs = $testServers | Where-Object { $_.IP -match ":" } | ForEach-Object { $_.IP }
            if ($testServerIPs.Count -eq 0) {
                Write-Host "No IPv6 servers available. Falling back to IPv4."
                $randomize = "IPv4"
                $testServerIPs = $testServers | Where-Object { $_.IP -notmatch ":" } | ForEach-Object { $_.IP }
                if ($testServerIPs.Count -eq 0) {
                    Write-Host "No IPv4 servers available either. Cannot proceed with testing."
                    return
                }
            }
        }
        "Both" {
            $testServerIPs = $testServers | ForEach-Object { $_.IP }
        }
        default {
            $testServerIPs = @($testServerIP)
        }
    }

    if ($testServerIPs.Count -eq 0) {
        Write-Host "No test servers available. Exiting."
        return
    }

    # Test for the maximum MTU without fragmentation
    $maxMTU = Test-MTU -TestServers $testServerIPs -StartMTU $startMTU -Randomize ($randomize -ne $false)

    # Warn if MTU is 1280 bytes or less
    if ($maxMTU -le 1280) {
        $continue1280 = Read-Host "MTU has reached 1280 bytes. Are you sure you want to continue? (y/n)"
        if ($continue1280 -ne 'y') {
            return
        }
    }

    # Warn if MTU is 576 bytes or less
    if ($maxMTU -le 576) {
        $continue576 = Read-Host "MTU has reached 576 bytes. You risk losing your network connection if the byte size becomes too small. Do you want to continue? (y/n)"
        if ($continue576 -ne 'y') {
            return
        }
    }

    Write-Host ""
    Write-Host "The maximum MTU without fragmentation for adapter '$($selectedAdapter.Name)' with IP address '$ipAddress' using test servers: $($testServerIPs -join ", ") is $maxMTU bytes."
    Write-Host ""

    # Ask the user if they want to set this MTU value
    $setMTU = Read-Host "Would you like to set this MTU value for the adapter? (y/n)"
    if ($setMTU -eq 'y') {
        # Ask the user if they want to set it persistently
        $persistent = Read-Host "Do you want to set it persistently? (y/n)"
        $persistent = $persistent -eq 'y'
        Set-AdapterMTU -AdapterName $selectedAdapter.Name -MTU $maxMTU -Persistent $persistent
    }
}

# Prompt the user to select a connection type and get the corresponding MTU value
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

    # Return the corresponding MTU value based on the selected connection type
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

# Main function
function Main {
    while ($true) {
        # Display options to the user
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  1. Check MTU settings"
        Write-Host "  2. Test and set MTU"
        Write-Host "  3. Set persistent MTU setting"
        Write-Host "  4. Set active MTU setting"
        Write-Host "  5. Exit"
        Write-Host ""
        
        $option = [int](Read-Host "Select an option (enter the number)")
        
        switch ($option) {
            1 {
                Get-MTU
            }
            2 {
                Test-AdapterMTUProcess
            }
            3 {
                Set-AdapterMTUSetting -SettingType "persistent"
            }
            4 {
                Set-AdapterMTUSetting -SettingType "active"
            }
            5 {
                Write-Host "Exiting..."
                exit
            }
            default {
                Write-Host "Invalid selection. Please try again."
            }
        }
    }
}

# Run the main function
Main
