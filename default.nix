let
  nixpkgsVersion =
    {
      date = "2020-05-21";
      rev = "6405edf2dca7f6faaa29266136dfa7f8f969b511";
      tarballHash = "069skn0ayxmhdlw1xcj92cij7wydkk2bndkcyk4vvhms16p9wj46";
    };

  nixpkgs =
    builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${nixpkgsVersion.rev}.tar.gz";
      sha256 = nixpkgsVersion.tarballHash;
    };

  pkgs =
    import nixpkgs { };
in
{
  inherit pkgs;

  run =
    pkgs.writeShellScriptBin "run"
      ''
      '';

  test =
    pkgs.writeShellScriptBin "test"
      ''
      '';
}
