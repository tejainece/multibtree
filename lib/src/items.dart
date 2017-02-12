part of btree.base;

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