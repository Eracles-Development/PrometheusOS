{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
  ];

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.openssh.enable = true;

  # Bootloader (Asegúrate de que esto coincida con tu servidor)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "eracles1"; 
  networking.networkmanager.enable = true;

  # Usuario
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "networkmanager" ];
  };

  # Configuración del sistema
  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = "23.11"; 
}