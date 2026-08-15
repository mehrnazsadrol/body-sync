import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_store.dart';
import '../../util/format.dart';

Future<void> shareExport(AppStore store) async {
  final result = await Share.shareXFiles(
    [
      XFile.fromData(
        utf8.encode(store.exportJson()),
        mimeType: 'application/json',
      ),
    ],
    fileNameOverrides: ['bodysync-export.json'],
  );
  if (result.status != ShareResultStatus.dismissed) {
    await store.recordExport();
  }
}

Future<({int days, int entries, int snapshots, int foods})?> pickAndImport(
    AppStore store) async {
  const group = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    uniformTypeIdentifiers: ['public.json'],
  );
  final file = await openFile(acceptedTypeGroups: [group]);
  if (file == null) return null;
  final raw = await file.readAsString();
  return store.importJson(raw);
}

String importSummary(({int days, int entries, int snapshots, int foods}) r) {
  final parts = <String>[
    if (r.days > 0) '${fmtKcal(r.days)} days',
    if (r.entries > 0) '${fmtKcal(r.entries)} entries',
    if (r.snapshots > 0) '${r.snapshots} check-ins',
    if (r.foods > 0) '${r.foods} foods',
  ];
  return parts.isEmpty
      ? 'Nothing new — everything in that file is already here'
      : 'Restored ${parts.join(' · ')}';
}

String fmtStorage(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).round()} KB';
}
