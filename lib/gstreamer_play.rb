# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "gobject-introspection"

require_relative "gstreamer_play/version"
require_relative "gstreamer_play/loader"

# Ruby bindings for GstPlay, GStreamer's high-level playback library.
#
# There is no compiled extension here and nothing in this gem wraps a GstPlay
# function by hand. gst-plugins-bad ships a GObject Introspection typelib
# describing every class, method, property and signal GstPlay has, and
# ruby-gnome's GObjectIntrospection::Loader reads that at require time and
# defines the Ruby classes from it. {GstPlay::Loader} is a few dozen lines;
# what you get is the whole library, and it does not drift when GstPlay gains
# a method.
#
# This is how ruby-gnome itself ships gtksourceview5, adwaita and the rest.
#
# {Play} is the playback object: give it a URI, call `play`, and it builds and
# drives a `playbin3` underneath, on its own main context and its own thread.
# It reports state, position, errors and discovered media as {PlayMessage}s on
# a bus, and {PlaySignalAdapter} turns those into GObject signals -- so it
# needs no event loop of yours to run, in a GTK application or out of one.
#
#   require "gstreamer_play"
#
#   play = GstPlay::Play.new
#   play.uri = "file:///music/track.opus"
#   play.play
#
# GStreamer has to be initialised before any of these types exist, which the
# loader does in `pre_load` -- see the comment there for why that is not
# optional, and why it does not require the `gstreamer` gem to do it.
#
# The typelib has to be findable at require time, which means gst-plugins-bad's
# `girepository-1.0` directory on `GI_TYPELIB_PATH` (or in the system default),
# along with the ones GstPlay-1.0.typelib names as dependencies: Gst, GstBase,
# GstVideo, GstAudio, GstTag and GstPbutils. This gem cannot install them: they
# are C libraries, so they belong to the distribution. See the README for the
# package names. The dev shell in `flake.nix` wires it all up.
#
# One trap, paid for already: the typelib must come from the same glib build as
# the `gobject-introspection` gem. Mix two and GIO gets registered twice in one
# process, which fails as `cannot register existing type 'GTlsCertificate'`.
module GstPlay
  LOG_DOMAIN = "GstPlay"
  GLib::Log.set_log_domain(LOG_DOMAIN)

  class Error < StandardError
  end

  loader = Loader.new(self)
  loader.load
end
