{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  ############################################################
  # 引导
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ############################################################
  # Nix 自身
  nix = {
    package      = pkgs.nixVersions.latest;
    extraOptions = "experimental-features = nix-command flakes";
    settings = {
      substituters         = [ "https://jiaqiwang969.cachix.org" ];
      trusted-public-keys  = [
        "jiaqiwang969.cachix.org-1:FXY5IvEszf/K/0ZhwnrG+cy+nsPc/nVHYSM8WnQaMvE="
      ];
    };
  };

  ############################################################
  # OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin        = "yes";
    };
  };
  users.users.root.initialPassword = "root";

  ############################################################
  # 网络 — systemd-networkd
  networking.useDHCP               = false;
  networking.networkmanager.enable = false;
  networking.nameservers           = [ "192.168.137.1" "1.1.1.1" ];

  systemd.network.enable = true;

  # ens36：Host-only，固定私网 + 默认路由
  systemd.network.networks."10-ens36" = {
    matchConfig.Name      = "ens36";
    networkConfig.Address = "192.168.137.33/24";
    networkConfig.Gateway = "192.168.137.1";
    networkConfig.DNS     = "192.168.137.1";
    linkConfig.RequiredForOnline = "yes";
  };

  # ens33：桥接，DHCP，但禁止抢默认路由
  systemd.network.networks."20-ens33" = {
    matchConfig.Name        = "ens33";
    networkConfig.DHCP      = "ipv4";
    dhcpConfig.RouteMetric = 6000;
    networkConfig.IPv6AcceptRA = "no";
    linkConfig.RequiredForOnline = "no";
  };

  # boot 阶段不用等 networkd-wait-online
  systemd.network.wait-online.enable = false;

  ############################################################
  system.stateVersion = "24.11";
}
