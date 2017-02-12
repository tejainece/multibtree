part of btree.base;

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