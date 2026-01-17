{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./libvirt-cockpit.nix 
  ];

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
  ];

  # Bootloader
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