/* qa_silence.js — init script for the QA browsers (Playwright addInitScript). A QA run must never make sound on
   the user's machine while he works: every media element is forced muted at volume 0 before play(), and every WebAudio
   connection to the real speakers is dropped (OfflineAudioContext, used by renderCue, is left alone so the cue
   peak check still works). window.__qaSilence counts what was silenced, as evidence that the patch was active. */
module.exports = function silence() {
  var stats = window.__qaSilence = { media: 0, connects: 0 };
  try {
    var P = HTMLMediaElement.prototype, play = P.play;
    P.play = function () { stats.media++; this.muted = true; this.volume = 0; return play.apply(this, arguments); };
  } catch (e) { /* engine without HTMLMediaElement: nothing to silence */ }
  try {
    var connect = AudioNode.prototype.connect;
    AudioNode.prototype.connect = function (dest) {
      var off = window.OfflineAudioContext || window.webkitOfflineAudioContext;
      if (typeof AudioDestinationNode !== "undefined" && dest instanceof AudioDestinationNode && !(off && dest.context instanceof off)) {
        stats.connects++;
        return dest;
      }
      return connect.apply(this, arguments);
    };
  } catch (e) { /* no WebAudio: nothing to silence */ }
};
