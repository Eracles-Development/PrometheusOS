{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./libvirt-cockpit.nix  # Asegúrate de que el archivo se llame exactamente así
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "eracles1"; 
  networking.networkmanager.enable = true;

  # Usuario con todos los grupos necesarios para virtualización
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "networkmanager" "kvm" ];
  };

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11"; 
}