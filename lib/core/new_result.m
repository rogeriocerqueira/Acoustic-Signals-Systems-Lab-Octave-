function res = new_result(id, title, question)
  ## NEW_RESULT  Estrutura padrão devolvida por cada experimento.
  ##   id       ex.: 'ex03'
  ##   title    título curto
  ##   question a pergunta que o experimento responde (vai para o relatório)
  res.id = id; res.title = title; res.question = question;
  res.metrics = cell(0, 3);     % {rótulo, valor formatado, comentário}
  res.figures = {}; res.audio = {}; res.notes = {};
end
