{ config, lib, pkgs, modulesPath, ... }:

let
  MAIN_PART = "/dev/disk/by-uuid/8745497b-25df-415a-89fa-5aef1ffd2a9a";
  BOOT_PART = "/dev/disk/by-uuid/E03E-5244";
  SWAP_PATH = "/swapfile";
  SWAP_SIZE = 32;
  RESUME_OFFSET = "244056064";
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    # Bootloader
    loader = {
      systemd-boot = {
        enable = true;
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      availableKernelModules =
        [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    # Swapfile hibernate
    resumeDevice = "${MAIN_PART}";
    kernelParams = [ "resume_offset=${RESUME_OFFSET}" ];
  };

  fileSystems = {
    "/" = {
      device = "${MAIN_PART}";
      fsType = "ext4";
      options = [ "noatime" "defaults" ];
    };

    "/boot" = {
      device = "${BOOT_PART}";
      fsType = "vfat";
      options = [ "relatime" "umask=0077" "defaults" ];
    };
  };

  swapDevices = [{
    device = "${SWAP_PATH}";
    size = SWAP_SIZE * 1024;
  }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
