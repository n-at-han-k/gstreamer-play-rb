# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module GstPlay
  # Defines everything in the GstPlay namespace from gst-plugins-bad's typelib.
  #
  # Modelled on ruby-gnome's own loaders (see gtksourceview5/lib/gtksourceview5/loader.rb,
  # which also has an init function to call, and gstreamer/lib/gst/loader.rb,
  # which is where the `gst_init_check` call below comes from).
  #
  # The version string is the typelib's, not the library's: GStreamer 1.28
  # ships `GstPlay-1.0.typelib`, so the version here is "1.0".
  class Loader < GObjectIntrospection::Loader
    def load
      self.version = "1.0"
      super("GstPlay")
    end

    private

    # GStreamer must be initialised before the GstPlay namespace is read.
    #
    # This is not a nicety. `gst_init` is what registers GStreamer's GTypes,
    # and the loader walks the typelib asking GObject about each one as it
    # goes. Without it, loading GstPlaySignalAdapter dies in GLib with
    #
    #   gsignal.c: parameter 2 of type '<invalid>' for signal
    #   "GstPlaySignalAdapter::error" is not a value type
    #
    # and what you are left with is a namespace that looks loaded -- the
    # constants are all there -- and then misbehaves. GtkSource has the same
    # shape of problem and ruby-gnome solves it the same way, in `pre_load`.
    def pre_load(repository, namespace)
      initialize_gstreamer(repository)
    end

    # `gst_init_check` rather than `gst_init`, because `gst_init` aborts the
    # process on failure and this returns the GError instead. argv is passed
    # and read back the way ruby-gnome's own Gst::Loader does it: GStreamer
    # consumes its own `--gst-*` options out of it.
    #
    # Done through the repository rather than through a Ruby `Gst` module on
    # purpose. This gem defines one namespace, GstPlay, and depends only on
    # `gobject-introspection`; initialising the C library does not need the
    # `gstreamer` gem's compiled extension, and taking a dependency on it to
    # make one call would make this gem's install a GStreamer build too.
    # `gst_init_check` is idempotent, so an application that also uses the
    # `gstreamer` gem can call `Gst.init` whenever it likes.
    def initialize_gstreamer(repository)
      repository.require("Gst", "1.0")

      succeeded, _argv, error = repository.find("Gst", "init_check").invoke([[$0]])
      raise error unless succeeded
    end

    def post_load(repository, namespace)
      require_libraries
    end

    def require_libraries
      # Nothing yet. Hand-written Ruby that improves on what the typelib gives
      # -- an each that yields, a to_s, a keyword-argument constructor -- goes
      # in files required from here, which is the convention ruby-gnome uses
      # for exactly that purpose.
    end
  end
end
