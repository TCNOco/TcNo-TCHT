# Copyright (C) 2023 TroubleChute (Wesley Pyburn)
# Licensed under the GNU General Public License v3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ----------------------------------------
# This script downloads all files from a HuggingFace repo using aria2c
# ----------------------------------------

<#
.SYNOPSIS
Downloads all files from a Huggingface repository using the Aria2 download manager.
This works well when you need to download all files from a repo, but if you need to download models the repo may have duplicates with different versions.

.DESCRIPTION
The `Get-HuggingFaceRepo` function downloads all files from a Huggingface repository using the Aria2 download manager.
The function requires the `Get-Aria2Files` function to be available, which can be imported using the `Import-RemoteFunction` and `Import-FunctionIfNotExists` cmdlets.

.PARAMETER Model
Specifies the Huggingface repository to download files from. The value should be specified in the "<username>/<repo-name>" format.

.PARAMETER OutputPath
Specifies the path where the downloaded files should be saved.
Can be relative too

.NOTES
This function requires an internet connection to download files from the specified Huggingface repository.

.EXAMPLE
Get-HuggingFaceRepo -Model "huggingface/transformers" -OutputPath "C:\Models\transformers"

Downloads all files from the "huggingface/transformers" repository and saves them to "C:\Models\transformers".
#>
function Get-HuggingFaceRepo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Model,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,

        [Parameter(Mandatory=$false)]
        [string[]]$SkipFiles = @(),

        [Parameter(Mandatory=$false)]
        [string[]]$IncludeFiles = @()
    )

    # Allow importing remote functions
    iex (irm Import-RemoteFunction.tc.ht)
    Import-FunctionIfNotExists -Command Get-Aria2Files -ScriptUri "File-DownloadMethods.tc.ht"

    # Get the Huggingface repository URL and API endpoint URL
    $repoUrl = "https://huggingface.co/$Model"
    $apiUrl = "https://api-inference.huggingface.co/models/$Model"
    $fileDownloadUrl = "$repoUrl/resolve/main"

    # Get the list of files in the repository
    $filesUrl = "$apiUrl/list_files"
    $filesResponse = Invoke-RestMethod -Uri $apiUrl -Method Get
    $filesList = $filesResponse.siblings
    $filenames = @()
    foreach ($file in $filesResponse.siblings) {
        $filename = Split-Path $file.rfilename -Leaf
        # Check each file against the SkipFiles array
        $skip = $false
        if ($SkipFiles.Count -gt 0) {
            foreach ($skipFile in $SkipFiles) {
                if ($filename -match $skipFile) {
                    $skip = $true
                    break
                }
            }
        }
        
        # Check each file against the IncludeFiles array
        $include = $true
        if ($IncludeFiles.Count -gt 0) {
            $include = $false
            foreach ($includeFile in $IncludeFiles) {
                if ($filename -match $includeFile) {
                    $include = $true
                    break
                }
            }
        }

        if (!$skip -and $include) {
            $filenames += $filename
        }
    }

    Get-Aria2Files -Url $fileDownloadUrl -OutputPath $OutputPath -Files $filenames
}


