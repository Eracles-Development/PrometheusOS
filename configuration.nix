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
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.openssh.enable = true;

  # Bootloader (Asegúrate de que esto coincide con tu servidor)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "eracles1"; 
  networking.networkmanager.enable = true;

  # Usuario
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "networkmanager" "kvm" ];
  };

  # Configuración del sistema
  nixpkgs.config.allowUnfree = true;
  
  # Deshabilitar systemd-oomd para evitar incompatibilidades
  systemd.services.systemd-oomd.enable = false;
  
  system.stateVersion = "24.11"; 
}