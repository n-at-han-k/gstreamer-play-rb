# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# GstBadAudio -- the audio elements that live in gst-plugins-bad, which Amberol and gnome-podcasts reach for.
#
# It lives here rather than in a gem of its own because `GstBadAudio-1.0.typelib`
# ships in the same package as GstPlay's, so this gem already pins everything
# it needs and already has gst_init run by GstPlay's loader. A separate gem
# would add a repository, a release and a dependency for twenty lines.
module GstBadAudio
  LOG_DOMAIN = "GstBadAudio"
  GLib::Log.set_log_domain(LOG_DOMAIN)

  class Error < StandardError
  end

  # Modelled on ruby-gnome's gstreamer gem, which brings up GstBase,
  # GstController and GstAudio behind Gst in exactly this way.
  class Loader < GObjectIntrospection::Loader
    def load
      self.version = "1.0"
      super("GstBadAudio")
    end
  end

  Loader.new(self).load
end
