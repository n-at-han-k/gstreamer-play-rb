# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "gstreamer_play"

describe GstPlay do
  it "defines the namespace from the typelib" do
    # Not an arbitrary number: it is the point of the loader. A hand-written
    # binding exposes what someone got round to wrapping; this exposes what
    # GstPlay has. GstPlay-1.0 is a small namespace -- one playback object and
    # the media-info and enum types around it -- so the bar is a dozen, and a
    # drop below that means the loader silently half-ran.
    expect(GstPlay.constants.size).to be > 12
  end

  it "defines the classes a caller actually reaches for" do
    expect(GstPlay.const_defined?(:Play)).to be == true
    expect(GstPlay.const_defined?(:PlayMessage)).to be == true
    expect(GstPlay.const_defined?(:PlayMediaInfo)).to be == true
    expect(GstPlay.const_defined?(:PlayVideoInfo)).to be == true
    expect(GstPlay.const_defined?(:PlaySignalAdapter)).to be == true
  end

  it "defines the enumerations, with their members" do
    # PlayState is what every caller switches on, and an enum whose members did
    # not land is the shape of half-load that still answers const_defined?.
    expect(GstPlay::PlayState.const_defined?(:PLAYING)).to be == true
    expect(GstPlay::PlayState.const_defined?(:STOPPED)).to be == true
  end

  it "maps GObject methods onto the class, not just constants" do
    # A loader that registered the types but no methods would still satisfy
    # every assertion above, so this is the one that catches it. Play has over
    # a hundred; twenty is a floor, not a measurement.
    expect((GstPlay::Play.instance_methods - Object.instance_methods).size).to be > 20
  end

  it "subclasses the GObject hierarchy it belongs to" do
    # GstPlay::Play is a GstObject. If the loader had not initialised GStreamer
    # first, its GTypes would not be registered and this would not resolve.
    expect(GstPlay::Play.ancestors).to be(:include?, GLib::Object)
  end

  with "a player" do
    # Real, and real work: this builds a playbin3 underneath and starts the
    # thread that drives it. It needs GStreamer's plugins -- flake.nix puts
    # them on GST_PLUGIN_SYSTEM_PATH_1_0 -- but no display and no main loop of
    # ours, which is the property that makes GstPlay worth binding.
    let(:play) { GstPlay::Play.new }

    it "constructs" do
      expect(play).to be_a(GstPlay::Play)
    end

    it "round-trips a GObject property" do
      play.volume = 0.25

      expect(play.volume).to be_within(0.001).of(0.25)
    end

    it "takes a URI and reads it back" do
      play.uri = "file:///does/not/exist.opus"

      expect(play.uri).to be == "file:///does/not/exist.opus"
    end

    it "answers for its own configuration" do
      # `config` comes back as a Gst::Structure, which is a type from another
      # namespace: a loader that resolved only its own would not return one.
      expect(play.config).not.to be_nil
    end

    it "has not discovered any media yet" do
      expect(play.media_info).to be_nil
    end
  end

  with "the signal adapter" do
    # The one that proves `pre_load` ran. GstPlaySignalAdapter's "error" signal
    # takes a GError, and without `gst_init` first that parameter's type comes
    # back as '<invalid>' -- GLib refuses to register the signal, and what is
    # left is an adapter whose signals never fire. Constants and methods all
    # look fine in that state, so nothing above this catches it.
    it "emits state changes onto a main loop" do
      play = GstPlay::Play.new
      adapter = GstPlay::PlaySignalAdapter.new(play)

      main_loop = GLib::MainLoop.new

      states = []
      adapter.signal_connect("state-changed") do |_adapter, state|
        states << state
        main_loop.quit
      end

      play.uri = "file:///does/not/exist.opus"
      play.play

      # GstPlay drives itself on its own thread; the adapter marshals onto this
      # main context, which the first state change quits. The URI is
      # deliberately missing -- GstPlay reports that as a message rather than an
      # exception, and the states still arrive. The timeout is the backstop that
      # turns a signal which never fires into a failure rather than a hang.
      GLib::Timeout.add(5_000) do
        main_loop.quit
        GLib::Source::REMOVE
      end
      main_loop.run

      expect(states).not.to be(:empty?)
      expect(states.first).to be_a(GstPlay::PlayState)
    end
  end

  it "also defines GstBadAudio from the same package" do
    # GstBadAudio-1.0 ships alongside GstPlay's typelib, so this gem covers it
    # too. Asserted because a silent regression here would quietly reopen a
    # gap on the Bindings board.
    expect(Object.const_defined?(:GstBadAudio)).to be == true
    expect(GstBadAudio.constants.size).to be > 5
  end
end
