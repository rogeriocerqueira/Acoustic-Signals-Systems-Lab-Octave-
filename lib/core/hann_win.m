function w = hann_win(L)
  ## HANN_WIN  Janela de Hann periódica (coluna), sem depender de pacotes.
  ## A versão periódica é a correta para STFT com sobreposição (soma constante).
  w = 0.5 - 0.5*cos(2*pi*(0:L-1)'/L);
end
