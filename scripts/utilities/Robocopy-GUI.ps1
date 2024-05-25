<#
MIT License

...
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Function to create the main window
function Show-RobocopyGui {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Robocopy GUI" Height="700" Width="800" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="10">
            <Grid Margin="5">
                <Grid.RowDefinitions>
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
            </Grid>
        </StackPanel>

        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
            <StackPanel Margin="10">

                <GroupBox Header="Common Options" Margin="5">
                    <StackPanel Name="CommonOptionsPanel" Margin="5">
                        <CheckBox Name="MirrorCheckbox" Content="/MIR - Mirror a directory tree (equivalent to /E plus /PURGE)" Margin="5"/>
                        <CheckBox Name="IncludeSubdirectoriesCheckbox" Content="/S - Copy subdirectories" Margin="5"/>
                        <CheckBox Name="IncludeEmptySubdirectoriesCheckbox" Content="/E - Copy subdirectories, including empty ones" Margin="5"/>
                        <CheckBox Name="PurgeCheckbox" Content="/PURGE - Delete dest files/dirs that no longer exist in source" Margin="5"/>
                        <CheckBox Name="RestartableCheckbox" Content="/Z - Restartable mode" Margin="5"/>
                        <CheckBox Name="BackupModeCheckbox" Content="/B - Backup mode" Margin="5"/>
                        <CheckBox Name="SecCheckbox" Content="/SEC - Copy files with SECurity (equivalent to /COPY:DATS)" Margin="5"/>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="File Selection Options" Margin="5">
                    <StackPanel Name="FileSelectionOptionsPanel" Margin="5">
                        <CheckBox Name="AOnlyCheckbox" Content="/A - Copy only files with the Archive attribute set" Margin="5"/>
                        <CheckBox Name="MCheckbox" Content="/M - Copy only files with the Archive attribute and reset it" Margin="5"/>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="IncludeAttributesCheckbox" Content="/IA - Include only files with any of the given attributes" Margin="5"/>
                            <TextBox Name="IAValueTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="ExcludeAttributesCheckbox" Content="/XA - Exclude files with any of the given attributes" Margin="5"/>
                            <TextBox Name="XAValueTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Retry Options" Margin="5">
                    <StackPanel Name="RetryOptionsPanel" Margin="5">
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="RCheckbox" Content="/R - Number of retries on failed copies" Margin="5"/>
                            <TextBox Name="RValueTextBox" Width="50" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="WCheckbox" Content="/W - Wait time between retries (in seconds)" Margin="5"/>
                            <TextBox Name="WValueTextBox" Width="50" Margin="5"/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Logging Options" Margin="5">
                    <StackPanel Name="LoggingOptionsPanel" Margin="5">
                        <CheckBox Name="LCheckbox" Content="/L - List only - don’t copy, timestamp, or delete any files" Margin="5"/>
                        <CheckBox Name="XCheckbox" Content="/X - Report all extra files, not just those selected" Margin="5"/>
                        <CheckBox Name="VCheckbox" Content="/V - Produce Verbose output, showing skipped files" Margin="5"/>
                        <CheckBox Name="NPCheckbox" Content="/NP - No progress - don’t display percentage copied" Margin="5"/>
                        <CheckBox Name="LogCheckbox" Content="/LOG - Output status to LOG file (overwrite existing log)" Margin="5"/>
                        <CheckBox Name="LogPlusCheckbox" Content="/LOG+ - Output status to LOG file (append to existing log)" Margin="5"/>
                        <CheckBox Name="ETACheckbox" Content="/ETA - Show estimated time of arrival for copied files" Margin="5"/>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Job Options" Margin="5">
                    <StackPanel Name="JobOptionsPanel" Margin="5">
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="JobCheckbox" Content="/JOB - Take parameters from the named job file" Margin="5"/>
                            <TextBox Name="JobValueTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="SaveJobCheckbox" Content="/SAVE - Save parameters to the named job file" Margin="5"/>
                            <TextBox Name="SaveJobValueTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                        <CheckBox Name="QuitCheckbox" Content="/QUIT - Quit after processing command line (to view parameters)" Margin="5"/>
                        <CheckBox Name="NoSourceDirCheckbox" Content="/NOSD - No source directory is specified" Margin="5"/>
                        <CheckBox Name="NoDestDirCheckbox" Content="/NODD - No destination directory is specified" Margin="5"/>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Advanced Options" Margin="5">
                    <StackPanel Name="AdvancedOptionsPanel" Margin="5">
                        <CheckBox Name="CopyDATSCheckbox" Content="/COPY:DATS - Copy Data, Attributes, Timestamps, Security" Margin="5"/>
                        <CheckBox Name="DCopyCheckbox" Content="/DCOPY:T - Copy Directory Timestamps" Margin="5"/>
                        <CheckBox Name="CreateCheckbox" Content="/CREATE - CREATE directory tree and zero-length files only" Margin="5"/>
                        <CheckBox Name="FatCheckbox" Content="/FAT - Use 8.3 FAT file names only" Margin="5"/>
                        <CheckBox Name="LongPathCheckbox" Content="/256 - Turn off very long path (> 256 characters) support" Margin="5"/>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="MonCheckbox" Content="/MON - Monitor source; run again when more than n changes seen" Margin="5"/>
                            <TextBox Name="MonValueTextBox" Width="50" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="MotCheckbox" Content="/MOT - Monitor source; run again in m minutes if changes seen" Margin="5"/>
                            <TextBox Name="MotValueTextBox" Width="50" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="RHCheckbox" Content="/RH - Run hours (time range for starting new copies)" Margin="5"/>
                            <TextBox Name="RHValueTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="PFCheckbox" Content="/PF - Check run hours on a Per File basis" Margin="5"/>
                            <TextBox Name="PFValueTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="AddAttrCheckbox" Content="/A+ - Add the given attributes to copied files" Margin="5"/>
                            <TextBox Name="AddAttrTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="RemoveAttrCheckbox" Content="/A- - Remove the given attributes from copied files" Margin="5"/>
                            <TextBox Name="RemoveAttrTextBox" Width="150" Margin="5"/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Multithreading Options" Margin="5">
                    <StackPanel Name="MultithreadingOptionsPanel" Margin="5">
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="MultiThreadCheckbox" Content="/MT - Multithreaded mode (default is 8 threads)" Margin="5"/>
                            <TextBlock VerticalAlignment="Center" Margin="5">/MT value (1-128):</TextBlock>
                            <TextBox Name="MTValueTextBox" Width="50" Margin="5"/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Network Options" Margin="5">
                    <StackPanel Name="NetworkOptionsPanel" Margin="5">
                        <StackPanel Orientation="Horizontal" Margin="5">
                            <CheckBox Name="IPGCheckbox" Content="/IPG - Inter-Packet Gap (ms)" Margin="5"/>
                            <TextBox Name="IPGValueTextBox" Width="50" Margin="5"/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Copy Options" Margin="5">
                    <StackPanel Name="CopyOptionsPanel" Margin="5">
                        <CheckBox Name="ZBCheckbox" Content="/ZB - Use restartable mode; if access denied use Backup mode" Margin="5"/>
                        <CheckBox Name="JCheckbox" Content="/J - Copy using unbuffered I/O (recommended for large files)" Margin="5"/>
                    </StackPanel>
                </GroupBox>

            </StackPanel>
        </ScrollViewer>

        <StackPanel Grid.Row="2" Margin="10">
            <TextBlock Name="ErrorMessage" Foreground="Red" TextWrapping="Wrap" Margin="5"/>
            <Button Name="RunButton" Content="Run Robocopy" Height="40" Margin="5"/>
        </StackPanel>
    </Grid>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Function to show error message for 5 seconds
    function ShowErrorMessage($message) {
        $window.Dispatcher.Invoke([action] {
            $window.FindName("ErrorMessage").Text = $message
        })
        $timer = New-Object Timers.Timer
        $timer.Interval = 5000
        $timer.AutoReset = $false
        $timer.add_Elapsed({
            $window.Dispatcher.Invoke([action] {
                $window.FindName("ErrorMessage").Text = ""
            })
        })
        $timer.Start()
    }

    # Function to handle checkbox changes and ensure mutually exclusive options
    function HandleCheckboxChange {
        param ($checkbox)
        $incompatibleSwitches = @()
        $conflictMessage = ""

        switch ($checkbox.Name) {
            "MirrorCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true) { $conflictMessage = "/MIR conflicts with /S"; $window.FindName("IncludeSubdirectoriesCheckbox").IsChecked = $false }
                    if ($window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) { $conflictMessage = "/MIR conflicts with /E"; $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked = $false }
                    if ($window.FindName("PurgeCheckbox").IsChecked -eq $true) { $conflictMessage = "/MIR conflicts with /PURGE"; $window.FindName("PurgeCheckbox").IsChecked = $false }
                    if ($window.FindName("NoSourceDirCheckbox").IsChecked -eq $true) { $conflictMessage = "/MIR conflicts with /NOSD"; $window.FindName("NoSourceDirCheckbox").IsChecked = $false }
                    if ($window.FindName("MOVCheckbox").IsChecked -eq $true) { $conflictMessage = "/MIR conflicts with /MOV"; $window.FindName("MOVCheckbox").IsChecked = $false }
                }
            }
            "IncludeSubdirectoriesCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("MirrorCheckbox").IsChecked -eq $true) { $conflictMessage = "/S conflicts with /MIR"; $window.FindName("MirrorCheckbox").IsChecked = $false }
                    if ($window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) { $conflictMessage = "/S conflicts with /E"; $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked = $false }
                }
            }
            "IncludeEmptySubdirectoriesCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("MirrorCheckbox").IsChecked -eq $true) { $conflictMessage = "/E conflicts with /MIR"; $window.FindName("MirrorCheckbox").IsChecked = $false }
                    if ($window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true) { $conflictMessage = "/E conflicts with /S"; $window.FindName("IncludeSubdirectoriesCheckbox").IsChecked = $false }
                }
            }
            "CopyDATSCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("SecCheckbox").IsChecked -eq $true) { $conflictMessage = "/COPY:DATS conflicts with /SEC"; $window.FindName("SecCheckbox").IsChecked = $false }
                }
            }
            "SecCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("CopyDATSCheckbox").IsChecked -eq $true) { $conflictMessage = "/SEC conflicts with /COPY:DATS"; $window.FindName("CopyDATSCheckbox").IsChecked = $false }
                }
            }
            "NPCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("ETACheckbox").IsChecked -eq $true) { $conflictMessage = "/NP conflicts with /ETA"; $window.FindName("ETACheckbox").IsChecked = $false }
                }
            }
            "ETACheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("NPCheckbox").IsChecked -eq $true) { $conflictMessage = "/ETA conflicts with /NP"; $window.FindName("NPCheckbox").IsChecked = $false }
                }
            }
            "RestartableCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("BackupModeCheckbox").IsChecked -eq $true) { $conflictMessage = "/Z conflicts with /B"; $window.FindName("BackupModeCheckbox").IsChecked = $false }
                }
            }
            "BackupModeCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("RestartableCheckbox").IsChecked -eq $true) { $conflictMessage = "/B conflicts with /Z"; $window.FindName("RestartableCheckbox").IsChecked = $false }
                }
            }
            "LogPlusCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("LogCheckbox").IsChecked -eq $true) { $conflictMessage = "/LOG+ conflicts with /LOG"; $window.FindName("LogCheckbox").IsChecked = $false }
                }
            }
            "LogCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("LogPlusCheckbox").IsChecked -eq $true) { $conflictMessage = "/LOG conflicts with /LOG+"; $window.FindName("LogPlusCheckbox").IsChecked = $false }
                }
            }
            "NoSourceDirCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("MirrorCheckbox").IsChecked -eq $true) { $conflictMessage = "/NOSD conflicts with /MIR"; $window.FindName("MirrorCheckbox").IsChecked = $false }
                }
            }
            "MOVCheckbox" {
                if ($checkbox.IsChecked -eq $true) {
                    if ($window.FindName("MirrorCheckbox").IsChecked -eq $true) { $conflictMessage = "/MOV conflicts with /MIR"; $window.FindName("MirrorCheckbox").IsChecked = $false }
                }
            }
        }

        # Check for multiple conflicting options
        if ($window.FindName("MirrorCheckbox").IsChecked -eq $true -and ($window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true -or $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true -or $window.FindName("PurgeCheckbox").IsChecked -eq $true -or $window.FindName("NoSourceDirCheckbox").IsChecked -eq $true -or $window.FindName("MOVCheckbox").IsChecked -eq $true)) {
            $incompatibleSwitches += "/MIR conflicts with /S, /E, /PURGE, /NOSD, /MOV"
        }
        if ($window.FindName("IncludeSubdirectoriesCheckbox").IsChecked -eq $true -and $window.FindName("IncludeEmptySubdirectoriesCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/S conflicts with /E"
        }
        if ($window.FindName("SecCheckbox").IsChecked -eq $true -and $window.FindName("CopyDATSCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/SEC conflicts with /COPY:DATS"
        }
        if ($window.FindName("NPCheckbox").IsChecked -eq $true -and $window.FindName("ETACheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/NP conflicts with /ETA"
        }
        if ($window.FindName("BackupModeCheckbox").IsChecked -eq $true -and $window.FindName("RestartableCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/B conflicts with /Z"
        }
        if ($window.FindName("LogPlusCheckbox").IsChecked -eq $true -and $window.FindName("LogCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/LOG+ conflicts with /LOG"
        }
        if ($window.FindName("NoSourceDirCheckbox").IsChecked -eq $true -and $window.FindName("MirrorCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/NOSD conflicts with /MIR"
        }
        if ($window.FindName("MOVCheckbox").IsChecked -eq $true -and $window.FindName("MirrorCheckbox").IsChecked -eq $true) {
            $incompatibleSwitches += "/MOV conflicts with /MIR"
        }

        if ($incompatibleSwitches.Count -gt 0) {
            $message = $conflictMessage
            if ($incompatibleSwitches.Count -gt 0) {
                $message += ". Additional conflicts: " + ($incompatibleSwitches -join ", ")
            }
            ShowErrorMessage($message)
        } else {
            $window.Dispatcher.Invoke([action] {
                $window.FindName("ErrorMessage").Text = ""
            })
        }
    }

    # Add event handlers to checkboxes
    $panels = @(
        "CommonOptionsPanel",
        "FileSelectionOptionsPanel",
        "RetryOptionsPanel",
        "LoggingOptionsPanel",
        "JobOptionsPanel",
        "AdvancedOptionsPanel",
        "MultithreadingOptionsPanel",
        "NetworkOptionsPanel",
        "CopyOptionsPanel"
    )

    foreach ($panelName in $panels) {
        $panel = $window.FindName($panelName)
        if ($null -ne $panel) {
            foreach ($child in $panel.Children) {
                if ($child.GetType().Name -eq "CheckBox") {
                    $child.Add_Checked({
                        param ($cbSender, $e)
                        HandleCheckboxChange $cbSender
                    })
                    $child.Add_Unchecked({
                        param ($cbSender, $e)
                        HandleCheckboxChange $cbSender
                    })
                } elseif ($child.GetType().Name -eq "StackPanel") {
                    foreach ($grandchild in $child.Children) {
                        if ($grandchild.GetType().Name -eq "CheckBox") {
                            $grandchild.Add_Checked({
                                param ($cbSender, $e)
                                HandleCheckboxChange $cbSender
                            })
                            $grandchild.Add_Unchecked({
                                param ($cbSender, $e)
                                HandleCheckboxChange $cbSender
                            })
                        }
                    }
                }
            }
        }
    }

    $window.FindName("BrowseSourceButton").Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $window.Dispatcher.Invoke([action] {
                $window.FindName("SourceTextBox").Text = '"' + $folderDialog.SelectedPath + '"'
            })
        }
    })

    $window.FindName("BrowseDestinationButton").Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $window.Dispatcher.Invoke([action] {
                $window.FindName("DestinationTextBox").Text = '"' + $folderDialog.SelectedPath + '"'
            })
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
        if ($window.FindName("LevCheckbox").IsChecked -eq $true) {
            $levValue = $window.FindName("LevValueTextBox").Text
            if ($levValue -match '^\d+$') {
                $options += "/LEV:$levValue "
            } else {
                ShowErrorMessage("Invalid /LEV value. It should be a number.")
                return
            }
        }
        if ($window.FindName("AOnlyCheckbox").IsChecked -eq $true) { $options += "/A " }
        if ($window.FindName("MCheckbox").IsChecked -eq $true) { $options += "/M " }
        if ($window.FindName("IncludeAttributesCheckbox").IsChecked -eq $true) {
            $iaValue = $window.FindName("IAValueTextBox").Text.Trim('"')
            if ($iaValue) {
                $options += "/IA:`"$iaValue`" "
            }
        }
        if ($window.FindName("ExcludeAttributesCheckbox").IsChecked -eq $true) {
            $xaValue = $window.FindName("XAValueTextBox").Text.Trim('"')
            if ($xaValue) {
                $options += "/XA:`"$xaValue`" "
            }
        }
        if ($window.FindName("RCheckbox").IsChecked -eq $true) {
            $rValue = $window.FindName("RValueTextBox").Text
            if ($rValue -match '^\d+$') {
                $options += "/R:$rValue "
            } else {
                ShowErrorMessage("Invalid /R value. It should be a number.")
                return
            }
        }
        if ($window.FindName("WCheckbox").IsChecked -eq $true) {
            $wValue = $window.FindName("WValueTextBox").Text
            if ($wValue -match '^\d+$') {
                $options += "/W:$wValue "
            } else {
                ShowErrorMessage("Invalid /W value. It should be a number.")
                return
            }
        }
        if ($window.FindName("LCheckbox").IsChecked -eq $true) { $options += "/L " }
        if ($window.FindName("XCheckbox").IsChecked -eq $true) { $options += "/X " }
        if ($window.FindName("VCheckbox").IsChecked -eq $true) { $options += "/V " }
        if ($window.FindName("NPCheckbox").IsChecked -eq $true) { $options += "/NP " }
        if ($window.FindName("LogCheckbox").IsChecked -eq $true) { $options += "/LOG " }
        if ($window.FindName("LogPlusCheckbox").IsChecked -eq $true) { $options += "/LOG+ " }
        if ($window.FindName("ETACheckbox").IsChecked -eq $true) { $options += "/ETA " }
        if ($window.FindName("JobCheckbox").IsChecked -eq $true) {
            $jobValue = $window.FindName("JobValueTextBox").Text.Trim('"')
            if ($jobValue) {
                $options += "/JOB:`"$jobValue`" "
            }
        }
        if ($window.FindName("SaveJobCheckbox").IsChecked -eq $true) {
            $saveJobValue = $window.FindName("SaveJobValueTextBox").Text.Trim('"')
            if ($saveJobValue) {
                $options += "/SAVE:`"$saveJobValue`" "
            }
        }
        if ($window.FindName("QuitCheckbox").IsChecked -eq $true) { $options += "/QUIT " }
        if ($window.FindName("NoSourceDirCheckbox").IsChecked -eq $true) { $options += "/NOSD " }
        if ($window.FindName("NoDestDirCheckbox").IsChecked -eq $true) { $options += "/NODD " }
        if ($window.FindName("SecCheckbox").IsChecked -eq $true) { $options += "/SEC " }
        if ($window.FindName("CopyDATSCheckbox").IsChecked -eq $true) { $options += "/COPY:DATS " }
        if ($window.FindName("DCopyCheckbox").IsChecked -eq $true) { $options += "/DCOPY:T " }
        if ($window.FindName("PurgeCheckbox").IsChecked -eq $true) { $options += "/PURGE " }
        if ($window.FindName("MOVCheckbox").IsChecked -eq $true) { $options += "/MOV " }
        if ($window.FindName("MoveCheckbox").IsChecked -eq $true) { $options += "/MOVE " }
        if ($window.FindName("AddAttrCheckbox").IsChecked -eq $true) {
            $addAttrValue = $window.FindName("AddAttrTextBox").Text.Trim('"')
            if ($addAttrValue) {
                $options += "/A+:`"$addAttrValue`" "
            }
        }
        if ($window.FindName("RemoveAttrCheckbox").IsChecked -eq $true) {
            $removeAttrValue = $window.FindName("RemoveAttrTextBox").Text.Trim('"')
            if ($removeAttrValue) {
                $options += "/A-:`"$removeAttrValue`" "
            }
        }
        if ($window.FindName("CreateCheckbox").IsChecked -eq $true) { $options += "/CREATE " }
        if ($window.FindName("FatCheckbox").IsChecked -eq $true) { $options += "/FAT " }
        if ($window.FindName("LongPathCheckbox").IsChecked -eq $true) { $options += "/256 " }
        if ($window.FindName("MonCheckbox").IsChecked -eq $true) {
            $monValue = $window.FindName("MonValueTextBox").Text
            if ($monValue -match '^\d+$') {
                $options += "/MON:$monValue "
            }
        }
        if ($window.FindName("MotCheckbox").IsChecked -eq $true) {
            $motValue = $window.FindName("MotValueTextBox").Text
            if ($motValue -match '^\d+$') {
                $options += "/MOT:$motValue "
            }
        }
        if ($window.FindName("RHCheckbox").IsChecked -eq $true) {
            $rhValue = $window.FindName("RHValueTextBox").Text.Trim('"')
            if ($rhValue) {
                $options += "/RH:`"$rhValue`" "
            }
        }
        if ($window.FindName("PFCheckbox").IsChecked -eq $true) {
            $pfValue = $window.FindName("PFValueTextBox").Text.Trim('"')
            if ($pfValue) {
                $options += "/PF:`"$pfValue`" "
            }
        }
        if ($window.FindName("MultiThreadCheckbox").IsChecked -eq $true) {
            $mtValue = $window.FindName("MTValueTextBox").Text
            if ($mtValue -match '^\d+$' -and $mtValue -ge 1 -and $mtValue -le 128) {
                $options += "/MT:$mtValue "
            } else {
                ShowErrorMessage("Invalid /MT value. Accepted values are between 1 and 128.")
                return
            }
        }
        if ($window.FindName("IPGCheckbox").IsChecked -eq $true) {
            $ipgValue = $window.FindName("IPGValueTextBox").Text
            if ($ipgValue -match '^\d+$') {
                $options += "/IPG:$ipgValue "
            } else {
                ShowErrorMessage("Invalid /IPG value. It should be a number.")
                return
            }
        }
        if ($window.FindName("RestartableCheckbox").IsChecked -eq $true) { $options += "/Z " }
        if ($window.FindName("BackupModeCheckbox").IsChecked -eq $true) { $options += "/B " }
        if ($window.FindName("ZBCheckbox").IsChecked -eq $true) { $options += "/ZB " }
        if ($window.FindName("JCheckbox").IsChecked -eq $true) { $options += "/J " }

        $command = "Robocopy $source $destination $options"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", $command
    })

    $window.ShowDialog() | Out-Null
}

# Run The GUI
Show-RobocopyGui
