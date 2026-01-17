{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./libvirt-cockpit.nix  # Importamos solo libvirt-cockpit.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "eracles1"; 
  networking.networkmanager.enable = true;

  # Configuración de firewall general
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 9090 ];  # SSH + Cockpit

  # Usuario principal
  users.users.eracles = {
    isNormalUser = true;
    description = "Eracles";
    createHome = true;
    home = "/home/eracles";
    extraGroups = [ 
      "wheel" 
      "networkmanager"
      "dialout" 
      "audio"
      # Los grupos de libvirt se añaden en libvirt-cockpit.nix
    ];
    # Si no tienes contraseña configurada, descomenta esta línea:
    # initialPassword = "nixos123";
  };

  # Shell por defecto
  users.defaultUserShell = pkgs.bash;

  # Paquetes básicos del sistema
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    btop
    tmux
    unzip
  ];

  # Habilitar soporte para hardware
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.extraModulePackages = [];

  # Parámetros del kernel para virtualización (si tienes Intel/AMD VT-d)
  boot.kernelParams = [ 
    # Para Intel
    "intel_iommu=on" 
    # Para AMD
    # "amd_iommu=on"
  ];

  # Configuración de Nix
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Servicios básicos
  services.nix-daemon.enable = true;
  services.openssh.enable = true;
  
  # Zona horaria
  time.timeZone = "America/New_York";  # Cambia según tu zona
  i18n.defaultLocale = "en_US.UTF-8";

  # Teclado
  services.xserver.layout = "us";  # Cambia si necesitas otro layout
  console.useXkbConfig = true;

  system.stateVersion = "24.11"; 
}