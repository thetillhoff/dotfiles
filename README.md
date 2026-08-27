# dotfiles

```sh
git init
git remote add origin git@github.com:thetillhoff/dotfiles.git
git branch --set-upstream-to=origin/main main
git pull
git checkout main # not sure if needed

 brew tap thetillhoff/homebrew-tap
 brew tap hashicorp/tap
 brew tap fluxcd/tap
cat .brew-list | xargs brew install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # Install oh-my-zsh
git reset --hard
git checkout main -f
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k # Install powerlevel10k
brew install --cask font-meslo-lg-nerd-font # Install nerd-font
```

```sh
touch .hushlogin # Silence iterm2 startup message
```

## amdgpu GPU-hang coredump capture

RX 6700 XT (Navi 22) can hang under GPU load: display goes "no signal" (audio keeps
playing, fans spin up), GPU won't self-recover because `mode1`/ASIC reset fails
(`-62`) -> only a hard reset gets out. Root cause = a userspace GL app (VS Code /
Electron / Chromium) trips a `gfxhub` UTCL2 permission page fault -> gfx ring timeout
-> failed reset. Known upstream class:

- drm/amd (kernel, NOT github): <https://gitlab.freedesktop.org/drm/amd/-/issues>
  see issues #1855, #2134 (Navi 22 reset failure)
- <https://github.com/pop-os/cosmic-comp/issues/2149> (same UTCL2 page-fault trigger)

The kernel writes a devcoredump to sysfs at hang time, but it's RAM-backed and wiped
on reboot - can't grab it manually since the screen is dead. Auto-capture is installed
(survives ostree updates, lives outside this repo):

- `/usr/local/bin/save-devcoredump` (-> /var/usrlocal/bin, persistent)
- `/etc/udev/rules.d/70-amdgpu-coredump.rules` (fires on `devcoredump` device add)

After a hang, the dump lands at `/var/log/amdgpu-devcoredump-*.bin`. That file + kernel
(`uname -r`) and mesa (`rpm -q mesa-vulkan-drivers`) versions = enough to file a fresh
drm/amd issue (only if it recurs; otherwise it's a known dup).

Safe end-to-end test (forces a real GPU reset - do it idle, not mid-work):
`echo 1 | sudo tee /sys/kernel/debug/dri/*/amdgpu_gpu_recover` then check `/var/log/`.

Mitigation to reduce the trigger: VS Code -> "Preferences: Configure Runtime Arguments"
-> `"disable-hardware-acceleration": true`.
