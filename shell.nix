# shell.nix
{ pkgs ? import <nixpkgs> {} }:
let
  pythonPackages = ps: with ps; [
    numpy
    (
    buildPythonPackage rec {
      pname = "futhark-data";
      version = "1.0.1";
      src = fetchPypi {
        inherit pname version;
        sha256 = "sha256-UJ0x642f5Q9749ffYIimQuF+sMTVOyx4iYZgrB86HFo=";
      };
      doCheck = false;
      propagatedBuildInputs = [
        # Specify dependencies
        pkgs.python3Packages.numpy
      ];
    }
  )
  ];
  myPython = pkgs.python3.withPackages pythonPackages;
in myPython.env
