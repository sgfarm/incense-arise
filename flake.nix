{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils}: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ ];
        pkgs = (import nixpkgs) {
          inherit system overlays;
        };

        playlist = ./playlist.m3u;

        container = pkgs.dockerTools.buildLayeredImage {
          name = "incense-arise";
          tag = "latest";
          contents = [ pkgs.cacert ];
          config = {
            # runs the executable with tini: https://github.com/krallin/tini
            # this does signal forwarding and zombie process reaping
            Entrypoint = [ "${pkgs.tini}/bin/tini" "--" ];
            User = "1000";
            Cmd = [
              "${pkgs.vlc}/bin/cvlc" "${playlist}" "-v" "--loop" "--random"
              "--sout-all" "--sout-keep" "--sout"
              "#transcode{vcodec=h264,acodec=mp4a,ab=256,channels=2,samplerate=44100}:http{mux=ts,dst=:3000/}"
            ];
          };
        };
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            just yt-dlp awscli flyctl
          ];
        };
        packages = {
          inherit container;
          default = container;
        };
      });
}
