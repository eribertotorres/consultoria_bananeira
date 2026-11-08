import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/data/models/chamado_model.dart';
import '/data/services/database_service.dart';
import '/data/services/foto_service.dart';

class RegistrarAtendimentoView extends StatefulWidget {
  final ChamadoModel chamado;

  const RegistrarAtendimentoView({super.key, required this.chamado});

  @override
  State<RegistrarAtendimentoView> createState() =>
      _RegistrarAtendimentoViewState();
}

class _RegistrarAtendimentoViewState extends State<RegistrarAtendimentoView> {
  final _formKey = GlobalKey<FormState>();

  final _categoriaController = TextEditingController();
  final _procedimentoController = TextEditingController();
  final FotoService _fotoService = FotoService();
  static const List<String> _categoriasTecnicas = [
    'Falha na fibra óptica',
    'Conector danificado',
    'Problema no roteador',
    'Problema na ONU',
    'Falha de configuração',
    'Problema na rede Wi-Fi',
    'Falha de sinal',
    'Outros',
  ];
  String? _caminhoFoto;
  String? _erroCarregamento;
  String? _statusAtendimento;

  bool _selecionandoFoto = false;
  bool _carregando = true;
  bool _registroExistente = false;
  bool _salvando = false;

  bool get _somenteLeitura =>
      _statusAtendimento == 'verificar' || _statusAtendimento == 'sincronizado';

  @override
  void initState() {
    super.initState();
    _carregarAtendimento();
  }

  // Recupera um atendimento salvo anteriormente no dispositivo.
  Future<void> _carregarAtendimento() async {
    try {
      final registro = await DatabaseService.instance.buscarAtendimentoPendente(
        widget.chamado.id,
      );

      if (!mounted) return;

      if (registro != null) {
        _categoriaController.text = registro['categoria_tecnico'] as String;

        _procedimentoController.text =
            registro['descricao_procedimento'] as String;

        _caminhoFoto = registro['foto_path'] as String?;
      }

      setState(() {
        _registroExistente = registro != null;
        _statusAtendimento = registro?['status'] as String?;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erroCarregamento = 'Não foi possível consultar o atendimento: $e';
        _carregando = false;
      });
    }
  }

