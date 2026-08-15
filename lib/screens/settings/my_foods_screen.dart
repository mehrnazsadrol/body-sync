import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_empty.dart';
import '../../widgets/bs_list_row.dart';

class MyFoodsScreen extends StatelessWidget {
  const MyFoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    final store = context.watch<AppStore>();
    final custom = store.foods.customFoods;
    final overrides = store.foods.overrides.values.toList()
      ..sort((a, b) => b.edited.compareTo(a.edited));
    final total = custom.length + overrides.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            BSTitleBar(
              title: 'My foods and overrides',
              sub: total > 0 ? '$total saved' : null,
              icon: 'chevronLeft',
              onIconTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: total == 0
                  ? const Padding(
                      padding: EdgeInsets.only(top: BSSpace.s7),
                      child: BSEmpty(
                        hue: 'pro',
                        icon: 'edit',
                        title: 'Nothing saved yet',
                        body:
                            'Foods you create and nutrition facts you correct both show up here.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          BSSpace.screen, 0, BSSpace.screen, BSSpace.s6),
                      children: [
                        if (custom.isNotEmpty) ...[
                          BSSecHead('MY FOODS', right: '${custom.length}'),
                          for (var i = 0; i < custom.length; i++)
                            BSListRow(
                              first: i == 0,
                              title: custom[i].name,
                              meta: custom[i].portions.first.per,
                              value: fmtKcal(custom[i].portions.first.kcal),
                              valueMeta: 'kcal',
                            ),
                        ],
                        if (overrides.isNotEmpty) ...[
                          BSSecHead('OVERRIDES', right: '${overrides.length}'),
                          for (var i = 0; i < overrides.length; i++)
                            BSListRow(
                              first: i == 0,
                              title:
                                  store.foods.byId(overrides[i].foodId)?.name ??
                                      overrides[i].foodId,
                              meta:
                                  '${overrides[i].portionLabel} · edited ${fmtDay(overrides[i].edited)}',
                              value: fmtKcal(overrides[i].kcal),
                              valueMeta: 'kcal',
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
