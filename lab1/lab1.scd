// === Create a sine wave ===
(
SynthDef(\firstSynth, {
	var osc = SinOsc.ar(freq: 440, phase: pi/3, mul: 1, add: 0.0);
	Out.ar(0, [osc, osc]);
	// Alternativt
	// Out.ar(0, {osc}!2);
}).play;
)


(
s.scope;FreqScope.new(400, 200, 0, server: s);
FreqScope(400, 200, 0, server: s);
)


// === Create other waveforms
(
SynthDef(\secondSynth, {
	var freq = 220;
	var osc1 = LFTri.ar(freq);
	var osc2 = LFSaw.ar(freq);
	var osc3 = LFPulse.ar(freq, 0, 1.0);
	var osc4 = LFPulse.ar(freq, 0, 0.5);
	Out.ar(0, [osc3, osc3]);
}).play;
)


// === Create multiple simultaneous sounds ===
(
SynthDef(\firstSynthCopy, {
	var freq = 220;
	var detune = 1;

	var osc1 = SinOsc.ar(440 + detune, 0, 0.5, 0.0);
	var osc2 = SinOsc.ar(440 - detune, 0, 0.5, 0.0);
	Out.ar(0, {osc1 + osc2}!2);
}).play;
)


// === Modulating the frequency ===
(
SynthDef(\anotherSynth, {
	var osc1 = LFPulse.kr(1, 0, 0.5).range(-10, 10);
	var osc2 = SinOsc.ar(329.63 + osc1, 0, 1, 0.0);
	Out.ar(0, {osc2}!2);
}).play;
)


// === Modulating the amplitude ===
(
SynthDef(\tremoloSynth, {
	// var osc1 = LFPulse.kr(1, 0, 0.5).range(0, 1);
	var osc1 = SinOsc.kr(1).range(0.8, 1);
	var osc2 = SinOsc.ar(329.63, 0, 1, 0.0) * osc1;
	Out.ar(0, {osc2}!2);
}).play;
)


// === Pulse width modulation ===
(
SynthDef(\pwmSynth, {
	var pwm = SinOsc.kr(0.5).range(0.2, 0.8);
	var osc = LFPulse.ar(440, 0, pwm);
	Out.ar(0, {osc}!2);
}).play;
)


// === Ring modulation ===
(
SynthDef(\ringModSynth, {
	// var osc1 = LFPulse.kr(1, 0, 0.5).range(0, 1);
	var freq = 220;
	var osc1 = SinOsc.ar(freq).range(-1, 1);
	var osc2 = SinOsc.ar(freq * 8, 0, 1, 0.0);
	Out.ar(0, {osc1 * osc2}!2);
}).play;
)


// === Simple FM Synthesis ===
(
SynthDef(\FMSynth, {
	// var osc1 = LFPulse.kr(1, 0, 0.5).range(0, 1);
	var freq = 329.63;
	var osc1 = SinOsc.ar(freq).range(0, 2);
	var osc2 = SinOsc.ar(freq * 1 * osc1, 0, 1, 0.0);
	Out.ar(0, {osc2}!2);
}).play;
)


// === Distortion ===
(
SynthDef(\distortionSynth, {
	var osc1 = SinOsc.ar(329.63);
	var clip = osc1.clip(-0.5, 0.5);
	var softClip = osc1.softclip(-0.5, 0.5);
	Out.ar(0, [clip, softClip]);
	// Out.ar(0, {osc1}!2);
}).play;
)


// === Controlling a synthdef from client ===
(
var notes = [57, 60, 64, 69];

SynthDef(\distortionSynth2, { arg inputFrequency = 220;
	var osc1 = SinOsc.ar(inputFrequency);
	var clip = osc1.clip(-0.5, 0.5);
	var softClip = osc1.softclip(-0.5, 0.5);
	Out.ar(0, [clip, softClip]);
	// Out.ar(0, {osc1}!2);
}).add;

~mySynth = Synth.new(\distortionSynth2).register;
//~mySynth.set(\inputFrequency, 440);

fork({
	loop({
		for (0, notes.size-1, { arg index;
			~mySynth.set(\inputFrequency, notes[index].midicps);
			0.3.wait;
		});
	});
});
)


// === Example from lecture 1 ===
(
fork{
	loop{
		h=([33,38,40].choose.midicps)*(2**((0 .. 4).choose));
		play{
			Splay.ar({SinOsc.ar(exprand(h-(h/64),h+(h/64)),0,0.1)}!8)*LFGauss.ar(10,1/4,0,0,2);
		};
		1.wait;
	}
};
)