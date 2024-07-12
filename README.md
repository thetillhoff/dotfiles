# dotfiles

```sh
git init
git remote add origin git@github.com:thetillhoff/dotfiles.git
git branch --set-upstream-to=origin/main main
git pull
git checkout main # not sure if needed

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # Install oh-my-zsh
git reset --hard
git checkout main -f
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k # Install powerlevel10k
brew install --cask font-meslo-lg-nerd-font # Install nerd-font
```

```sh
touch .hushlogin # Silence iterm2 startup message
```
