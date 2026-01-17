# sudo nixos-rebuild switch

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./cockpit.nix
    ];

  # Use the systemd-boot EFI boot loader.
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;

   users.users.eracles = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; 
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

  system.stateVersion = "25.05"; # Did you read the comment?

}

