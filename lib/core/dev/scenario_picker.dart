import 'package:flutter/material.dart';

import '../network/fake/fake_scenario.dart';
import '../theme/monte_theme.dart';

/// Names shown in the picker.
extension FakeScenarioLabel on FakeScenario {
  String get label => switch (this) {
    FakeScenario.normal => 'Normal',
    FakeScenario.empty => 'Vazio',
    FakeScenario.serverError => 'Erro 500',
    FakeScenario.rateLimited => 'Limite 429',
    FakeScenario.slow => 'Lento (3 s)',
    FakeScenario.offline => 'Sem internet',
    FakeScenario.corruptedData => 'Dado quebrado',
    FakeScenario.wrongPassword => 'Senha errada',
  };
}

extension FakeVolumeLabel on FakeVolume {
  String get label => switch (this) {
    FakeVolume.small => '50',
    FakeVolume.medium => '500',
    FakeVolume.large => '10 mil',
  };
}

/// Dev-only sheet that bends the simulated bank (and the CoinGecko
/// connection) so every screen state can be shown on demand.
///
/// Completes with `true` when something changed, so a signed-in caller can
/// drop the saved statement and load again under the new scenario.
Future<bool> showScenarioPicker(
  BuildContext context,
  FakeBackendSettings settings,
) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ScenarioPickerSheet(settings: settings),
  );
  return changed ?? false;
}

class ScenarioPickerSheet extends StatefulWidget {
  const ScenarioPickerSheet({super.key, required this.settings});

  final FakeBackendSettings settings;

  @override
  State<ScenarioPickerSheet> createState() => _ScenarioPickerSheetState();
}

class _ScenarioPickerSheetState extends State<ScenarioPickerSheet> {
  static const _devColor = Color(0xFF6E3BD1);

  late var _scenario = widget.settings.scenario;
  late var _volume = widget.settings.volume;

  void _apply() {
    final settings = widget.settings;
    final changed =
        _scenario != settings.scenario || _volume != settings.volume;
    settings.scenario = _scenario;
    if (_volume != settings.volume) settings.updateData(volume: _volume);
    Navigator.of(context).pop(changed);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.monte;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _devColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DEV',
                    style: text.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cenário do servidor falso',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Só existe no build de desenvolvimento. Vale pro banco simulado '
              'e pra conexão com a CoinGecko.',
              style: text.bodySmall?.copyWith(color: colors.subtle),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scenario in FakeScenario.values)
                  ChoiceChip(
                    key: Key('dev.scenario.${scenario.name}'),
                    label: Text(scenario.label),
                    selected: scenario == _scenario,
                    onSelected: (_) => setState(() => _scenario = scenario),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Quantidade de transações',
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<FakeVolume>(
                showSelectedIcon: false,
                segments: [
                  for (final volume in FakeVolume.values)
                    ButtonSegment(
                      value: volume,
                      label: Text(
                        volume.label,
                        key: Key('dev.volume.${volume.name}'),
                      ),
                    ),
                ],
                selected: {_volume},
                onSelectionChanged: (picked) =>
                    setState(() => _volume = picked.single),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('dev.apply'),
                onPressed: _apply,
                child: const Text('Aplicar e recarregar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
