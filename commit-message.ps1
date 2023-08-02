# Owner : github.com/abh80
# Usage : stage the files , using git add
# then run this script

function GetModifiedFiles {
    git diff --cached --name-status # using git to get all staged commits
}

function handleSavedFile {
    param(
        [string]$savedCommitFile
    )

    $shouldDo = Read-Host "Found an existing saved commit file from a previously failed sesssion, use it ? (Y/n)"
    if ($shouldDo -eq "n") {
        Write-Host "Removing the saved commit file and exiting..."
        Remove-Item $savedCommitFile
        exit 0
    }
    $content = Get-Content $savedCommitFile -Raw
    return parseCommitFile -givenString $content
    
}

function parseCommitFile {
    param (
        [string]$givenString
    )
    $splitString = $givenString -split $("-" * 10)

    # Trim the leading/trailing whitespaces of each line
    $lines = $splitString -replace '^\s+|\s+$' -ne ''

    # Split the lines into two separate arrays
    $array1 = $lines[0..($lines.Length / 2 - 1)]
    $array2 = $lines[($lines.Length / 2)..($lines.Length - 1)]

    # Convert the two arrays into the desired format
    $resultArray = @($array1), @($array2)
    return $resultArray
}

function GenerateCommitMessage {
    param (
        [string]$fileStatus
    )

    $fileStatusParts = $fileStatus -split '\s+'
    $status = $fileStatusParts[0]
    $file = $fileStatusParts[1]
    $filename = Split-Path -Leaf $file

    $prefix = switch ($status) {
        'M' { "refactor($filename)" }
        'A' { "add($filename)" }
        'D' { "remove($filename)" }
        'T' { "refactor($filename)" }
        'R' { "refactor($filename)" }
        'C' { "copied($filename)" }
        Default { Write-Host "Unknown file status: $status"; exit 1 }
    }
    
    $message = Read-Host $prefix

    return $prefix + ": " + $message
}

$savedCommitFile = "$(Get-Location)/.git/SAVED_COMMIT.txt"

$modifiedFiles = @(GetModifiedFiles)

$commitMessage

if ($modifiedFiles.Count -eq 0) {
    if (Test-Path -Path $savedCommitFile) {
        $raw = handleSavedFile -savedCommitFile $savedCommitFile        
        $commitMessage = $raw[0]
        $modifiedFiles = $raw[1]
        
    }
    else {
        Write-Host "No changes to commit. Exiting."
        exit 0
    }
}

$commitStatusJoinDelim = "-" * 10

Write-Host "You will be asked to enter commit details"

if ($null -eq $commitMessage) {
    $commitMessage = @($modifiedFiles | ForEach-Object {
            GenerateCommitMessage $_
        })
}
Write-Host "Generated commit message:"
Write-Host "--------------------------"
Write-Host $($commitMessage -join "`n")

$shallCommit = Read-Host "Commit the changes? (Y\n)"

if ($shallCommit -eq "n") {
    exit 0
}
else {
    $commitFileContentAsArray = @($commitMessage + $commitStatusJoinDelim + $modifiedFiles)
    $($commitFileContentAsArray -join "`n") | Out-File -FilePath $savedCommitFile
    $filePaths = @($modifiedFiles | ForEach-Object {
            $fileStatusParts = $_ -split '\s+'
            return $fileStatusParts[1]
        })

    try {
        Invoke-Expression "git reset" > $null # Unstage all the changes
        for ($i = 0 ; $i -lt $filePaths.Count ; $i++) {
            $file = $filePaths[$i]
            $cm = $commitMessage[$i]
            Invoke-Expression "git add `"$file`"" > $null
            Invoke-Expression "git commit -m `"$cm`"" > $null
            if ($LASTEXITCODE -ne 0) {
                Invoke-Expression "git reset" > $null
                Write-Host "An error occurred during the commit process. Changes have been reset`nYour commit messages are not gone! Run the script again without staging anything to recover the commits."
                exit 1
            }
        }
    }
    catch {
        Invoke-Expression "git reset" > $null
        exit 1
    }
}
Write-Host "Wrote the commit, sucessfully"
Remove-Item -Path $savedCommitFile