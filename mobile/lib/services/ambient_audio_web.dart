// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playAmbientSound(String type, double volume) {
  try {
    js.context.callMethod('eval', ["""
      (function() {
        if (window._kausapAudio) {
          window._kausapAudio.stop();
        }
        window.AudioContext = window.AudioContext || window.webkitAudioContext;
        if (!window.AudioContext) return;
        var ctx = window._kausapAudioCtx || new window.AudioContext();
        window._kausapAudioCtx = ctx;
        if (ctx.state === 'suspended') {
          ctx.resume();
        }
        var masterGain = ctx.createGain();
        masterGain.gain.value = $volume * 0.35;
        masterGain.connect(ctx.destination);
        var sourceNode = null;
        var intervalId = null;

        if ('$type' === 'zen') {
          var osc1 = ctx.createOscillator();
          var osc2 = ctx.createOscillator();
          osc1.type = 'sine';
          osc1.frequency.value = 136.1;
          osc2.type = 'sine';
          osc2.frequency.value = 272.2;
          var g = ctx.createGain();
          g.gain.value = 0.2;
          osc1.connect(g);
          osc2.connect(g);
          g.connect(masterGain);
          osc1.start(0);
          osc2.start(0);
          sourceNode = { stop: function() { osc1.stop(); osc2.stop(); } };
        } else if ('$type' === 'ocean') {
          var bufferSize = ctx.sampleRate * 3;
          var noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
          var out = noiseBuffer.getChannelData(0);
          var lastOut = 0.0;
          for (var i = 0; i < bufferSize; i++) {
            var white = Math.random() * 2 - 1;
            out[i] = (lastOut + (0.02 * white)) / 1.02;
            lastOut = out[i];
            out[i] *= 1.2;
          }
          var whiteNoise = ctx.createBufferSource();
          whiteNoise.buffer = noiseBuffer;
          whiteNoise.loop = true;
          var filter = ctx.createBiquadFilter();
          filter.type = 'lowpass';
          filter.frequency.value = 350;
          var waveGain = ctx.createGain();
          waveGain.gain.value = 0.25;
          whiteNoise.connect(filter);
          filter.connect(waveGain);
          waveGain.connect(masterGain);
          whiteNoise.start(0);
          var phase = 0;
          intervalId = setInterval(function() {
            phase += 0.04;
            var swell = (Math.sin(phase) + 1.0) / 2.0;
            waveGain.gain.value = 0.1 + (swell * 0.5);
            filter.frequency.value = 200 + (swell * 300);
          }, 50);
          sourceNode = whiteNoise;
        } else if ('$type' === 'forest') {
          var bufferSize = ctx.sampleRate * 2;
          var noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
          var out = noiseBuffer.getChannelData(0);
          for (var i = 0; i < bufferSize; i++) {
            out[i] = (Math.random() * 2 - 1) * 0.04;
          }
          var noise = ctx.createBufferSource();
          noise.buffer = noiseBuffer;
          noise.loop = true;
          var filter = ctx.createBiquadFilter();
          filter.type = 'bandpass';
          filter.frequency.value = 550;
          filter.Q.value = 1.8;
          noise.connect(filter);
          filter.connect(masterGain);
          noise.start(0);
          sourceNode = noise;
        } else {
          // Rain
          var bufferSize = ctx.sampleRate * 2;
          var noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
          var out = noiseBuffer.getChannelData(0);
          var b0 = 0, b1 = 0, b2 = 0;
          for (var i = 0; i < bufferSize; i++) {
            var white = Math.random() * 2 - 1;
            b0 = 0.99886 * b0 + white * 0.0555179;
            b1 = 0.99332 * b1 + white * 0.0750759;
            b2 = 0.96900 * b2 + white * 0.1538520;
            out[i] = (b0 + b1 + b2) * 0.07;
          }
          var whiteNoise = ctx.createBufferSource();
          whiteNoise.buffer = noiseBuffer;
          whiteNoise.loop = true;
          var filter = ctx.createBiquadFilter();
          filter.type = 'lowpass';
          filter.frequency.value = 800;
          whiteNoise.connect(filter);
          filter.connect(masterGain);
          whiteNoise.start(0);
          sourceNode = whiteNoise;
        }

        window._kausapAudio = {
          masterGain: masterGain,
          sourceNode: sourceNode,
          intervalId: intervalId,
          stop: function() {
            if (this.intervalId) clearInterval(this.intervalId);
            try {
              if (this.sourceNode && this.sourceNode.stop) this.sourceNode.stop();
            } catch(e) {}
            try {
              if (this.masterGain && this.masterGain.disconnect) this.masterGain.disconnect();
            } catch(e) {}
            window._kausapAudio = null;
          },
          setVolume: function(v) {
            if (this.masterGain && this.masterGain.gain) {
              this.masterGain.gain.value = v * 0.35;
            }
          }
        };
      })();
    """]);
  } catch (_) {}
}

void stopAmbientSound() {
  try {
    js.context.callMethod('eval', ["""
      if (window._kausapAudio) {
        window._kausapAudio.stop();
      }
    """]);
  } catch (_) {}
}

void setAmbientVolume(double volume) {
  try {
    js.context.callMethod('eval', ["""
      if (window._kausapAudio) {
        window._kausapAudio.setVolume($volume);
      }
    """]);
  } catch (_) {}
}
