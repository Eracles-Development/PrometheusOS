{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./cockpit.nix 
  ];

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
  ];

  networking.firewall.enable = false;

  # Bootloader (Asegúrate de que esto coincide con tu servidor)
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
  
  system.stateVersion = "24.11"; 
}