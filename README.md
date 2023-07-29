# git-hooks
My custom git hooks which I use across my repository

> Note: requires [Powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) to be installed in your system

# Installation
Add it using [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

```bash
$ git submodule add https://github.com/abh80/git-hooks.git
```

# Usage
Execute the script using their relative paths `git-hooks/<script>.ps1`

# Available scripts

- **Commit Message**
  
  Automatically formats your git commit message and commits them easily, also commits your each file separately.

  1. Stage the commits using `git add .` or individually `git add <some-file>`
  2. Execute the script `./git-hooks/commmit-message.ps1`
  3. Everything required will be prompted next!
