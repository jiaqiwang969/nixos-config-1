{ pkgs, currentSystemUser, lib, ... }: {
  imports = [
    # 从 fetchTarball 导入 cursor-server 模块
    (import (builtins.fetchTarball {
      url    = "https://github.com/warmingking/nixos-cursor-server/tarball/master";
      sha256 = "0iqrhkysfjmqpkxj31vk1y7iq8541sfnpqjlg1jlgvn20kbpym3p";
    }))
  ];

  boot.isContainer = true;

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = currentSystemUser;
    startMenuLaunchers = true;
  };

  # SSH 服务配置 for WSL instance
  services.openssh = {
    enable = true;
    settings = {
      # 允许密码登录，如果您的用户设置了密码并且希望使用。
      # 为了更高安全性，建议设置为 false 并仅使用 SSH 密钥。
      PasswordAuthentication = true; 
      # 禁止 root 用户通过密码登录，但允许通过密钥（如果 root 有 authorized_keys）
      # 或者完全禁止 root 登录: PermitRootLogin = "no";
      PermitRootLogin = "prohibit-password"; 
    };
    ports = [ 2222 ]; # NixOS-WSL 将监听在 2222 端口
  };

  # 启用 cursor-server 服务
  services.cursor-server.enable = true;

  # 添加 nix-ld 配置
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # 基础库
      stdenv.cc.cc.lib # glibc
      gcc.cc.lib       # libstdc++

      # 常见运行库
      openssl
      zlib
      util-linux
      systemd # 包含 libsystemd, 某些程序可能需要
      nss     # Name Service Switch, 某些网络或用户相关操作可能需要
    ];
  };

  # 添加中文字体配置
  fonts.packages = with pkgs; [
    wqy_zenhei          # 文泉驿正黑 (常用无衬线)
    noto-fonts-cjk-sans # Noto 无衬线黑体 (简体中文)
  ];

  # ----- NVIDIA CUDA for WSL2 -----
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
    "cuda-toolkit"
    "cudnn"
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # In WSL, power management is typically handled by Windows
    open = false; # Use NVIDIA's proprietary drivers
    # Ensure this package matches or is compatible with your Windows NVIDIA driver version
    # 'stable' is a good default. You might need to pick a specific branch like 'production' or a versioned one.
    package = pkgs.config.boot.kernelPackages.nvidiaPackages.stable;
  };

  nixpkgs.config.cudaSupport = true;

  # Add user to relevant groups for GPU access
  users.users.${currentSystemUser}.extraGroups = lib.mkIf pkgs.stdenv.isLinux [ "video" "render" ];

  environment.systemPackages = with pkgs; [
    # This will install a default version of CUDA Toolkit chosen by Nixpkgs based on the driver
    cudaPackages.cudatoolkit
    # This will install a default version of cuDNN compatible with the chosen cudatoolkit
    cudaPackages.cudnn
    # You can specify versions if needed, e.g.:
    # cudaPackages_11_8.cudatoolkit
    # cudaPackages_11_8.cudnn_8_9 # Check exact cudnn package name for specific versions

    # nvidia-container-toolkit # Uncomment if you plan to use Docker with GPU support inside NixOS-WSL
  ];
  # ----- End NVIDIA CUDA for WSL2 -----

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  system.stateVersion = "23.05";
}
