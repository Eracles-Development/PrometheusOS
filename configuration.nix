{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./libvirt-cockpit.nix 
  ];

  # Bootloader: Configuración estándar para servidores modernos (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Red
  networking.hostName = "eracles1"; 
  networking.networkmanager.enable = true;

  # Configuración de Usuario
  users.users.eracles = {
    isNormalUser = true;
    description = "Administrador del Sistema";
    # 'wheel' para sudo, 'libvirtd' y 'kvm' para gestionar máquinas virtuales
    extraGroups = [ "wheel" "libvirtd" "kvm" "networkmanager" ];
  };

  # Paquetes base esenciales para la terminal
  environment.systemPackages = with pkgs; [
     vim
     wget
     git
     htop
     pciutils  # Útil para diagnosticar hardware en virtualización
     usbutils  # Útil para ver dispositivos USB
  ];

  # Configuración del sistema
  nixpkgs.config.allowUnfree = true;
  
  # IMPORTANTE: No cambies este valor. 
  # Aunque uses NixOS 25.05 (Unstable), stateVersion indica con qué versión 
  # se inicializaron tus datos originales para mantener compatibilidad.
  system.stateVersion = "24.11"; 
}