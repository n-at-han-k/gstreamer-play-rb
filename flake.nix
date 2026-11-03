{
  description = "gstreamer_play — Ruby bindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, mine, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        gemspecFiles = pkgs.runCommand "gstreamer_play-gemspec" { } ''
          mkdir -p $out/lib/gstreamer_play
          cp ${./gstreamer_play.gemspec}         $out/gstreamer_play.gemspec
          cp ${./lib/gstreamer_play/version.rb}  $out/lib/gstreamer_play/version.rb
        '';

        gems = pkgs.bundlerEnv {
          name = "gstreamer_play-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = import ./gemset.nix;
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

        # The GStreamer packages this binding reads at runtime. gst-plugins-bad
        # is the one that carries GstPlay. Nothing here is compiled against:
        # this gem has no extension, so these are typelibs and plugins, not
        # headers and libraries.
        gstPackages = with pkgs.gst_all_1; [
          gst-plugins-bad
          gst-plugins-base
          gstreamer
          gst-plugins-good
        ];

        # The namespaces the loader needs at require time: GstPlay itself, the
        # six GStreamer namespaces GstPlay-1.0.typelib declares as dependencies
        # (Gst, GstBase, GstVideo, GstAudio, GstTag, GstPbutils), and
        # GLib/GObject/Gio under those.
        #
        # `makeSearchPath` would take each package's *first* output, and both
        # glib's and gstreamer's first output is `bin`, which carries no
        # typelibs -- hence the explicit `.out`. That trap has cost real time
        # twice.
        typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0"
          (map (drv: drv.out or drv) (gstPackages ++ [ pkgs.glib ]));

        # Where GStreamer looks for its own plugins. The suite needs this, not
        # just playback: GstPlay::Play.new builds a `playbin3`, and GstPlay
        # treats a missing playbin3 as a fatal g_error rather than as something
        # it can report. nixpkgs' setup hooks would populate this from
        # buildInputs anyway; it is set explicitly so that what the suite needs
        # is written down rather than inherited.
        gstPluginPath = pkgs.lib.makeSearchPath "lib/gstreamer-1.0"
          (map (drv: drv.out or drv) gstPackages);
      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            # GStreamer, for its typelibs and its plugins. Taking them from the
            # same nixpkgs as the gobject-introspection gem is not a tidiness
            # point: a typelib built against a different glib registers GIO a
            # second time in the process and dies with
            #   cannot register existing type 'GTlsCertificate'
          ] ++ gstPackages ++ [
            skywalking-eyes
          ];

          shellHook = /* bash */ ''
            # GstPlay-1.0.typelib, plus the typelibs it depends on. GstPlay-1.0
            # declares Gst-1.0, GstBase-1.0, GstVideo-1.0, GstAudio-1.0,
            # GstTag-1.0 and GstPbutils-1.0, and the loader resolves those
            # transitively at require time, so gstreamer's and
            # gst-plugins-base's girepository directories have to be here too
            # or the load fails with "Typelib file for namespace 'Gst' not
            # found". glib's is here for GLib-2.0, GObject-2.0 and Gio-2.0
            # under them.
            export GI_TYPELIB_PATH="${typelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"

            # playbin3 is in gst-plugins-base's `playback` plugin, scaletempo
            # in good's `audiofx`, and the decoders behind them in good and
            # bad. Without this, constructing a GstPlay::Play aborts the
            # process.
            export GST_PLUGIN_SYSTEM_PATH_1_0="${gstPluginPath}''${GST_PLUGIN_SYSTEM_PATH_1_0:+:$GST_PLUGIN_SYSTEM_PATH_1_0}"

            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"
          '';
        };
      }
    );
}
