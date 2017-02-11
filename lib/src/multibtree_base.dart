// Copyright (c) 2017, teja. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library btree.base;

import 'package:quiver_check/check.dart';
import 'package:quiver_collection/collection.dart';
import 'package:tuple/tuple.dart';

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

  Set<VT> removeAll() {
    //TODO
  }

  /// Removes an item equal to the passed in [item] from the tree, returning it.
  /// If no such item exists, returns `null`.
  Set<VT> remove(T item) => _removeItem(item);

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

/// [_Node] is an internal node in a tree.
class _Node<KT extends Comparable, VT> {
  final _Items<KT, VT> items = new _Items<KT, VT>();

  final _Children<KT, VT> children = new _Children<KT, VT>();

  final MultiBTree tree;

  _Node(this.tree);

  /// Splits the node at the given index. The current node shrinks,
  /// and this function returns the item that existed at that index and
  /// a new node containing all items/children after it.
  Tuple2<Pair<KT, VT>, _Node<KT, VT>> split(int i) {
    final Pair<KT, VT> item = items[i];
    final _Node<KT, VT> next = new _Node(tree);
    next.items.addAll(items.sublist(i + 1));
    items.length = i;
    if (children.isNotEmpty) {
      next.children.addAll(children.sublist(i + 1));
      children.length = i + 1;
    }
    return new Tuple2<Pair<KT, VT>, _Node<KT, VT>>(item, next);
  }

  /// Checks if a child should be split, and if so splits it.
  /// Returns whether or not a split occurred.
  bool maybeSplitChild(int i, int maxItems) {
    if (children[i].items.length < maxItems) {
      return false;
    }
    final _Node<KT, VT> first = children[i];
    final Tuple2<Pair<KT, VT>, _Node<KT, VT>> splitResult =
    first.split(maxItems ~/ 2);
    final Pair<KT, VT> item = splitResult.item1;
    final _Node<KT, VT> second = splitResult.item2;
    items.insertAt(i, item);
    children.insertAt(i + 1, second);
    return true;
  }

  /// Inserts an [item] into the subtree rooted at this node, making sure no
  /// nodes in the subtree exceed [maxItems] items.
  ///
  /// Should an equivalent item be be found/replaced by insert, it will be
  /// returned.
  bool insertUnpaired(KT item, VT val, int maxItems) {
    final findResult = items.find(item);
    var i = findResult.item1;
    final found = findResult.item2;
    if (found) {
      final out = items[i];
      out.value.add(val);
      return false;
    }
    if (children.isEmpty) {
      items.insertAt(i, new Pair<KT, VT>.fromOne(item, val));
      return true;
    }
    if (maybeSplitChild(i, maxItems)) {
      final inTree = items[i];
      final cmp = item.compareTo(inTree);
      if (cmp < 0) {
        // no change, we want first split node
      } else if (cmp > 0) {
        i++; // we want second split node
      } else {
        final out = items[i];
        out.value.add(val);
        return false;
      }
    }
    return children[i].insertUnpaired(item, val, maxItems);
  }

  // Finds the given key in the subtree and returns it.
  Set<VT> operator [](KT key) {
    final findResult = items.find(key);
    final i = findResult.item1;
    final found = findResult.item2;
    if (found) {
      return items[i].value.toSet();
    } else if (children.isNotEmpty) {
      return children[i][key];
    }
    return null;
  }

  /// Rem n                                     e.
  Pair<KT, VT> remove(KT item, int minItems) {
    var i;
    var found = false;

    final findResult = items.find(item);
    i = findResult.item1;
    found = findResult.item2;
    if (children.isEmpty) {
      if (found) {
        return items.removeAt(i);
      }
      return null;
    }

    // If we get to here, we have children.
    final child = children[i];
    if (child.items.length <= minItems) {
      return growChildAndRemove(i, item, minItems);
    }
    // Either we had enough items to begin with, or we've done some
    // merging/stealing, because we've got enough now and we're ready to return
    // stuff.
    if (found) {
      // The item exists at index 'i', and the child we've selected can give us
      // a predecessor, since if we've gotten here it's got > minItems items in
      // it.
      final out = items[i];
      // We use our special-case 'remove' call with typ=maxItem to pull the
      // predecessor of item i (the rightmost leaf of our immediate left child)
      // and set it into where we pulled the item from.
      items[i] = child.remove(null, minItems);
      return out;
    }
    // Final recursive call. Once we're here, we know that the item isn't in
    // this node and that the child is big enough to remove from.
    return child.remove(item, minItems);
  }

