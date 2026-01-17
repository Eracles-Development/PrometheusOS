{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./libvirt-cockpit.nix  
  ];

  # Configuración del Bootloader (Ajusta si usas GRUB o Systemd-boot)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configuración de Red
  networking.hostName = "nixos-server"; # Cámbialo si quieres
  networking.networkmanager.enable = true;

  # Configuración de Usuario (Asegúrate de que tu usuario esté aquí)
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "networkmanager" ];
    password = "eracles"; 
  };

  # Versión del sistema (No la borres ni cambies)
  system.stateVersion = "25.05"; 

  # Permitir software no libre (opcional)
  nixpkgs.config.allowUnfree = true;
}