# sudo nixos-rebuild switch

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./libvirt-virt-manager.nix
    ];

  # =========================================================================
  # System & Boot
  # =========================================================================
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Enable IP Forwarding (needed for containers/VMs)
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # =========================================================================
  # Power Management
  # =========================================================================
  
  # Prevent suspension/shutdown when lid is closed
  services.logind.lidSwitch = "ignore";

  # =========================================================================
  # Networking
  # =========================================================================
  
  networking.firewall = {
    enable = true;
    # "checkReversePath = false" usually needed for libvirt/VPNs
    checkReversePath = false; 
    trustedInterfaces = [ "tailscale0" "virbr0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # =========================================================================
  # Services
  # =========================================================================

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
    };
  };
  programs.ssh.setXAuthLocation = true;

  # Enable Tailscale
  services.tailscale.enable = true;

  # =========================================================================
  # Users & Environment
  # =========================================================================

  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "eracles";
    packages = with pkgs; [
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  system.stateVersion = "25.05"; # Did you read the comment?

}
