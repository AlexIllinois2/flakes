
## before
还没有编译**成功过**的话， flakes和国内源就**生效不了**：
1. flake： 在configuration.nix中增加：`nix.settings.experimental-features = [ "nix-command" "flakes" ];`
2. 国内源： 
  - 在/switch命令（home-manager）中增加： `--option substituters "https://mirrors.cernet.edu.cn/nix-channels/store?priority=10 https://mirrors.ustc.edu.cn/nix-channels/store?priority=10 https://mirror.sjtu.edu.cn/nix-channels/store?priority=10 https://cache.nixos.org/"`
  - 在/etc/nix/nix.conf中增加： `extra-substituters = https://mirrors.cernet.edu.cn/nix-channels/store?priority=10 https://mirrors.ustc.edu.cn/nix-channels/store?priority=10 https://mirror.sjtu.edu.cn/nix-channels/store?priority=10`
  - 在configuration.nix中增加： 
``` nix

  nix.settings = {
    extra-substituters = [
      "https://mirrors.cernet.edu.cn/nix-channels/store?priority=10"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=10"
      "https://mirror.sjtu.edu.cn/nix-channels/store?priority=10"
    ];
  };
```
然后先跑一次switch让这两个先生效:
- nixos
``` bash
sudo nixos-rebuild build
sudo nixos-rebuild switch
```
- home-manager
``` bash
home-manager build .
home-manager switch .
home-manager switch . \
  --option substituters "https://mirrors.cernet.edu.cn/nix-channels/store?priority=10 https://mirrors.ustc.edu.cn/nix-channels/store?priority=10 https://mirror.sjtu.edu.cn/nix-channels/store?priority=10 https://cache.nixos.org/"
```

## flakes
- *flake 只读 Git 索引，不读工作区未跟踪文件
``` bash
sudo nixos-rebuild build --flake .#asus
sudo nixos-rebuild switch --flake .#asus
sudo nixos-rebuild boot --flake .#asus
```

## after
``` bash
fcitx5-remote -r # 重新部署rime
fcitx5 -r -d  

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-modify flathub --url https://mirrors.ustc.edu.cn/flathub
flatpak install flathub it.mijorus.gearlever # 管理appimage
```

## 包查找
- nix: `nix search nixpkgs <package>`
- nur: https://nur.nix-community.org/repos/
- 直接安装: `nix profile install nixpkgs#<package>`

## 手动管理构建版本
``` bash
# 列表
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
# 清理, 保留最近5个
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
```

## dev
``` bash
nix develop path:./sdks/android
```
