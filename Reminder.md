操作办法：将configuration.nix 替换到/etc/nixos/configuration.nix中
然后：suod nixos-rebuild switch

# VM 网络配置修改备忘

> 适用：`vm-intel` 虚拟机首次安装 / `make vm/bootstrap0` 阶段

1. **改用 systemd-networkd**
   ```nix
   networking.useDHCP               = false;
   networking.networkmanager.enable = false;
   networking.nameservers           = [ "192.168.137.1" "1.1.1.1" ];

   systemd.network.enable = true;
   ```
2. **接口配置**
   ```nix
   # ens36 —— Host-only，固定私网 + 默认路由
   systemd.network.networks."10-ens36" = {
     matchConfig.Name      = "ens36";
     networkConfig.Address = "192.168.137.33/24";
     networkConfig.Gateway = "192.168.137.1";
     networkConfig.DNS     = "192.168.137.1";
     linkConfig.RequiredForOnline = "yes";
   };

   # ens33 —— 桥接，DHCP，但禁止抢默认路由
   systemd.network.networks."20-ens33" = {
     matchConfig.Name        = "ens33";
     networkConfig.DHCP      = "ipv4";      # 只拿 IPv4
     dhcpConfig.RouteMetric  = 6000;         # RouteMetric 必须放在 dhcpConfig
     networkConfig.IPv6AcceptRA = "no";
     linkConfig.RequiredForOnline = "no";
   };

   # 不等待 networkd-wait-online
   systemd.network.wait-online.enable = false;
   ```
3. **Nix / OpenSSH 其他附加行**（与网络无关，此处记录方便备份）
   ```nix
   nix = {
     package      = pkgs.nixVersions.latest;
     extraOptions = "experimental-features = nix-command flakes";
     settings = {
       substituters        = [ "https://jiaqiwang969.cachix.org" ];
       trusted-public-keys = [
         "jiaqiwang969.cachix.org-1:FXY5IvEszf/K/0ZhwnrG+cy+nsPc/nVHYSM8WnQaMvE="
       ];
     };
   };

   services.openssh = {
     enable = true;
     settings = {
       PasswordAuthentication = true;
       PermitRootLogin        = "yes";
     };
   };
   users.users.root.initialPassword = "root";
   ```
4. **纯 shell 无编辑器写入方法**
   ```bash
   # 把自定义块写到临时文件
   cat > /tmp/net.nix <<'NET'
   # 上面的 systemd.network.* 内容……
   NET

   # 删除旧 networking / systemd.networkd 行
   sed -i -e '/networking\.useDHCP/d' \
          -e '/networking\.networkmanager\.enable/d' \
          -e '/networking\.nameservers/d' \
          -e '/systemd\.network\./d' \
          /etc/nixos/configuration.nix

   # 插入到 system.stateVersion 行之后
   sed -i '/system\.stateVersion/r /tmp/net.nix' /etc/nixos/configuration.nix
   ```
5. **常见踩坑**
   * `RouteMetric` 只能放在 `dhcpConfig`，放错段会报 _extra fields_。
   * `sed 'a\'` 后面必须立即换行，长文本推荐 `sed … r file`。
   * `hardware-configuration.nix` 会被 `nixos-generate-config` 覆盖，持久网络配置应放 `configuration.nix`。 