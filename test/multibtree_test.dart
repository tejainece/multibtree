// Copyright (c) 2017, teja. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:multibtree/multibtree.dart';
import 'package:test/test.dart';

void main() {
  group('Test MultiBTree', () {
    setUp(() {});

    test('Insert', () {
      MultiBTree<int, String> tree = new MultiBTree<int, String>(2);
      tree.insert(1, 'one1');
      tree.insert(2, 'two1');
      tree.insert(1, 'one2');
      tree.insert(3, 'three1');
      tree.insert(1, 'one3');
      tree.insert(1, 'one4');

      expect(tree.length, 3);
      expect(tree[1],
          new Set()..add('one1')..add('one2')..add('one3')..add('one4'));
    });

    test('Remove', () {
      MultiBTree<int, String> tree = new MultiBTree<int, String>(2);
      tree.insert(1, 'one1');
      tree.insert(2, 'two1');
      tree.insert(1, 'one2');
      tree.insert(3, 'three1');
      tree.insert(1, 'one3');
      tree.insert(1, 'one4');

      tree.remove(1, 'one3');
      expect(tree.length, 3);
      expect(tree[1],
          new Set()..add('one1')..add('one2')..add('one4'));
    });
  });
}
