// Copyright (c) 2017, teja. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:multibtree/multibtree.dart';

main() {
  MultiBTree<int, String> tree = new MultiBTree<int, String>(2);
  tree.insert(1, 'one1');
  tree.insert(2, 'two1');
  tree.insert(1, 'one2');
  tree.insert(3, 'three1');
  tree.insert(1, 'one3');
  tree.insert(1, 'one4');
  print(tree[1]);
  print(tree[2]);
  print(tree[3]);

  tree.remove(1, 'one3');
  print(tree[1]);
  print(tree[2]);
  print(tree[3]);
}
