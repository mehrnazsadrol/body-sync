import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_icon.dart';
import '../../widgets/bs_list_row.dart';
import 'data_transfer.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();
    final lastExport = store.lastExport;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              BSSpace.screen, 0, BSSpace.screen, BSSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.dangerSoft,
                        shape: BoxShape.circle,
                      ),
                      child: BSIcon('info', size: 26, color: c.danger),
                    ),
                    const SizedBox(height: BSSpace.s4),
                    Text(
                      'Some days could not be read',
                      style: TextStyle(
                        fontFamily: BSType.font,
                        fontSize: BSType.title,
                        fontWeight: BSType.wBold,
                        height: 1.2,
                        letterSpacing: -.02 * BSType.title,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: BSSpace.s4),
                    const BSM2(
                        'Part of the saved file on this phone is damaged. Everything that could be read opened normally.'),
                    const SizedBox(height: 14),
                    BSRule(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        children: [
                          BSListRow(
                            first: true,
                            title: 'Readable',
                            value: fmtKcal(store.readableDays),
                            valueMeta: 'days',
                          ),
                          BSListRow(
                            title: 'Unreadable',
                            value: fmtKcal(store.unreadableCount),
                            valueMeta: 'items',
                          ),
                          BSListRow(
                            title: 'Last good backup',
                            meta: lastExport != null
                                ? 'Restorable with the button below'
                                : null,
                            value:
                                lastExport != null ? fmtDay(lastExport) : null,
                            valueWidget: lastExport == null
                                ? Text(
                                    'No export on file',
                                    style: TextStyle(
                                      fontFamily: BSType.font,
                                      fontSize: BSType.body,
                                      fontWeight: BSType.wBold,
                                      height: 1.2,
                                      color: c.ink3,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              BSButton(
                'Keep the ${fmtKcal(store.readableDays)} readable days',
                size: BSButtonSize.lg,
                block: true,
                onTap: () => store.resolveKeepReadable(),
              ),
              const SizedBox(height: 10),
              BSButton(
                'Restore an export',
                variant: BSButtonVariant.tint,
                hue: 'pro',
                block: true,
                onTap: () => _restore(context, store),
              ),
              const SizedBox(height: 10),
              BSButton(
                'Start fresh instead',
                variant: BSButtonVariant.quiet,
                block: true,
                labelColor: c.danger,
                onTap: () => _confirmStartFresh(context, store),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14, bottom: 4),
                child: BSM2(
                  'Nothing is written until you choose.',
                  align: TextAlign.center,
                  size: BSType.micro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context, AppStore store) async {
    try {
      final r = await pickAndImport(store);
      if (r == null) return;
      await store.resolveKeepReadable();
      if (context.mounted) showBSToast(context, importSummary(r));
    } on FormatException catch (e) {
      if (context.mounted) showBSToast(context, e.message);
    }
  }

  Future<void> _confirmStartFresh(BuildContext context, AppStore store) async {
    final readable = fmtKcal(store.readableDays);
    final body = store.uid != null
        ? 'Everything is deleted from this phone and your account, including the $readable readable days. There is no undo.'
        : 'Everything on this phone is deleted, including the $readable readable days. There is no undo.';
    await showBSDialog(
      context,
      title: 'Start fresh?',
      body: body,
      actions: [
        Builder(
          builder: (dctx) => BSButton(
            'Erase everything',
            variant: BSButtonVariant.danger,
            block: true,
            onTap: () async {
              await store.eraseAll();
              if (dctx.mounted) Navigator.of(dctx).pop();
            },
          ),
        ),
        Builder(
          builder: (dctx) => BSButton(
            'Cancel',
            variant: BSButtonVariant.quiet,
            block: true,
            onTap: () => Navigator.of(dctx).pop(),
          ),
        ),
      ],
    );
  }
}
