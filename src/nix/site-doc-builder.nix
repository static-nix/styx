{ pkgs ? import <nixpkgs> {}
, siteFile }:

pkgs.callPackage (import ./site-doc.nix) {
  site = (import siteFile) { extraConf.siteUrl = "http://domain.org"; };
}
