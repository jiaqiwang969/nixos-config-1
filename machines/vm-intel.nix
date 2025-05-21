{ config, pkgs, ... }:

{
  imports = [
    ./hardware/vm-intel.nix
    ./vm-shared.nix
    (import (fetchTarball {
      url    = "https://github.com/warmingking/nixos-cursor-server/tarball/master";
      sha256 = "0iqrhkysfjmqpkxj31vk1y7iq8541sfnpqjlg1jlgvn20kbpym3p";
    }))
  ];

  virtualisation.vmware.guest.enable = true;

  ######################## 网络 ########################
  networking.useDHCP                   = false;   # 全局关
  networking.networkmanager.enable     = false;   # 换成 networkd
  networking.nameservers               = [ "192.168.137.1" "1.1.1.1" ];

  systemd.network.enable               = true;

  # ---- Host-only ens36：固定私网 + 默认路由 ----
  systemd.network.networks."10-ens36" = {
    matchConfig.Name     = "ens36";
    networkConfig.Address = "192.168.137.33/24";
    networkConfig.Gateway = "192.168.137.1";
    networkConfig.DNS     = "192.168.137.1";
    linkConfig.RequiredForOnline = "yes";
  };

  # ---- 桥接 ens33：DHCP，禁止默认路由（Metric 高）----
  systemd.network.networks."20-ens33" = {
    matchConfig.Name       = "ens33";
    networkConfig = {
      DHCP     = "ipv4";
      IPv6AcceptRA = "no";
    };
    dhcpConfig.RouteMetric = 6000;     # 永不抢默认
    linkConfig.RequiredForOnline = "no";
  };

  # 不必再管 wait-online：networkd 自己很快
  systemd.network.wait-online.enable   = false;
  systemd.services."NetworkManager-wait-online".enable = false;

  ######################################################
  nixpkgs.config.allowUnfree = true;

  fileSystems."/host" = {
    fsType  = "fuse.vmhgfs-fuse";
    device  = ".host:/";
    options = [
      "umask=22" "uid=1000" "gid=1000"
      "allow_other" "auto_unmount" "nofail"
      "x-systemd.automount" "x-systemd.device-timeout=5s"
    ];
  };

  services.cursor-server.enable = true;
}