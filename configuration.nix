{ config, pkgs, ... }:

{
  imports =
    [ 
      # ESTA LÍNEA ES VITAL: Importa la configuración de tus discos y hardware
      ./hardware-configuration.nix
    ];

  # 1. Configuración del Bootloader (Ajusta según si usas GRUB o Systemd-boot)
  # Si tu servidor es antiguo o usa BIOS/Legacy:
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1"; # O el disco donde instalaste (ej: /dev/nvme0n1)
  
  # Si tu servidor es moderno y usa UEFI, comenta lo de arriba y usa esto:
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # 2. Configuración de Cockpit 
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        Origins = "https://192.168.8.122:9090";
        AllowUnencrypted = true;
      };
    };
  };

  # 3. Seguridad y Firewall
  security.polkit.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # 4. Versión del sistema 
  system.stateVersion = "25.05"; 

  # El resto de tu configuración 
  users.users.tu_usuario = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Para que puedas usar sudo
  };
}