{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      # Asegúrate de que este archivo exista y no entre en conflicto
      ./libvirt-cockpit.nix 
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Red
  networking.hostName = "nixos-server"; 
  networking.networkmanager.enable = true; # Recomendado para gestionar interfaces fácilmente

  # --- CONFIGURACIÓN DE COCKPIT ---
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        AllowUnencrypted = true; # Ayuda si tienes problemas de TLS inicialmente
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # Habilitar Libvirtd para que Cockpit tenga qué administrar
  virtualisation.libvirtd.enable = true;

  # Usuarios
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" ]; # Añadido libvirtd
    initialPassword = "eracles";
    packages = with pkgs; [
      tree
      cockpit # Aseguramos que el paquete esté presente
    ];
  };

  # Paquetes del sistema
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    virt-manager # Interfaz gráfica opcional para libvirt
    bridge-utils
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes"; # Opcional, según tu seguridad
  };

  # Firewall - IMPORTANTE
  # Aunque lo tengas en false, si lo activas después, Cockpit necesita estos:
  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 9090 22 ];

  # --- CORRECCIÓN DE VERSIÓN ---
  # Si instalaste recientemente, usa "24.11". Si usas la rama inestable, usa "24.11" 
  # pero NUNCA pongas una versión futura que no ha salido.
  system.stateVersion = "24.11"; 

}
