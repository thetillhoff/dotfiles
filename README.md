# dotfiles

This repo is checked out in `~` itself, so `~/.claude` is the live copy. Never clone it a second time.

## Initial setup (macOS)

1. Install the command line tools. Git needs them.

   ```sh
   xcode-select --install
   ```

2. Create an SSH key. Add the public key to GitHub.

   ```sh
   ssh-keygen -t ed25519 -C "<email>"
   cat ~/.ssh/id_ed25519.pub
   ```

3. Check out this repo into `~`.

   ```sh
   cd ~
   git init
   git remote add origin git@github.com:thetillhoff/dotfiles.git
   git pull origin main
   git branch --set-upstream-to=origin/main main
   ```

4. Install Homebrew. Add it to the `PATH`.

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv zsh)"
   ```

5. Install oh-my-zsh. Answer `n` to the question about `.zshrc`, so the installer keeps the `.zshrc` of this repo.

   ```sh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

6. Install all packages, taps and casks from `.Brewfile`. This includes the Nerd Font and Claude Code.

   ```sh
   brew bundle install --file ~/.Brewfile
   ```

7. Open a new terminal.

Before step 6, the shell prints errors for `nvm_find_nvmrc`, `starship` and `direnv`. The tools do not exist yet. The errors stop after step 7.

### Identity

`.gitconfig` sets no email. Git takes the identity from these tracked files:

- `~/code/.gitconfig`: default for every repo under `~`.
- `~/code/<org>/.gitconfig`: overrides the default for the repos in that directory. Add a matching `includeIf` to `.gitconfig` for a new org.

### Maintain `.Brewfile`

`.Brewfile` is shared by macOS and Linux. On Linux, `brew bundle install` can fail for mac-only entries. Install the rest and ignore those.

On macOS, the `brew` function in `.zshrc` rewrites `.Brewfile` after a successful `install`, `uninstall`, `reinstall`, `tap` or `untap`. It does nothing on Linux, because a Linux dump would drop the mac-only entries. On Linux, edit the file by hand.

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
