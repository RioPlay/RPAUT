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
function DisplayCommonMTUStandards {
    Write-Host "Common MTU Standards:"
    Write-Host "  - Ethernet (Standard): 1500 bytes"
    Write-Host "  - Ethernet (Jumbo Frames): 9000 bytes"
    Write-Host "  - PPPoE: 1492 bytes"
    Write-Host "  - VPN: 1400 bytes"
    Write-Host "  - Wireless: 2272 bytes"
    Write-Host "  - FDDI: 4352 bytes"
    Write-Host "  - ATM: 9180 bytes"
    Write-Host "  - IPv4 Minimum MTU: 576 bytes"
    Write-Host "  - IPv6 Minimum MTU: 1280 bytes"
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
        [string]$TestServer,
        [int]$StartMTU,
        [bool]$Randomize
    )

    # Initial values
    $maxMTU = $StartMTU  # Starting from the specified MTU
    $minMTU = 1280  # Lower bound for IPv6

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
        @{IP="8.26.56.26"; Name="Comodo Secure DNS"},
        @{IP="8.20.247.20"; Name="Comodo Secure DNS"},
        @{IP="77.88.8.8"; Name="Yandex DNS"},
        @{IP="77.88.8.1"; Name="Yandex DNS"},
        @{IP="84.200.69.80"; Name="DNS.WATCH"},
        @{IP="84.200.70.40"; Name="DNS.WATCH"}
    )

    for ($currentMTU = $maxMTU; $currentMTU -ge $minMTU; $currentMTU--) {
        if ($Randomize) {
            $randomServer = $testServers | Get-Random
            $TestServer = $randomServer.IP
            Write-Host "Testing MTU: $currentMTU with randomized server: $TestServer"
        } else {
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
function Set-MTU {
    param (
        [string]$AdapterName,
        [int]$MTU,
        [bool]$Persistent
    )

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }

    if ($Persistent) {
        Write-Host "Setting MTU for adapter '$AdapterName' to $MTU bytes persistently."
        Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore PersistentStore
        #Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore ActiveStore
    } else {
        Write-Host "Setting MTU for adapter '$AdapterName' to $MTU bytes for this session."
        Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore ActiveStore
    }
}

# Remove persistent MTU settings
function Set-PersistentMTU {
    param (
        [string]$AdapterName,
        [int]$MTU
    )

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }

    Write-Host "Setting persistent MTU setting for adapter '$AdapterName'."
    Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore PersistentStore
}

