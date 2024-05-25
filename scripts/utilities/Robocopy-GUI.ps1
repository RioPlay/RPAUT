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

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Function to create the main window
function Show-RobocopyGui {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Robocopy GUI" Height="600" Width="800" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.Column="0" Margin="5" VerticalAlignment="Center">Source:</TextBlock>
        <TextBox Name="SourceTextBox" Grid.Row="0" Grid.Column="1" Margin="5"/>
        <Button Name="BrowseSourceButton" Grid.Row="0" Grid.Column="2" Margin="5" Content="Browse"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="5" VerticalAlignment="Center">Destination:</TextBlock>
        <TextBox Name="DestinationTextBox" Grid.Row="1" Grid.Column="1" Margin="5"/>
        <Button Name="BrowseDestinationButton" Grid.Row="1" Grid.Column="2" Margin="5" Content="Browse"/>

        <GroupBox Header="Options" Grid.Row="2" Grid.ColumnSpan="3" Margin="5">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
                <StackPanel Margin="5">
                    <CheckBox Name="MirrorCheckbox" Content="/MIR - Mirror a directory tree (equivalent to /E plus /PURGE)" Margin="5"/>
                    <CheckBox Name="PurgeCheckbox" Content="/PURGE - Delete dest files/dirs that no longer exist in source" Margin="5"/>
                    <CheckBox Name="RestartableCheckbox" Content="/Z - Restartable mode" Margin="5"/>
                    <CheckBox Name="BackupModeCheckbox" Content="/B - Backup mode" Margin="5"/>
                    <CheckBox Name="IncludeSubdirectoriesCheckbox" Content="/S - Copy subdirectories" Margin="5"/>
                    <CheckBox Name="IncludeEmptySubdirectoriesCheckbox" Content="/E - Copy subdirectories, including empty ones" Margin="5"/>
                    <CheckBox Name="ETACheckbox" Content="/ETA - Show estimated time of arrival for copied files" Margin="5"/>
                    <CheckBox Name="TECheckbox" Content="/TEE - Write status output to the console window, as well as to the log file" Margin="5"/>
                    <CheckBox Name="LogPlusCheckbox" Content="/LOG+ - Output status to LOG file (append to existing log)" Margin="5"/>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="MultiThreadCheckbox" Content="/MT - Multithreaded mode (default is 8 threads)" Margin="5"/>
                        <TextBlock VerticalAlignment="Center" Margin="5">/MT value (1-128):</TextBlock>
                        <TextBox Name="MTValueTextBox" Width="50" Margin="5"/>
                    </StackPanel>
                    <CheckBox Name="CopyAllCheckbox" Content="/COPYALL - Copy all file info (equivalent to /COPY:DATSOU)" Margin="5"/>
                    <CheckBox Name="CopyDATSCheckbox" Content="/COPY:DATS - Copy Data, Attributes, Timestamps, Security" Margin="5"/>
                    <CheckBox Name="DCopyCheckbox" Content="/DCOPY:T - Copy directory timestamps" Margin="5"/>
                    <CheckBox Name="NPCheckbox" Content="/NP - No progress - don't display % copied" Margin="5"/>
                    <CheckBox Name="XJCheckbox" Content="/XJ - Exclude junction points" Margin="5"/>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="RCheckbox" Content="/R - Number of retries on failed copies" Margin="5"/>
                        <TextBox Name="RValueTextBox" Width="50" Margin="5"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="WCheckbox" Content="/W - Wait time between retries (in seconds)" Margin="5"/>
                        <TextBox Name="WValueTextBox" Width="50" Margin="5"/>
                    </StackPanel>
                    <CheckBox Name="LCheckbox" Content="/L - List only - don't copy, timestamp or delete any files" Margin="5"/>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="XFCheckbox" Content="/XF - Exclude files" Margin="5"/>
                        <TextBox Name="XFValueTextBox" Width="150" Margin="5"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="XDCheckbox" Content="/XD - Exclude directories" Margin="5"/>
                        <TextBox Name="XDValueTextBox" Width="150" Margin="5"/>
                    </StackPanel>
                    <CheckBox Name="SECFixCheckbox" Content="/SECFIX - Fix file security on all files, even skipped ones" Margin="5"/>
                    <CheckBox Name="TIMFixCheckbox" Content="/TIMFIX - Fix file times on all files, even skipped ones" Margin="5"/>
                    <CheckBox Name="XOCheckbox" Content="/XO - Exclude older files" Margin="5"/>
                    <CheckBox Name="XNCheckbox" Content="/XN - Exclude newer files" Margin="5"/>
                    <CheckBox Name="XCCheckbox" Content="/XC - Exclude changed files" Margin="5"/>
                    <CheckBox Name="XXCheckbox" Content="/XX - Exclude extra files and directories" Margin="5"/>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="XACheckbox" Content="/XA - Exclude files with the given attributes" Margin="5"/>
                        <TextBox Name="XAValueTextBox" Width="150" Margin="5"/>
                    </StackPanel>
                    <CheckBox Name="DSTCheckbox" Content="/DST - Compensate for one-hour DST time differences" Margin="5"/>
                    <CheckBox Name="NoDirEpochCheckbox" Content="/NODCOPY - Do not copy directory timestamps" Margin="5"/>
                    <CheckBox Name="TBDCheckbox" Content="/TBD - Wait for share names to be defined" Margin="5"/>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="RHCheckbox" Content="/RH - Run hours (time range for starting new copies)" Margin="5"/>
                        <TextBox Name="RHValueTextBox" Width="150" Margin="5"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="PFCheckbox" Content="/PF - Check run hours on a per-file basis" Margin="5"/>
                        <TextBox Name="PFValueTextBox" Width="150" Margin="5"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="5">
                        <CheckBox Name="IPGCheckbox" Content="/IPG - Inter-Packet Gap (ms)" Margin="5"/>
                        <TextBox Name="IPGValueTextBox" Width="50" Margin="5"/>
                    </StackPanel>
                </StackPanel>
            </ScrollViewer>
        </GroupBox>

        <TextBlock Name="ErrorMessage" Grid.Row="3" Grid.ColumnSpan="3" Margin="5" Foreground="Red" TextWrapping="Wrap"/>

        <Button Name="RunButton" Grid.Row="4" Grid.ColumnSpan="3" Margin="5" Content="Run Robocopy" Height="40"/>
    </Grid>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Function to check for incompatible options
    function CheckForIncompatibleOptions {
        $incompatibleSwitches = @()
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /S"
        }
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /E"
        }
        if ($window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true -and $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/S and /E"
        }
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("PurgeCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /PURGE"
        }
        if ($window.FindName("CopyAllCheckbox").IsChecked -eq $true -and $window.FindName("CopyDATSCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/COPYALL and /COPY:DATS"
        }
        if ($window.FindName("NPCheckbox").IsChecked -eq $true -and $window.FindName("ETACheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/NP and /ETA"
        }
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("NoDirEpochCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /NODCOPY"
        }
        if ($window.FindName("DCopyCheckbox").IsChecked -eq $true -and $window.FindName("NoDirEpochCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/DCOPY:T and /NODCOPY"
        }
        if ($incompatibleSwitches.Count -gt 0) {
            $errorMessage = "The following switches are incompatible: " + ($incompatibleSwitches -join ", ")
            $window.FindName("ErrorMessage").Text = $errorMessage
        } else {
            $window.FindName("ErrorMessage").Text = ""
        }
    }

    # Add event handlers to checkboxes for immediate validation
    $window.FindName("MirrorCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("MirrorCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("IncludeSubdirectoriesCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("IncludeSubdirectoriesCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("IncludeEmptySubdirectoriesCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("IncludeEmptySubdirectoriesCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("PurgeCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("PurgeCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("CopyAllCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("CopyAllCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("CopyDATSCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("CopyDATSCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("ETACheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("ETACheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("NPCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("NPCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("NoDirEpochCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("NoDirEpochCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })
    $window.FindName("DCopyCheckbox").Add_Checked({
        CheckForIncompatibleOptions
    })
    $window.FindName("DCopyCheckbox").Add_Unchecked({
        CheckForIncompatibleOptions
    })

    $window.FindName("BrowseSourceButton").Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $window.FindName("SourceTextBox").Text = '"' + $folderDialog.SelectedPath + '"'
        }
    })

    $window.FindName("BrowseDestinationButton").Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $window.FindName("DestinationTextBox").Text = '"' + $folderDialog.SelectedPath + '"'
        }
    })

    $window.FindName("RunButton").Add_Click({
        $source = $window.FindName("SourceTextBox").Text
        $destination = $window.FindName("DestinationTextBox").Text
        $options = ""

        # Ensure the correct order of options
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true) { $options += "/MIR " }
        if ($window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true) { $options += "/S " }
        if ($window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) { $options += "/E " }
        if ($window.FindName("PurgeCheckbox").IsChecked -eq $true) { $options += "/PURGE " }
        if ($window.FindName("RestartableCheckbox").IsChecked -eq $true) { $options += "/Z " }
        if ($window.FindName("BackupModeCheckbox").IsChecked -eq $true) { $options += "/B " }
        if ($window.FindName("ETACheckbox").IsChecked -eq $true) { $options += "/ETA " }
        if ($window.FindName("TECheckbox").IsChecked -eq $true) { $options += "/TEE " }
        if ($window.FindName("LogPlusCheckbox").IsChecked -eq $true) { $options += "/LOG+ " }
        if ($window.FindName("MultiThreadCheckbox").IsChecked -eq $true) {
            $mtValue = $window.FindName("MTValueTextBox").Text
            if ($mtValue -match '^\d+$' -and $mtValue -ge 1 -and $mtValue -le 128) {
                $options += "/MT:$mtValue "
            } else {
                $window.FindName("ErrorMessage").Text = "Invalid /MT value. Accepted values are between 1 and 128."
                return
            }
        }
        if ($window.FindName("CopyAllCheckbox").IsChecked -eq $true) { $options += "/COPYALL " }
        if ($window.FindName("CopyDATSCheckbox").IsChecked -eq $true) { $options += "/COPY:DATS " }
        if ($window.FindName("DCopyCheckbox").IsChecked -eq $true) { $options += "/DCOPY:T " }
        if ($window.FindName("NPCheckbox").IsChecked -eq $true) { $options += "/NP " }
        if ($window.FindName("XJCheckbox").IsChecked -eq $true) { $options += "/XJ " }
        if ($window.FindName("RCheckbox").IsChecked -eq $true) {
            $rValue = $window.FindName("RValueTextBox").Text
            if ($rValue -match '^\d+$') {
                $options += "/R:$rValue "
            } else {
                $options += "/R:0 "
            }
        }
        if ($window.FindName("WCheckbox").IsChecked -eq $true) {
            $wValue = $window.FindName("WValueTextBox").Text
            if ($wValue -match '^\d+$') {
                $options += "/W:$wValue "
            } else {
                $options += "/W:0 "
            }
        }
        if ($window.FindName("LCheckbox").IsChecked -eq $true) { $options += "/L " }
        if ($window.FindName("XFCheckbox").IsChecked -eq $true) {
            $xfValue = $window.FindName("XFValueTextBox").Text.Trim('"')
            if ($xfValue) {
                $options += "/XF `"$xfValue`" "
            }
        }
        if ($window.FindName("XDCheckbox").IsChecked -eq $true) {
            $xdValue = $window.FindName("XDValueTextBox").Text.Trim('"')
            if ($xdValue) {
                $options += "/XD `"$xdValue`" "
            }
        }
        if ($window.FindName("SECFixCheckbox").IsChecked -eq $true) { $options += "/SECFIX " }
        if ($window.FindName("TIMFixCheckbox").IsChecked -eq $true) { $options += "/TIMFIX " }
        if ($window.FindName("XOCheckbox").IsChecked -eq $true) { $options += "/XO " }
        if ($window.FindName("XNCheckbox").IsChecked -eq $true) { $options += "/XN " }
        if ($window.FindName("XCCheckbox").IsChecked -eq $true) { $options += "/XC " }
        if ($window.FindName("XXCheckbox").IsChecked -eq $true) { $options += "/XX " }
        if ($window.FindName("XACheckbox").IsChecked -eq $true) {
            $xaValue = $window.FindName("XAValueTextBox").Text.Trim('"')
            if ($xaValue) {
                $options += "/XA `"$xaValue`" "
            }
        }
        if ($window.FindName("DSTCheckbox").IsChecked -eq $true) { $options += "/DST " }
        if ($window.FindName("NoDirEpochCheckbox").IsChecked -eq $true) { $options += "/NODCOPY " }
        if ($window.FindName("TBDCheckbox").IsChecked -eq $true) { $options += "/TBD " }
        if ($window.FindName("RHCheckbox").IsChecked -eq $true) {
            $rhValue = $window.FindName("RHValueTextBox").Text.Trim('"')
            if ($rhValue) {
                $options += "/RH:$rhValue "
            }
        }
        if ($window.FindName("PFCheckbox").IsChecked -eq $true) {
            $pfValue = $window.FindName("PFValueTextBox").Text.Trim('"')
            if ($pfValue) {
                $options += "/PF:$pfValue "
            }
        }
        if ($window.FindName("IPGCheckbox").IsChecked -eq $true) {
            $ipgValue = $window.FindName("IPGValueTextBox").Text
            if ($ipgValue -match '^\d+$') {
                $options += "/IPG:$ipgValue "
            } else {
                $window.FindName("ErrorMessage").Text = "Invalid /IPG value. It should be a number."
                return
            }
        }

        # Error checking for incompatible switches
        $incompatibleSwitches = @()
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /S"
        }
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /E"
        }
        if ($window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true -and $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/S and /E"
        }
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("PurgeCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /PURGE"
        }
        if ($window.FindName("CopyAllCheckbox").IsChecked -eq $true -and $window.FindName("CopyDATSCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/COPYALL and /COPY:DATS"
        }
        if ($window.FindName("NPCheckbox").IsChecked -eq $true -and $window.FindName("ETACheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/NP and /ETA"
        }
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and $window.FindName("NoDirEpochCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MIR and /NODCOPY"
        }
        if ($window.FindName("DCopyCheckbox").IsChecked -eq $true -and $window.FindName("NoDirEpochCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/DCOPY:T and /NODCOPY"
        }
        if ($incompatibleSwitches.Count -gt 0) {
            $errorMessage = "The following switches are incompatible: " + ($incompatibleSwitches -join ", ")
            $window.FindName("ErrorMessage").Text = $errorMessage
            return
        } else {
            $window.FindName("ErrorMessage").Text = ""
        }

        $command = "Robocopy '$source' '$destination' $options"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", $command
    })

    $window.ShowDialog() | Out-Null
}

# Run The GUI
Show-RobocopyGui
