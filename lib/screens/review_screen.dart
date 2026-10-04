import 'package:flutter/material.dart';

import '../services/photo_platform.dart';
import '../services/rename_planner.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.platform,
    required this.plans,
    required this.renameInPlace,
    this.outputTreeUri,
  });

  final PhotoPlatform platform;
  final List<RenamePlan> plans;
  final bool renameInPlace;
  final String? outputTreeUri;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<RenamePlan> _plans;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _plans = List<RenamePlan>.from(widget.plans);
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final items = _plans
        .map(
          (plan) => RenameApplyItem(
            uri: plan.uri,
            newName: plan.proposedName,
            selected: plan.selected,
          ),
        )
        .toList();
    final results = await widget.platform.applyRenames(
      items: items,
      outputTreeUri: widget.renameInPlace ? null : widget.outputTreeUri,
    );
    if (!mounted) return;
    setState(() => _applying = false);
    final failures = results.where((r) => r['success'] != true).length;
    if (failures > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failures rename(s) failed. Others may have succeeded.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renames applied.')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review renames'),
        actions: [
          TextButton(
            onPressed: _applying
                ? null
                : () {
                    final allSelected = _plans.every((p) => p.selected);
                    setState(() {
                      for (final plan in _plans) {
                        plan.selected = !allSelected;
                      }
                    });
                  },
            child: const Text('Toggle all'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.renameInPlace
                  ? 'Preview before renaming in place. Uncheck any file to skip.'
                  : 'Preview before copying into the output folder. Originals are removed after a successful copy.',
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return CheckboxListTile(
                  value: plan.selected,
                  onChanged: (value) {
                    setState(() => plan.selected = value ?? false);
                  },
                  title: Text(plan.currentName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('→ ${plan.proposedName}'),
                      Text(plan.reason, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _applying ? null : _apply,
                child: Text(_applying ? 'Applying…' : 'Apply selected renames'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
