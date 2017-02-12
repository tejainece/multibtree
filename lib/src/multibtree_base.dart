// Copyright (c) 2017, teja. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library btree.base;

import 'package:quiver_check/check.dart';
import 'package:quiver_collection/collection.dart';
import 'package:tuple/tuple.dart';

part 'children.dart';
part 'items.dart';
part 'node.dart';

typedef bool ItemIterator<T>(T item);

/// Holds a key:values pair
class Pair<KT extends Comparable, VT> {
  Pair(this.key, this.value);

  factory Pair.fromOne(KT key, VT val) =>
      new Pair<KT, VT>(key, new Set<VT>()..add(val));

  KT key;

  Set<VT> value;
}

/// [MultiBTree] is an implementation of a B-Tree that can store multiple values
/// for same key.
///
/// [MultiBTree] stores [Comparable] instances in an ordered structure, allowing
/// easy insertion, removal, and iteration.
class MultiBTree<T extends Comparable, VT> {
  final int _degree;

  int _length = 0;

  _Node<T, VT> _root;

  /// Returns `true` if the tree has no items in it.
  bool get isEmpty => _length == 0;

  /// Returns `true` if the tree has items in it.
  bool get isNotEmpty => _length != 0;

  /// The number of items currently in the tree.
  int get length => _length;

  /// The max number of items to allow per node.
  int get _maxItems => _degree * 2 - 1;

  /// The min number of items to allow per node (ignored for the root node).
  int get _minItems => _degree - 1;

  /// Creates a new B-tree with the given degree.
  ///
  /// `new BTree(2)`, for example, will create a 2-3-4 tree
  /// (each node contains 1-3 items and 2-4 children).
  MultiBTree(this._degree);

  /// Returns `true` if the given key is in the tree.
  bool contains(T key) => this[key] != null;

  /// Adds the given item to the tree. If an item in the tree already equals
  /// the given one, it is removed from the tree and returned.
  ///
  /// Otherwise, `null` is returned.
  ///
  /// Adding `null` to the tree throws an [ArgumentError].
  void insert(T item, VT val) {
    checkNotNull(item);
    if (_root == null) {
      _root = new _Node<T, VT>(this);
      _root.items.addUnpaired(item, val);
      _length++;
    } else if (_root.items.length >= _maxItems) {
      final result = _root.split(_maxItems ~/ 2);
      final item2 = result.item1;
      final second = result.item2;
      final oldRoot = _root;
      _root = new _Node<T, VT>(this)
        ..items.add(item2)
        ..children.addAll([oldRoot, second]);
    }
    bool inserted = _root.insertUnpaired(item, val, _maxItems);
    if (inserted) {
      _length++;
    }
  }

  /// Removes an item equal to the passed in [item] from the tree, returning it.
  /// If no such item exists, returns `null`.
  bool remove(T key, VT val) {
    final Pair<T, VT> found = _root.find(key);
    if(found == null) return false;
    found.value.remove(val);
    return true;
  }

  Set<VT> removeAll(T item) => _removeItem(item);

  Set<VT> _removeItem(T item) {
    if (_root == null || _root.items.isEmpty) {
      return null;
    }
    final out = _root.remove(item, _minItems);
    if (_root.items.isEmpty && _root.children.isNotEmpty) {
      _root = _root.children.first;
    }
    if (out != null) {
      _length--;
    }
    return out?.value;
  }

  /// Looks for the key item in the tree, returning it. It returns `null` if
  /// unable to find that item.
  Set<VT> operator [](T key) {
    if (_root == null) return null;
    return _root[key];
  }

  /// Calls the iterator for every value in the tree within the range
  /// [greaterOrEqual, lessThan), until iterator returns false.
  void ascendRange(T greaterOrEqual, T lessThan, ItemIterator<Pair<T, VT>> iterator) {
    if (_root == null) return;
    _root.iterate((T a) => a.compareTo(greaterOrEqual) >= 0,
            (T a) => a.compareTo(lessThan) < 0, iterator);
  }

  /// Calls the iterator for every value in the tree within the range
  /// [first, pivot), until iterator returns false.
  void ascendLessThan(T pivot, ItemIterator<Pair<T, VT>> iterator) {
    if (_root == null) return;
    _root.iterate((T a) => true, (T a) => a.compareTo(pivot) < 0, iterator);
  }

  /// Calls the iterator for every value in the tree within
  /// the range [pivot, last], until iterator returns false.
  void ascendGreaterOrEqual(T pivot, ItemIterator<Pair<T, VT>> iterator) {
    if (_root == null) return;
    _root.iterate((T a) => a.compareTo(pivot) >= 0, (T a) => true, iterator);
  }

  /// [first, last], until iterator returns false.
  void ascend(ItemIterator<Pair<T, VT>> iterator) {
    if (_root == null) return;
    _root.iterate((T a) => true, (T a) => true, iterator);
  }
}

/// Returns the index of the given [key] in the sorted [list].
/// If no such [key] is found, then returns `-(insertion point + 1)`.
int _binarySearch<KT extends Comparable, VT>(List<Pair<KT, VT>> list, KT key) {
  int min = 0;
  int max = list.length;
  while (min < max) {
    int mid = min + ((max - min) >> 1);
    final Pair<KT, VT> currentItem = list[mid];
    int comp = currentItem.key.compareTo(key);
    if (comp == 0) return mid;
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -(min + 1);
}
