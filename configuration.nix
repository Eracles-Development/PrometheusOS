# sudo nixos-rebuild switch

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./libvirt-virt-manager.nix
    ];

  # Use the systemd-boot EFI boot loader.
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;

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

  # Enable the OpenSSH daemon.
   services.openssh = {
     enable = true;
     settings = {
       X11Forwarding = true;
     };
   };
   programs.ssh.setXAuthLocation = true;

  # Enable Tailscale and configure firewall
  services.tailscale.enable = true;
  
  # Habilitar IP Forwarding para que funcionen los contenedores/VMs
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.firewall = {
    enable = true;
    # "checkReversePath = false" suele ser necesario para libvirt/VPNs
    checkReversePath = false; 
    trustedInterfaces = [ "tailscale0" "virbr0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  system.stateVersion = "25.05"; # Did you read the comment?

}

