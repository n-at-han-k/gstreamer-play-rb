# gstreamer_play

Ruby bindings for [GstPlay](https://gstreamer.freedesktop.org/documentation/play/index.html),
GStreamer's high-level playback library.

```ruby
require "gstreamer_play"

play = GstPlay::Play.new
play.uri = "file:///music/track.opus"
play.volume = 0.8
play.play

main_loop = GLib::MainLoop.new

# Everything it does, it reports. GstPlay::PlaySignalAdapter turns that into
# GObject signals on a main context of your choosing -- the application's, if
# you have one.
adapter = GstPlay::PlaySignalAdapter.new(play)
adapter.signal_connect("state-changed") { |_adapter, state| puts state }
adapter.signal_connect("position-updated") { |_adapter, position| puts position }
adapter.signal_connect("end-of-stream") { main_loop.quit }

main_loop.run
```

Give `GstPlay::Play` a URI and it builds and drives a `playbin3` underneath, on
its own GLib main context and its own thread. Nothing above needs an event loop
of its own for playback to run — the main loop there is only so that the
process stays alive to hear the signals, and in a GTK application you already
have one.

The other way to read what it is doing is `play.message_bus`, which carries
`GstPlay::PlayMessage`s. Pulling them off that bus means calling `Gst::Bus`
methods, which belong to the `gstreamer` gem rather than to this one — with
just this gem, use the signal adapter.

## How this works, and why there is nothing here to compile

gst-plugins-bad ships a GObject Introspection typelib that describes every
class, method, property and signal GstPlay has. `GstPlay::Loader` hands that
typelib to ruby-gnome's `GObjectIntrospection::Loader`, which defines the Ruby
classes from it at `require` time.

So this gem is pure Ruby: no extension of its own, no Cargo workspace, no
per-platform binary. You get the whole library rather than the subset somebody
got round to wrapping by hand, and it does not drift when GstPlay gains API.

It is worth being precise about what that does and does not buy you at install
time. `gem install gstreamer_play` still compiles C, because
`gobject-introspection` and `glib2` are themselves native extensions built
against glib — so a compiler and glib's development headers are needed. What
this gem adds on top of that is nothing: those two are what every ruby-gnome
application already has, since `gtk4` depends on them. If you are writing a
Ruby GTK app, gstreamer_play costs you no build step you were not already
paying.

Note also what is *not* a dependency: the `gstreamer` gem. GStreamer has to be
initialised before GstPlay's types exist, and the loader does that by calling
`gst_init_check` through the typelib — so this gem does not pull in that gem's
compiled extension to make one call. If your application wants the `Gst`
namespace in Ruby as well, add the `gstreamer` gem for it; the two coexist.

This is how [ruby-gnome](https://github.com/ruby-gnome/ruby-gnome) itself ships
gtksourceview5, libsecret and the rest.

## What you must install

The typelib and the plugins are C-library artefacts, so they belong to your
distribution and this gem cannot install them. GstPlay is in
**gst-plugins-bad**, not in GStreamer core:

| | |
|---|---|
| Debian / Ubuntu | `gstreamer1.0-plugins-bad`, plus `gir1.2-gst-plugins-bad-1.0` for the typelib and `gstreamer1.0-plugins-base` and `-good` for `playbin3` and its decoders |
| Fedora | `gstreamer1-plugins-bad-free`, `gstreamer1-plugins-base`, `gstreamer1-plugins-good` |
| Arch | `gst-plugins-bad`, `gst-plugins-base`, `gst-plugins-good` |
| nix | `pkgs.gst_all_1.gst-plugins-bad`, `pkgs.gst_all_1.gst-plugins-base`, `pkgs.gst_all_1.gst-plugins-good`, `pkgs.gst_all_1.gstreamer` |

If the typelibs are not in the default search path, point `GI_TYPELIB_PATH` at
the directory holding `GstPlay-1.0.typelib` — and at the ones holding the
typelibs it depends on: `Gst-1.0`, `GstBase-1.0` (GStreamer core),
`GstVideo-1.0`, `GstAudio-1.0`, `GstTag-1.0` and `GstPbutils-1.0`
(gst-plugins-base). The dev shell in `flake.nix` does all of this.

**The plugins are not optional.** `GstPlay::Play.new` constructs a `playbin3`,
and GstPlay treats a missing `playbin3` as a fatal error that aborts the
process rather than something it can report. If GStreamer cannot find its
plugins, set `GST_PLUGIN_SYSTEM_PATH_1_0`.

**One trap worth knowing.** The typelibs must come from the same glib build as
the `gobject-introspection` gem. Mixing two registers GIO twice in one process
and fails with `cannot register existing type 'GTlsCertificate'`. Under nix,
take both from one nixpkgs — and note that glib's and gstreamer's typelibs are
in their `out` output, not the default `bin` one.

## Development

```sh
nix develop
bin/test
```

## Licence

Apache-2.0. GStreamer itself is LGPL-2.1-or-later; this gem links nothing and
copies no GStreamer code — it reads a description of it at runtime.
