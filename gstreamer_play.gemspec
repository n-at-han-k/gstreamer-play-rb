# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "lib/gstreamer_play/version"

Gem::Specification.new do |spec|
  spec.name = "gstreamer_play"
  spec.version = GstreamerPlay::VERSION
  spec.authors = ["Nathan Kidd"]
  spec.email = ["nathankidd@hey.com"]
  spec.license = "Apache-2.0"

  spec.summary = "Ruby bindings for GstPlay, GStreamer's high-level playback library."
  spec.description = "GstPlay for Ruby, defined from its GObject Introspection typelib at " \
    "require time rather than wrapped by hand. A URI in, playback out: GstPlay builds and " \
    "drives the pipeline itself, runs its own main context, and reports state, position, " \
    "errors and discovered media as signals and bus messages -- so it needs no event loop " \
    "of yours to run, in a GTK application or out of one. Pure Ruby: there is no extension " \
    "to compile, and the binding does not drift as GstPlay gains API."
  spec.homepage = "https://github.com/n-at-han-k/gstreamer-play-rb"

  spec.required_ruby_version = ">= 3.3"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://n-at-han-k.github.io/gstreamer-play-rb/"

  # The library, and nothing else. There is no ext/ and no Cargo workspace: the
  # binding is the loader, which is Ruby.
  #
  # LICENSE and NOTICE ship because the Apache License asks for both: section
  # 4(a) wants every recipient given a copy of the licence, and 4(d) wants the
  # attribution notices carried along with it.
  spec.files = Dir.glob(
    ["{lib}/**/*", "LICENSE", "NOTICE", "README.md", "CHANGELOG.md"],
    File::FNM_DOTMATCH,
    base: __dir__,
  )

  spec.require_paths = ["lib"]

  # GemKit::Deprecate declares a deprecation as a dated promise: the replacement, and the version the old name stops existing in.
  spec.add_dependency "gem_kit", "~> 0.2"

  # The loader. This is the whole binding: GObjectIntrospection::Loader reads
  # GstPlay-1.0.typelib and defines the GstPlay namespace from it. glib2 comes
  # along as its dependency and is what GLib::Log, GLib::MainLoop and the
  # GObject base classes are.
  #
  # Installing this does compile C -- glib2 and gobject-introspection are
  # native extensions built against glib, so a compiler and glib's development
  # headers are needed. What this gem adds on top is nothing, and those two are
  # what every ruby-gnome application already has, since gtk4 depends on them.
  #
  # GStreamer itself is NOT a gem dependency and cannot be: it is a C library
  # and its typelib belongs to the distribution. See the README for the package
  # names. The `gstreamer` gem is deliberately not here either -- GStreamer has
  # to be initialised before GstPlay's types exist, and the loader does that by
  # calling gst_init_check through the typelib, so this gem needs neither that
  # gem nor its compiled extension to do it.
  spec.add_dependency "gobject-introspection", "~> 4.3"

  spec.add_development_dependency "lefthook", "~> 2.2"
end
