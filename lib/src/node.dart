part of btree.base;

/// [_Node] is an internal node in a tree.
class _Node<KT extends Comparable, VT> {
  final _Items<KT, VT> items = new _Items<KT, VT>();

  final _Children<KT, VT> children = new _Children<KT, VT>();

  final MultiBTree tree;

  _Node(this.tree);

  Pair<KT, VT> find(KT key) {
    final Tuple2<int, bool> findResult = items.find(key);
    final int i = findResult.item1;
    final bool found = findResult.item2;
    if (found) {
      return items[i];
    } else if (children.isNotEmpty) {
      return children[i].find(key);
    }
    return null;
  }

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
    final Tuple2<int, bool> findResult = items.find(item);
    int i = findResult.item1;
    bool found = findResult.item2;
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
  Set<VT> operator [](KT key) => find(key)?.value;

  /// Remove
  Pair<KT, VT> remove(KT item, int minItems) {
    final Tuple2<int, bool> findResult = items.find(item);
    int i = findResult.item1;
    bool found = findResult.item2;
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