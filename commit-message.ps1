# Owner : github.com/abh80
# Usage : stage the files , using git add
# then run this script

function GetModifiedFiles {
    git diff --cached --name-status # using git to get all staged commits
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

$modifiedFiles = @(GetModifiedFiles)

if ($modifiedFiles.Count -eq 0) {
    Write-Host "No changes to commit. Exiting."
    exit 0
}

Write-Host "You will be asked to enter commit details"

$commitMessage = @($modifiedFiles | ForEach-Object {
        GenerateCommitMessage $_
    })

Write-Host "Generated commit message:"
Write-Host "--------------------------"
Write-Host $($commitMessage -join "`n")

$shallCommit = Read-Host "Commit the changes? (Y\n)"

if ($shallCommit -eq "n") {
    exit 0
}
else {
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
                Write-Host "An error occurred during the commit process. Changes have been reset."
                exit 1
            }
        }
    }
    catch {
        exit 1
    }
}

Write-Host "Wrote the commit, sucessfully"
