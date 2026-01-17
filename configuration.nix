{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./libvirt-cockpit.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "eracles1"; 
  networking.networkmanager.enable = true;

  # Configuración de firewall general
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 9090 ];

  # Usuario principal
  users.users.eracles = {
    isNormalUser = true;
    description = "Eracles";
    extraGroups = [ 
      "wheel" 
      "networkmanager"
      "dialout" 
      "audio"
    ];
  };

  # Shell por defecto
  users.defaultUserShell = pkgs.bash;

  # Paquetes básicos del sistema
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
  ];

  # Habilitar soporte para hardware
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

  # Configuración de Nix
  nixpkgs.config.allowUnfree = true;
  
  # Servicio SSH (opcional)
  services.openssh.enable = true;
  
  # Zona horaria
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "24.11"; 
}