  // Seleciona uma fotografia pela câmera ou pela galeria.
  Future<void> _selecionarFoto(ImageSource origem) async {
    if (_somenteLeitura || _selecionandoFoto || _salvando) {
      return;
    }

    setState(() {
      _selecionandoFoto = true;
    });

    try {
      final caminho = await _fotoService.selecionarFoto(
        chamadoId: widget.chamado.id,
        origem: origem,
      );

      if (!mounted || caminho == null) return;

      setState(() {
        _caminhoFoto = caminho;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a foto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _selecionandoFoto = false;
        });
      }
    }
  }

  // Salva o atendimento localmente.
  Future<void> _salvarAtendimento() async {
    if (_carregando ||
        _salvando ||
        _selecionandoFoto ||
        _erroCarregamento != null ||
        _somenteLeitura) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Regra de negócio: fotografia comprobatória obrigatória.
    if (_caminhoFoto == null || _caminhoFoto!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A fotografia comprobatória é obrigatória '
            'para concluir o atendimento.',
          ),
        ),
      );
      return;
    }

    final arquivoFoto = File(_caminhoFoto!);

    if (!await arquivoFoto.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A fotografia não foi encontrada. '
            'Capture ou selecione outra imagem.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      // Confere novamente o status antes de gravar.
      final registroAtual = await DatabaseService.instance
          .buscarAtendimentoPendente(widget.chamado.id);

      final statusAtual = registroAtual?['status'];

      if (statusAtual == 'verificar' || statusAtual == 'sincronizado') {
        if (!mounted) return;

        setState(() {
          _statusAtendimento = statusAtual as String;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este atendimento está em conferência '
              'ou já foi sincronizado.',
            ),
          ),
        );
        return;
      }

      await DatabaseService.instance.salvarAtendimentoPendente(
        chamadoId: widget.chamado.id,
        categoriaTecnico: _categoriaController.text.trim(),
        descricaoProcedimento: _procedimentoController.text.trim(),
        fotoPath: _caminhoFoto,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Atendimento salvo no dispositivo. '
            'Sincronização pendente.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o atendimento: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _categoriaController.dispose();
    _procedimentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Atendimento OS #${widget.chamado.id}')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erroCarregamento != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_erroCarregamento!, textAlign: TextAlign.center),
              ),
            )
          : _construirFormulario(context),
    );
  }

  Widget _construirFormulario(BuildContext context) {
    final categorias = List<String>.from(_categoriasTecnicas);
    final categoriaAnterior = _categoriaController.text.trim();

    if (categoriaAnterior.isNotEmpty &&
        !categorias.contains(categoriaAnterior)) {
      categorias.insert(0, categoriaAnterior);
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dados do chamado.
          Text(
            widget.chamado.nomeCliente,
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Text(
            'Problema informado: '
            '${widget.chamado.descricaoProblema}',
          ),

          const SizedBox(height: 24),

          // Situação do atendimento já cadastrado.
          if (_registroExistente) ...[
            Card(
              child: ListTile(
                leading: Icon(
                  _somenteLeitura ? Icons.lock_outline : Icons.pending_actions,
                ),
                title: Text(
                  _somenteLeitura
                      ? 'Atendimento protegido'
                      : 'Atendimento salvo localmente',
                ),
                subtitle: Text(
                  _statusAtendimento == 'verificar'
                      ? 'Envio com resultado desconhecido. '
                            'Aguarde a conferência com o servidor.'
                      : _statusAtendimento == 'sincronizado'
                      ? 'Atendimento confirmado pelo servidor.'
                      : 'Pendente de sincronização. '
                            'Você pode revisar e editar os dados.',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Categoria técnica.
          DropdownButtonFormField<String>(
            initialValue: categoriaAnterior.isEmpty ? null : categoriaAnterior,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoria identificada pelo técnico',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Selecione a categoria'),
            items: categorias.map((categoria) {
              return DropdownMenuItem<String>(
                value: categoria,
                child: Text(categoria, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: _somenteLeitura
                ? null
                : (valor) {
                    setState(() {
                      _categoriaController.text = valor ?? '';
                    });
                  },
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Selecione uma categoria.';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Procedimento realizado.
          TextFormField(
            controller: _procedimentoController,
            readOnly: _somenteLeitura,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Procedimento realizado',
              hintText: 'Descreva o serviço executado...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().length < 10) {
                return 'O procedimento deve conter pelo menos 10 caracteres.';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Fotografia comprobatória.
          Text(
            'Foto comprobatória *',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Obrigatória para concluir o atendimento.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          if (!_somenteLeitura)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_selecionandoFoto || _salvando)
                        ? null
                        : () => _selecionarFoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Câmera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_selecionandoFoto || _salvando)
                        ? null
                        : () => _selecionarFoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeria'),
                  ),
                ),
              ],
            ),

          if (_selecionandoFoto)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Pré-visualização da imagem.
          if (_caminhoFoto != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_caminhoFoto!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Não foi possível visualizar a imagem.');
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Gravação local.
          if (!_somenteLeitura)
            FilledButton.icon(
              onPressed: (_salvando || _selecionandoFoto)
                  ? null
                  : _salvarAtendimento,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _salvando
                    ? 'Salvando...'
                    : _registroExistente
                    ? 'Atualizar atendimento pendente'
                    : 'Salvar atendimento offline',
              ),
            ),

          if (_somenteLeitura)
            const Text(
              'Este atendimento pode ser consultado, '
              'mas não pode ser alterado neste momento.',
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 12),

          if (!_somenteLeitura)
            const Text(
              'O atendimento será armazenado neste dispositivo '
              'até sua sincronização com o servidor.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