  /// Grows child [i] to make sure it's possible to remove an item from it
  /// while keeping it at [minItems], then calls remove to actually remove it.
  ///
  /// Most documentation says we have to do two sets of special casing:
  ///   1) item is in this node
  ///   2) item is in child
  /// In both cases, we need to handle the two subcases:
  ///   A) node has enough values that it can spare one
  ///   B) node doesn't have enough values
  /// For the latter, we have to check:
  ///   a) left sibling has node to spare
  ///   b) right sibling has node to spare
  ///   c) we must merge
  /// To simplify our code here, we handle cases #1 and #2 the same:
  /// If a node doesn't have enough items, we make sure it does (using a,b,c).
  /// We then simply redo our remove call, and the second time (regardless of
  /// whether we're in case 1 or 2), we'll have enough items and can guarantee
  /// that we hit case A.
  Pair<KT, VT> growChildAndRemove(int i, KT item, int minItems) {
    var child = children[i];
    if (i > 0 && children[i - 1].items.length > minItems) {
      // Steal from left child
      final stealFrom = children[i - 1];
      final stolenItem = stealFrom.items.pop();
      child.items.insertAt(0, items[i - 1]);
      items[i - 1] = stolenItem;
      if (stealFrom.children.isNotEmpty) {
        child.children.insertAt(0, stealFrom.children.pop());
      }
    } else if (i < items.length && children[i + 1].items.length > minItems) {
      // Steal from right child
      final stealFrom = children[i + 1];
      final stolenItem = stealFrom.items.removeAt(0);
      child.items.add(items[i]);
      items[i] = stolenItem;
      if (stealFrom.children.isNotEmpty) {
        child.children.add(stealFrom.children.removeAt(0));
      }
    } else {
      if (i >= items.length) {
        i--;
        child = children[i];
      }
      // Merge with right child
      final mergeItem = items.removeAt(i);
      final mergeChild = children.removeAt(i + 1);
      child.items
        ..add(mergeItem)
        ..addAll(mergeChild.items);
      child.children.addAll(mergeChild.children);
    }
    return remove(item, minItems);
  }

  /// Provides a simple method for iterating over elements in the tree.
  ///
  /// It requires that [from] and [to] both return `true` for values we should
  /// hit with the iterator. It should also be the case that [from] returns
  /// true for values less than or equal to values [to] returns true for,
  /// and [to] returns true for values greater than or equal to those that
  /// [from] does.
  bool iterate(bool from(T), bool to(T), ItemIterator<Pair<KT, VT>> iter) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (!from(item)) {
        continue;
      }
      if (children.isNotEmpty && !children[i].iterate(from, to, iter)) {
        return false;
      }
      if (!to(item)) {
        return false;
      }
      if (!iter(item)) {
        return false;
      }
    }
    if (children.isNotEmpty) {
      return children.last.iterate(from, to, iter);
    }
    return true;
  }
}

class _Items<KT extends Comparable, VT> extends DelegatingList<Pair<KT, VT>> {
  final List<Pair<KT, VT>> _list = new List<Pair<KT, VT>>();

  List<Pair<KT, VT>> get delegate => _list;

  /// Inserts a value into the given [index], pushing all subsequent values
  /// forward.
  void insertAt(int index, Pair<KT, VT> item) => _list.insert(index, item);

  void addUnpaired(KT key, VT val) {
    add(new Pair<KT, VT>.fromOne(key, val));
  }

  /// Removes and returns the last element in the list.
  Pair<KT, VT> pop() => _list.removeLast();

  /// Returns the index of the given [item] in the list.
  Tuple2<int, bool> find(KT item) {
    final i = _binarySearch(_list, item);
    return i >= 0
        ? new Tuple2<int, bool>(i, true)
        : new Tuple2<int, bool>(~i, false);
  }
}

/// Stores child nodes in a node.
class _Children<KT extends Comparable, VT>
    extends DelegatingList<_Node<KT, VT>> {
  final List<_Node<KT, VT>> _list = new List<_Node<KT, VT>>();

  List<_Node<KT, VT>> get delegate => _list;

  /// Inserts a value into the given [index], pushing all subsequent values
  /// forward.
  void insertAt(int index, _Node<KT, VT> node) => _list.insert(index, node);

  /// Removes and returns the last element in the list.
  _Node<KT, VT> pop() => _list.removeLast();
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
