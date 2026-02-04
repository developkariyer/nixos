# Android development: Android Studio with emulator support
{ config, lib, pkgs, ... }:

{
  # Accept Android SDK license (required for build)
  nixpkgs.config.android_sdk.accept_license = true;

  # Android Studio with full SDK bundle (platforms 28-34, emulator, NDK)
  environment.systemPackages = [ pkgs.android-studio-full ];

  # KVM access for emulator hardware acceleration
  users.users.ubuntu.extraGroups = [ "kvm" ];
}
