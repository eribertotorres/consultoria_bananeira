# Roadmap de Produto — Clayton | Projeto OS

**Documento:** planejamento de evolução do produto  
**Versão do documento:** 1.0 (30/10/2026)  
**Versão de referência do aplicativo:** Clayton v1.0.0  
**Responsável pelo produto:** Eriberto Torres de Oliveira  
**Apoio técnico e documentação:** Órion — ChatGPT (OpenAI)  
**Status:** propostas para avaliação, **não implementadas na v1.0.0**

## 1. Objetivo

Registrar, de maneira institucional e rastreável, possibilidades de evolução do Clayton após a entrega acadêmica. Este documento não constitui promessa de implementação, especificação fechada nem cronograma aprovado. Cada proposta dependerá de refinamento, priorização, avaliação técnica e testes.

## 2. Diretrizes de evolução

- Preservar os fluxos já homologados de autenticação, atendimento offline, armazenamento local, sincronização e histórico.
- Manter clara a distinção entre **dados verificados**, **previsões**, **recomendações** e **procedimentos definidos pela empresa**.
- Projetar funcionalidades resilientes à falta de conexão e respeitosas à privacidade.
- Desenvolver novos recursos em branches próprias, com testes e critérios de aceite antes de qualquer release.
- Evitar alterações na versão de entrega acadêmica (v1.0.0) em função deste roadmap.

## 3. Evoluções propostas

### PATCH 01 — Homenagens dinâmicas por API

**Estado:** ideia registrada / descoberta futura  
**Objetivo:** permitir homenagens opcionais no aplicativo, gerenciadas remotamente, sem necessidade de publicar uma nova versão a cada conteúdo.

**Escopo preliminar**
- Consultar uma API própria, via HTTPS, após a validação da sessão e antes da Home.
- Mostrar uma tela de homenagem **somente quando** existir conteúdo ativo.
- Permitir prosseguir imediatamente; na ausência de homenagem, falha de conexão ou timeout, seguir para a Home sem bloqueio.
- Definir título, texto, imagem, identificação e prazo de exibição por configuração remota.
- Avaliar registro local das homenagens já visualizadas, além de direitos de uso das imagens e textos.

**Critérios de aceite iniciais:** não interferir no login ou na navegação; fallback seguro; conteúdo opcional; não executar código remoto.

### PATCH 02 — LiliTips contextual e clima no destino da OS

**Estado:** ideia registrada / descoberta futura  
**Objetivo:** transformar previsão do tempo e dicas em orientações práticas para a preparação do técnico, considerando o **destino**, o **horário previsto** e o **tipo de serviço**.

**Cenário de referência:** o técnico parte de Antônio Carlos com sol para executar uma OS em Florianópolis com chuva prevista. O aplicativo precisa destacar a condição meteorológica no destino, não apenas na posição atual do técnico.

**Escopo preliminar**
- Consultar a previsão meteorológica do local da OS, com indicação do período de referência e fonte.
- Destacar chuva intensa e outros riscos relevantes de forma perceptível e acessível, sem alarmismo.
- Combinar tipo de serviço, previsão do destino e **regras cadastradas pela empresa** para compor dicas de preparação.
- Exemplo **ilustrativo**: “Há previsão de chuva forte no destino. Confira os equipamentos de proteção e o kit de ferramentas previsto pela sua empresa para instalação de fibra.”
- Em modo offline, apresentar apenas dados meteorológicos em cache com sua data de atualização; nunca representar dados antigos como atuais.

**Critérios de aceite iniciais:** localização e janela da previsão corretas; distinção entre recomendações e regras obrigatórias da empresa; privacidade dos dados do cliente; comportamento claro sem internet ou sem cadastro de regras.

### PATCH 03 — Checklist operacional por tipo de serviço

**Estado:** nova ideia registrada / levantamento de requisitos pendente  
**Objetivo:** converter as recomendações do LiliTips em uma **lista de verificação operacional**, vinculada ao tipo de OS e aos procedimentos de cada empresa.

**Escopo preliminar**
- A empresa configura modelos de checklist por serviço (por exemplo: instalação de fibra, manutenção, substituição de equipamento).
- O técnico visualiza, antes de sair, itens de preparação como ferramentas, equipamentos, materiais e EPIs definidos pelo empregador.
- O checklist pode incorporar alertas contextuais do PATCH 02, sem substituir o procedimento oficial ou as avaliações de segurança da empresa.
- Avaliar etapas **pré-deslocamento**, **execução** e **encerramento**, com registro de itens concluídos.
- Estudar persistência offline e sincronização posterior das marcações, além de versionamento dos modelos para preservar o histórico.

**Questões para refinamento:** quem cadastra e aprova os itens? Quais são obrigatórios? O que ocorre se faltar material? A conclusão do checklist deve bloquear uma OS ou apenas alertar? Como tratar itens “não se aplica”? Quem pode auditar alterações?

**Critérios de aceite iniciais:** lista correspondente à categoria da OS e à empresa; marcações utilizáveis offline; rastreabilidade; ausência de itens inventados pelo aplicativo.

### PATCH 04 — Encerramento seguro de sessão (logout)

**Estado:** ideia registrada / pós-entrega  
**Objetivo:** oferecer comando explícito de saída, limpar o token de autenticação e retornar à tela de login sem eliminar inadvertidamente registros de atendimento offline.

**Questões para refinamento:** o que fazer com registros pendentes vinculados à conta? Como proteger dados locais compartilhados entre usuários? Como tratar saída sem internet?

### PATCH 05 — Identidade visual dinâmica na tela de login

**Estado:** ideia registrada / pós-entrega  
**Objetivo:** destacar o nome Projeto OS, aprimorar o ícone da autenticação e, opcionalmente, carregar uma imagem institucional da futura API de homenagens, preservando um visual local padrão quando offline.

**Critérios iniciais:** login sempre funcional sem API; conteúdo remoto não deve executar scripts nem bloquear a autenticação.

## 4. Relação entre os patches

- O **PATCH 01** é independente: conteúdo institucional dinâmico.
- O **PATCH 02** fornece contexto de clima e recomendações orientadas ao serviço.
- O **PATCH 03** transforma regras operacionais em verificações práticas e pode aproveitar o contexto do PATCH 02.

> Sugestão de implementação: tratar cada patch como incremento independente e sujeito à aprovação, sem acoplar o PATCH 01 ao fluxo técnico das OS.

## 5. Backlog relacionado — Projeto Revolution / ERP Bananeiro

Existe a proposta de estudar uma aplicação do mesmo princípio de **dados contextuais + regras operacionais + checklist** às atividades agrícolas e logísticas do ERP Bananeiro. Trata-se de um projeto distinto, com regras próprias, e exigirá levantamento específico antes de qualquer adaptação.

## 6. Governança e próximos passos

1. Encerrar e entregar a v1.0.0 conforme o escopo acadêmico.
2. Refinar os requisitos com cenários, riscos, critérios de aceite e estimativas.
3. Priorizar o backlog e selecionar o próximo incremento.
4. Desenvolver e testar em branch própria, sem alterar retroativamente o release acadêmico.
5. Atualizar este documento quando houver decisão de escopo, implementação ou publicação.

## 7. Histórico do documento

| Data | Alteração | Estado |
|---|---|---|
| 30/10/2026 | Registro dos patches 01 a 05 e da oportunidade relacionada ao ERP Bananeiro | Proposto |

---

**Nota de transparência:** todas as funcionalidades descritas neste roadmap são **planejadas ou propostas**; não devem ser apresentadas como implementadas no Clayton v1.0.0.
