{ ... }:

let
  sampleRate = 48000;
  defaultQuantum = 64;
  minQuantum = 32;
  maxQuantum = 1024;
  defaultLatency = "${toString defaultQuantum}/${toString sampleRate}";
  minLatency = "${toString minQuantum}/${toString sampleRate}";
  maxLatency = "${toString maxQuantum}/${toString sampleRate}";
in
{
  security = {
    rtkit.enable = true;

    pam.loginLimits = [
      {
        domain = "@audio";
        type = "-";
        item = "rtprio";
        value = "95";
      }
      {
        domain = "@audio";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@audio";
        type = "-";
        item = "nice";
        value = "-19";
      }
    ];
  };

  services = {
    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      audio.enable = true;
      wireplumber.enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

      pulse.enable = true;
      jack.enable = true;

      extraConfig = {
        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = sampleRate;
            "default.clock.quantum" = defaultQuantum;
            "default.clock.min-quantum" = minQuantum;
            "default.clock.max-quantum" = maxQuantum;
            "mem.allow-mlock" = true;
          };
        };

        client."92-low-latency" = {
          "stream.properties" = {
            "node.latency" = defaultLatency;
            "resample.quality" = 10;
          };
        };

        pipewire-pulse."92-low-latency" = {
          "pulse.properties" = {
            "pulse.default.req" = defaultLatency;
            "pulse.min.req" = minLatency;
            "pulse.max.req" = maxLatency;
            "pulse.min.quantum" = minLatency;
            "pulse.max.quantum" = maxLatency;
            "resample.quality" = 10;
          };

          "stream.properties" = {
            "node.latency" = defaultLatency;
          };
        };

        jack."92-low-latency" = {
          "jack.properties" = {
            "node.latency" = defaultLatency;
            "node.lock-quantum" = true;
            "rt.prio" = 88;
            "jack.show-midi" = true;
            "jack.self-connect-mode" = "allow";
            "jack.max-client-ports" = 1024;
          };
        };
      };
    };
  };
}
