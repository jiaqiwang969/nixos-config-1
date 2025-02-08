{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.mitchellh = {
    isNormalUser = true;
    home = "/home/mitchellh";
    extraGroups = [ "docker" "lxd" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$8WqHXBEi1JIIAhUh$HmYTH8DLPG.NVxo.Cmj1yDb/55ASwVehYWUpSY8gZEk33q1nx5FkdaXoX5s/yw50GaEPehWnQuQE3PJ13b3he/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+VXTehNqZod7c/B+dW8Ky2B946nG0ud9zyzEue7LUr jqwang"
    ];
  };


  users.users.jqwang = {
    isNormalUser = true;
    home = "/home/jqwang";
    extraGroups = [ "docker" "lxd" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$8WqHXBEi1JIIAhUh$HmYTH8DLPG.NVxo.Cmj1yDb/55ASwVehYWUpSY8gZEk33q1nx5FkdaXoX5s/yw50GaEPehWnQuQE3PJ13b3he/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+VXTehNqZod7c/B+dW8Ky2B946nG0ud9zyzEue7LUr jqwang"
    ];
  };



  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix { inherit inputs; })
  ];
}
