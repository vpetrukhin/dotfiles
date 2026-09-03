# dotfiles

dotfiles for my work setup

## Installing

```bash
./install/install-brew.sh        # run this if brew uninstalled
./install/install-brew-package.sh # brew bundle --file=install/Brewfile
./install/bootstrap.sh           # symlinks from links.prop
```

## Adding a package

```bash
brew install <package>
brew bundle dump --force --file=install/Brewfile
```
