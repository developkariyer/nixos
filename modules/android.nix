# Android development: Android Studio with emulator support
{ config, lib, pkgs, ... }:

{
  # Accept Android SDK license (required for build)
  nixpkgs.config.android_sdk.accept_license = true;

  # Android Studio (minimal - use SDK Manager for components)
  environment.systemPackages = [ pkgs.android-studio ];

  # KVM access for emulator hardware acceleration
  users.users.ubuntu.extraGroups = [ "kvm" ];
}