# Remove active MTU settings
function Set-ActiveMTU {
    param (
        [string]$AdapterName,
        [int]$MTU
    )

    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $AdapterName }

    Write-Host "Removing active MTU setting for adapter '$AdapterName'."
    Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -NlMtu $MTU -PolicyStore ActiveStore
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
function Test-MTU-Process {
    while ($true) {
        # Get all network adapters
        $adapters = Get-NetworkAdapters

        if ($adapters.Count -eq 0) {
            Write-Host "No active network adapters found."
            break
        }

        # Display the adapters to the user with description
        $adapters | ForEach-Object {
            $i = [array]::IndexOf($adapters, $_) + 1
            Write-Host "$i. $($_.Name) - $($_.InterfaceDescription)"
        }

        # Print a newline after listing all adapters
        Write-Host ""

        # Prompt the user to select an adapter
        $adapterIndex = Read-Host "Select a network adapter (enter the number)"
        $selectedAdapter = $adapters[$adapterIndex - 1]

        if ($null -eq $selectedAdapter) {
            Write-Host "Invalid selection. Exiting."
            break
        }

        # Get the IP address of the selected adapter
        $ipAddress = Get-AdapterIPAddress -AdapterName $selectedAdapter.Name

        if ($null -eq $ipAddress) {
            Write-Host "Could not retrieve the IP address of the selected adapter. Exiting."
            break
        }

        # Prompt the user to select a connection type
        Write-Host ""
        Write-Host "Connection Types:"
        Write-Host "  1. Ethernet (Standard)"
        Write-Host "  2. Ethernet (Jumbo Frames)"
        Write-Host "  3. PPPoE"
        Write-Host "  4. VPN"
        Write-Host "  5. Wireless"
        Write-Host "  6. FDDI"
        Write-Host "  7. ATM"
        Write-Host "  8. IPv4 Minimum MTU"
        Write-Host "  9. IPv6 Minimum MTU"
        Write-Host ""

        $connectionType = Read-Host "Select a connection type (enter the number)"

        # Set the starting MTU based on the connection type
        switch ($connectionType) {
            1 { $startMTU = 1500 }
            2 { $startMTU = 9000 }
            3 { $startMTU = 1492 }
            4 { $startMTU = 1400 }
            5 { $startMTU = 2272 }
            6 { $startMTU = 4352 }
            7 { $startMTU = 9180 }
            8 { $startMTU = 576 }
            9 { $startMTU = 1280 }
            default {
                Write-Host "Invalid selection. Exiting."
                break
            }
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
            @{IP="8.26.56.26"; Name="Comodo Secure DNS"},
            @{IP="8.20.247.20"; Name="Comodo Secure DNS"},
            @{IP="77.88.8.8"; Name="Yandex DNS"},
            @{IP="77.88.8.1"; Name="Yandex DNS"},
            @{IP="84.200.69.80"; Name="DNS.WATCH"},
            @{IP="84.200.70.40"; Name="DNS.WATCH"}
        )

        # Display the test servers to the user
        $testServers | ForEach-Object {
            $i = [array]::IndexOf($testServers, $_) + 1
            Write-Host "$i. $($_.IP) ($($_.Name))"
        }

        # Print a newline after listing all servers
        Write-Host ""

        # Prompt the user to select a test server or enter a custom one
        $serverIndex = Read-Host "Choose a test server (enter the number) or enter a custom server IP"
        if ($serverIndex -match "^\d+$") {
            $selectedServer = $testServers[$serverIndex - 1]
            if ($null -eq $selectedServer) {
                Write-Host "Invalid selection. Exiting."
                break
            }
            $testServerIP = $selectedServer.IP
        } else {
            $testServerIP = $serverIndex
        }

        # Ask the user if they want to randomize servers when testing MTU
        $randomizeResponse = Read-Host "Would you like to randomize servers when testing MTU? (y/n)"
        $randomize = $randomizeResponse -eq 'y'

        # Test for the maximum MTU without fragmentation
        $maxMTU = Test-MTU -TestServer $testServerIP -StartMTU $startMTU -Randomize $randomize

        Write-Host ""
        Write-Host "The maximum MTU without fragmentation for adapter '$($selectedAdapter.Name)' with IP address '$ipAddress' using test server '$testServerIP' is $maxMTU bytes."
        Write-Host ""

        # Ask the user if they want to set this MTU value
        $setMTU = Read-Host "Would you like to set this MTU value for the adapter? (y/n)"
        if ($setMTU -eq 'y') {
            # Ask the user if they want to set it persistently
            $persistent = Read-Host "Do you want to set it persistently? (y/n)"
            $persistent = $persistent -eq 'y'
            Set-MTU -AdapterName $selectedAdapter.Name -MTU $maxMTU -Persistent $persistent
        }

        # Ask the user if they want to test again
        $response = Read-Host "Would you like to test again? (y/n)"
        if ($response -ne 'y') {
            break
        }
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
    Write-Host ""

    $connectionType = Read-Host "Select a connection type to reset MTU to (enter the number)"

    # Return the corresponding MTU value based on the selected connection type
    switch ($connectionType) {
        1 { return 1500 }
        2 { return 9000 }
        3 { return 1492 }
        4 { return 1400 }
        5 { return 2272 }
        6 { return 4352 }
        7 { return 9180 }
        8 { return 576 }
        9 { return 1280 }
        default {
            Write-Host "Invalid selection. Exiting."
            return $null
        }
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
        
        $option = Read-Host "Select an option (enter the number)"
        
        switch ($option) {
            1 {
                Get-MTU
            }
            2 {
                Test-MTU-Process
            }
            3 {
                # Get all network adapters
                $adapters = Get-NetworkAdapters

                if ($adapters.Count -eq 0) {
                    Write-Host "No active network adapters found."
                    break
                }

                # Display the adapters to the user with description
                $adapters | ForEach-Object {
                    $i = [array]::IndexOf($adapters, $_) + 1
                    Write-Host "$i. $($_.Name) - $($_.InterfaceDescription)"
                }

                # Print a newline after listing all adapters
                Write-Host ""

                # Prompt the user to select an adapter
                $adapterIndex = Read-Host "Select a network adapter to remove persistent MTU setting (enter the number)"
                $selectedAdapter = $adapters[$adapterIndex - 1]

                if ($null -eq $selectedAdapter) {
                    Write-Host "Invalid selection. Exiting."
                    break
                }

                # Prompt the user to select a connection type to reset MTU to
                $standardMTU = Get-StandardMTU
                if ($null -eq $standardMTU) {
                    break
                }

                Set-PersistentMTU -AdapterName $selectedAdapter.Name -MTU $standardMTU
            }
            4 {
                # Get all network adapters
                $adapters = Get-NetworkAdapters

                if ($adapters.Count -eq 0) {
                    Write-Host "No active network adapters found."
                    break
                }

                # Display the adapters to the user with description
                $adapters | ForEach-Object {
                    $i = [array]::IndexOf($adapters, $_) + 1
                    Write-Host "$i. $($_.Name) - $($_.InterfaceDescription)"
                }

                # Print a newline after listing all adapters
                Write-Host ""

                # Prompt the user to select an adapter
                $adapterIndex = Read-Host "Select a network adapter to remove active MTU setting (enter the number)"
                $selectedAdapter = $adapters[$adapterIndex - 1]

                if ($null -eq $selectedAdapter) {
                    Write-Host "Invalid selection. Exiting."
                    break
                }

                # Prompt the user to select a connection type to reset MTU to
                $standardMTU = Get-StandardMTU
                if ($null -eq $standardMTU) {
                    break
                }

                Remove-ActiveMTU -AdapterName $selectedAdapter.Name -MTU $standardMTU
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
