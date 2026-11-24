
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
然后先跑一次switch(#nixos / #home-manager), 让这两个先生效
- *flake 只读 Git 索引，不读工作区未跟踪文件

## nixos
``` bash
sudo nixos-rebuild switch
```

## flakes
``` bash
sudo nixos-rebuild build --flake .#asus
sudo nixos-rebuild switch --flake .#asus
sudo nixos-rebuild boot --flake .#asus
```

## home-manager
``` bash
home-manager build --flake .
home-manager switch --flake .
home-manager switch --flake . \
  --option substituters "https://mirrors.cernet.edu.cn/nix-channels/store?priority=10 https://mirrors.ustc.edu.cn/nix-channels/store?priority=10 https://mirror.sjtu.edu.cn/nix-channels/store?priority=10 https://cache.nixos.org/"
```

## after
``` bash
fcitx5-remote -r # 重新部署rime
fcitx5 -r -d  
```

## 包查找
- nix: `nix search nixpkgs <package>`
- nur: https://nur.nix-community.org/repos/

## dev
``` bash
nix develop path:./sdks/android
```
