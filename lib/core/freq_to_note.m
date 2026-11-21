function [name, cents, midi] = freq_to_note(f, a4)
  ## FREQ_TO_NOTE  Frequência -> nome da nota mais próxima e desvio em cents.
  ##
  ##   [name, cents] = freq_to_note(110)   % 'A2', 0
  ## (Um afinador cromático faz exatamente isso.)
  if nargin < 2, a4 = 440; end
  names = {'C','C#','D','D#','E','F','F#','G','G#','A','A#','B'};
  midi_f = 69 + 12*log2(f / a4);
  midi   = round(midi_f);
  cents  = 100 * (midi_f - midi);
  name   = sprintf('%s%d', names{mod(midi, 12) + 1}, floor(midi/12) - 1);
end
