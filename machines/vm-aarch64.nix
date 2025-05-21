{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware/vm-aarch64.nix
    ../modules/vmware-guest.nix
    ./vm-shared.nix
    (import (fetchTarball {
        url = "https://github.com/warmingking/nixos-cursor-server/tarball/master";
        sha256 = "0iqrhkysfjmqpkxj31vk1y7iq8541sfnpqjlg1jlgvn20kbpym3p"; # ✅ 正确
    }))
  ];

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  # Interface is this on M1
  networking = {
    interfaces.ens160.useDHCP = true;
    networkmanager.enable = true;
  };

  # 添加 systemd 网络等待配置
  systemd.network = {
    wait-online = {
      enable = false;  # 完全禁用等待服务
      timeout = 10;    # 如果启用，设置 10 秒超时
      anyInterface = true;  # 任何接口连接即可
      # ignoredInterfaces = [ "ens160" ];  # 可选：忽略特定接口
    };
  };

  systemd.services."NetworkManager-wait-online".enable = false;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;


  fileSystems."/host" = {
      fsType = "fuse.vmhgfs-fuse";
      device = ".host:/";
      options = [
          "uid=1000"
          "gid=1000"
          "allow_other"
          "auto_unmount"
          "defaults"
          "nofail"
          "x-systemd.automount"
          "x-systemd.device-timeout=5s"
      ];
  };

  services.cursor-server.enable = true;
  #services.vscode-server.enable = true;
  #services.vscode-server.enableFHS = true;
  #services.vscode-server.installPath = "$HOME/.cursor-server";  # 👈 关键是这行
}
