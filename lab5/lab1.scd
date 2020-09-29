(
var devices = ServerOptions.devices;
for (0, devices.size-1, { arg index;
	devices[index].postln;
});
)

(
ServerOptions.inDevices.postln;
)

(
s.options.sampleRate = 44100;
s.options.inDevice = "ASIO : Focusrite USB ASIO";
s.options.outDevice = "ASIO : Focusrite USB ASIO";
s.meter;
)


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
s.scope;
FreqScope.new(400, 200, 0, server: s);
FreqScope(400, 200, 0, server: s);
)


(
SynthDef(\noiseSynth, {
	Out.ar(0,{GrayNoise.ar()}!2);
}).play;
)


(
//var notes = [57, 60, 64, 69];

var notes = [
	57, 60, 64, 69,
	57, 60, 64, 69,
	57, 60, 64, 69,
	57, 60, 64, 69,

	57, 62, 65, 69,
	57, 62, 65, 69,
	57, 62, 65, 69,
	57, 62, 65, 69,
];

SynthDef(\amaaazingSynth, { arg inputFrequency = 220, gate, bufnum;
	var env = Env.adsr(0.01, 0.3, 0.7, 1.0, 1, -2.0);
	var noise = PinkNoise.ar();
	var osc1 = Saw.ar(inputFrequency - 0.7);
	var osc2 = Saw.ar(inputFrequency + 0.7);
	var subOsc = LFTri.ar(inputFrequency / 2);
	var lfo = SinOsc.ar(0.1).range(300, 6000);

	// Varfööör kan inte supercollider multiplicera först som aaaallt annat
	var mix = (0.3 * osc1) + (0.3 * osc2) + (0.45 * subOsc) + (0.15 * noise);
	//var mix = SoundIn.ar(bus: 1);
	//var mix = PlayBuf.ar(2, bufnum);

	// Självsvängning
	//var filteredMix = BLowPass4.ar(mix * 0.01, inputFrequency, 0.01);

	//var filteredMix = BLowPass4.ar(mix, 400, 0.2);
	//var filteredMix = BBandStop.ar(mix, freq: lfo, bw: 1);
	//var filteredMix = BPF.ar(mix, freq: lfo, rq: 0.1);
	var filteredMix = RLPF.ar(mix, freq: lfo, rq: 0.7);
	//var filteredMix = LPF.ar(mix, freq: lfo);
	//var filteredMix = HPF.ar(mix, freq: 500.0);

	var envMix = EnvGen.kr(env, gate) * filteredMix;

	var wetMix = AllpassC.ar(envMix, maxdelaytime: 0.2, delaytime: 0.2, decaytime: 0.40, mul: 1.0, add: 0.0);
	//var wetMix = AllpassC.ar(envMix, maxdelaytime: 0.2, delaytime: Rand.new(lo: 0.0, hi: 0.2), decaytime: 6, mul: 1.0, add: 0.0);
	//var wetMix = envMix;
	3.do({ wetMix = AllpassC.ar(in: wetMix, maxdelaytime: 0.2, delaytime: { Rand(0.001, 0.06) }.dup, decaytime: 6, mul: 1, add: 0)});

	//env.plot;
	Out.ar(0, 0.7 * {(0.6 * envMix) + (0.4 * wetMix)}!2);
	//Out.ar(0, 0.7 * [envMix, wetMix]);
	//Out.ar(0, 0.7 * {wetMix}!2);
}).add;

~mySynth = Synth.new(\amaaazingSynth).register;
//~mySynth.set(\inputFrequency, 440);

fork({
	/*var soundFileBuffer = Buffer.read(s,"E:/Dropbox/Musikgrejor/hejhej.wav");
	1.0.wait;
	~mySynth.set(\bufnum, soundFileBuffer.bufnum);*/

	loop({
		for (0, notes.size-1, { arg index;
			~mySynth.set(\inputFrequency, notes[index].midicps);
			~mySynth.set(\gate, 1);
			0.15.wait;
			~mySynth.set(\gate, 0);
			0.15.wait;
		});
	});
});
)
