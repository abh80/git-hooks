# Owner : github.com/abh80
# Usage : stage the files , using git add
# then run this script

function GetModifiedFiles {
    git diff --cached --name-only # using git to get all staged commits
}

function GenerateCommitMessage {
    param (
        [string]$file
    )

    $filename = Split-Path -Leaf $file

    $prefix = "refactor($filename)"
    
    $message = Read-Host $prefix

    return $prefix + ": " + $message
}

$modifiedFiles = @(GetModifiedFiles)

if ($modifiedFiles.Count -eq 0) {
    Write-Host "No changes to commit. Exiting."
    exit 0
}

$commitMessage = @($modifiedFiles | ForEach-Object {
        Write-Host "You will be asked to enter commit details"

        GenerateCommitMessage $_
    })

Write-Host "Generated commit message:"
Write-Host "--------------------------"
Write-Host $commitMessage

$shallCommit = Read-Host "Commit the changes? (Y\n)"

if ($shallCommit -eq "n") {
    exit 0
}
else {
    try {
        Invoke-Expression "git reset" > $null # Unstage all the changes
        for ($i = 0 ; $i -lt $modifiedFiles.Count ; $i++) {
            $file = $modifiedFiles[$i]
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
