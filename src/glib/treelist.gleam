//// TreeLists are ordered sequence of elements stored in an efficient binary
//// tree structure
//// 
//// New elements can be added at any index of the structure and will
//// be stored efficiently with O(log n) complexity
//// 
//// Based on https://en.wikipedia.org/wiki/AVL_tree
//// 

import gleam/bool
import gleam/int
import gleam/iterator.{type Iterator, Done, Next}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/result

pub opaque type TreeList(value) {
  TreeList(root: Node(value))
}

pub opaque type Node(value) {
  Node(
    value: Option(value),
    height: Int,
    size: Int,
    left: Option(Node(value)),
    right: Option(Node(value)),
  )
}

fn blank_node() -> Node(value) {
  Node(None, 0, 0, None, None)
}

fn new_node(value: value) -> Node(value) {
  Node(Some(value), 1, 1, Some(blank_node()), Some(blank_node()))
}

/// Creates an empty treelist
pub fn new() -> TreeList(value) {
  TreeList(blank_node())
}

/// Returns the number of elements in the provided treelist
pub fn size(list: TreeList(value)) -> Int {
  list.root.size
}

/// Returns the element at the specified position in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// 
/// ## Examples
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = add(list, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// ```
/// 
/// ```gleam
/// new() |> get(0)
/// // -> Error(Nil)
/// ```
/// 
pub fn get(list: TreeList(value), index: Int) -> Result(value, Nil) {
  use <- bool.guard(index < 0 || index >= size(list), return: Error(Nil))

  use node <- result.try(
    list.root
    |> get_node_at(index),
  )

  case node.value {
    Some(value) -> Ok(value)
    None -> Error(Nil)
  }
}

/// Updates the element at index specified in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// Returns a new TreeList containing the updated node
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = add(list, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// let assert Ok(new_list) = set(list, 0, "Updated")
/// get(new_list, 0)
/// // -> Ok("Updated")
/// ```
/// 
pub fn set(
  list: TreeList(value),
  index: Int,
  value: value,
) -> Result(TreeList(value), Nil) {
  use <- bool.guard(index < 0 || index >= size(list), return: Error(Nil))

  use new_root <- result.try(set_node_at(list.root, index, value))

  Ok(TreeList(new_root))
}

/// Adds an element to the end of the provided treelist
/// i.e. insert at position size(list)
/// 
/// Returns a new TreeList containing the provided element
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = add(list, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// ```
/// 
pub fn add(list: TreeList(value), value: value) -> Result(TreeList(value), Nil) {
  insert(list, size(list), value)
}

/// Inserts an element at the specified index in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// Returns a new TreeList containing the provided element
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = insert(list, 0, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// ```
/// 
/// ```gleam
/// let list = new()
/// insert(list, 1, "Test")
/// // -> Error(Nil)
/// ```
/// 
pub fn insert(
  list: TreeList(value),
  index: Int,
  value: value,
) -> Result(TreeList(value), Nil) {
  use <- bool.guard(when: index < 0 || index > size(list), return: Error(Nil))
  use <- bool.guard(when: index > get_max_int(), return: Error(Nil))
  use new_root <- result.try(insert_node_at(list.root, index, value))
  Ok(TreeList(new_root))
}

/// Removes an element at the specified index in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// Returns a tuple containing the value at the specified index and the new TreeList
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = insert(list, 0, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// remove(new_list, 0)
/// // -> #("Test", TreeList(..))
/// ```
/// 
/// ```gleam
/// let list = new()
/// remove(list, 1)
/// // -> Error(Nil)
/// ```
/// 
pub fn remove(
  list: TreeList(value),
  index: Int,
) -> Result(#(value, TreeList(value)), Nil) {
  use <- bool.guard(when: index < 0 || index > size(list), return: Error(Nil))

  use #(new_root, value) <- result.try(remove_node_at(list.root, index))

  Ok(#(value, TreeList(new_root)))
}

/// Converts a TreeList into a standard Gleam list
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = insert(list, 0, "Test")
/// let assert Ok(new_list2) = insert(new_list, 1, "Second")
/// to_list(new_list2)
/// // -> ["Test", "Second"]
/// ```
/// 
pub fn to_list(l: TreeList(value)) -> List(value) {
  do_to_list(l.root)
}

/// Takes a list and returns a new TreeList containing all the
/// elements from the list in the same order as that list
/// 
/// Returns an Error(Nil) in the case that the list is too large
/// 
/// ```gleam
/// let list = from_list([1,2,3])
/// get(list, 1)
/// // -> Ok(2)
/// ```
/// 
pub fn from_list(list: List(value)) -> Result(TreeList(value), Nil) {
  list.try_fold(list, new(), fn(acc, val) { add(acc, val) })
}

/// Builds a list of a given value a given number of times.
///
/// ## Examples
///
/// ```gleam
/// repeat("a", times: 0)
/// // -> treelist.new()
/// ```
///
/// ```gleam
/// repeat("a", times: 5)
/// |> to_list
/// // -> ["a", "a", "a", "a", "a"]
/// ```
///
pub fn repeat(item a: a, times times: Int) -> Result(TreeList(a), Nil) {
  do_repeat(a, times, new())
}

/// Creates an iterator that yields each element from the given treelist.
///
///
/// ```gleam
/// to_iterator(treelist.from_list([1, 2, 3, 4]))
/// |> to_list
/// // -> [1, 2, 3, 4]
/// ```
///
pub fn to_iterator(tlist: TreeList(value)) -> Iterator(value) {
  node_iterator(tlist, fn(_node, value, _index) { value })
}

/// Creates an iterator that yields each element from the given treelist.
///
///
/// ```gleam
/// to_iterator_reverse(treelist.from_list([1, 2, 3, 4]))
/// |> to_list
/// // -> [4, 3, 2, 1]
/// ```
///
pub fn to_iterator_reverse(tlist: TreeList(value)) -> Iterator(value) {
  node_iterator_reverse(tlist, fn(_node, value, _index) { value })
}

/// Returns the index of the first occurrence of the specified element
/// in this list, or -1 if this list does not contain the element.
/// 
/// ```gleam
/// index_of(treelist.from_list([1, 2, 3, 4]), 3)
/// // -> 2
/// ```
/// 
/// ```gleam
/// index_of(treelist.from_list([1, 2, 3, 4, 2, 2]), 2)
/// // -> 1
/// ```
/// 
/// ```gleam
/// index_of(treelist.from_list([1, 2, 3, 4]), 999)
/// // -> -1
/// ```
///
pub fn index_of(tlist: TreeList(value), item: value) -> Int {
  do_index_of(
    node_iterator(tlist, fn(_, value, index) { #(value, index) }),
    item,
  )
}

/// Returns the index of the last occurrence of the specified element
/// in this list, or -1 if this list does not contain the element.
/// 
/// ```gleam
/// last_index_of(treelist.from_list([1, 2, 3, 4]), 3)
/// // -> 2
/// ```
/// 
/// ```gleam
/// last_index_of(treelist.from_list([1, 2, 3, 4, 2, 2]), 2)
/// // -> 5
/// ```
/// 
/// ```gleam
/// last_index_of(treelist.from_list([1, 2, 3, 4]), 999)
/// // -> -1
/// ```
///
pub fn last_index_of(tlist: TreeList(value), item: value) -> Int {
  case
    do_index_of(
      node_iterator_reverse(tlist, fn(_, value, index) { #(value, index) }),
      item,
    )
  {
    -1 -> -1
    n -> tlist.root.size - n - 1
  }
}

/// Returns true if this list contains the specified element.
/// 
/// ```gleam
/// contains(treelist.from_list([1, 2, 3, 4]), 3)
/// // -> True
/// ```
/// 
/// ```gleam
/// contains(treelist.from_list([1, 2, 3, 4]), 999)
/// // -> False
/// ```
/// 
pub fn contains(tlist: TreeList(value), item: value) -> Bool {
  index_of(tlist, item) >= 0
}

pub fn filter(
  tlist: TreeList(value),
  filter_fn: fn(value) -> Bool,
) -> Result(TreeList(value), Nil) {
  to_iterator(tlist)
  |> iterator.try_fold(new(), fn(acc, el) {
    case filter_fn(el) {
      True -> add(acc, el)
      False -> Ok(acc)
    }
  })
}

// Internal functions

fn node_iterator(
  tlist: TreeList(value),
  ret_fn: fn(Node(value), value, Int) -> ret_type,
) -> Iterator(ret_type) {
  let stack = #(list.reverse(init_forward_stack(tlist.root, 0)), 0)
  let yield = fn(acc: #(List(Node(value)), Int)) {
    case acc {
      #([Node(Some(value), _, _, _, Some(right)) as node, ..rest], index) -> {
        let rest = list.append(get_left_stack(right, []), rest)
        Next(ret_fn(node, value, index), #(rest, index + 1))
      }
      _ -> Done
    }
  }

  iterator.unfold(stack, yield)
}

fn node_iterator_reverse(
  tlist: TreeList(value),
  ret_fn: fn(Node(value), value, Int) -> ret_type,
) -> Iterator(ret_type) {
  let stack = #(list.reverse(init_backward_stack(tlist.root, 0)), 0)
  let yield = fn(acc: #(List(Node(value)), Int)) {
    case acc {
      #([Node(Some(value), _, _, Some(left), _) as node, ..rest], index) -> {
        let rest = list.append(list.reverse(get_right_stack(left, [])), rest)
        Next(ret_fn(node, value, index), #(rest, index + 1))
      }
      _ -> Done
    }
  }

  iterator.unfold(stack, yield)
}

fn get_left_stack(
  node: Node(value),
  acc: List(Node(value)),
) -> List(Node(value)) {
  case node {
    Node(None, 0, 0, None, None) -> acc
    _ -> {
      case node.left {
        Some(left) -> get_left_stack(left, [node, ..acc])
        _ -> acc
      }
    }
  }
}

fn get_right_stack(
  node: Node(value),
  acc: List(Node(value)),
) -> List(Node(value)) {
  case node {
    Node(None, 0, 0, None, None) -> acc
    _ -> {
      case node.right {
        Some(right) -> get_right_stack(right, [node, ..acc])
        _ -> acc
      }
    }
  }
}

fn init_forward_stack(node: Node(value), index: Int) -> List(Node(value)) {
  case node {
    Node(None, 0, 0, None, None) -> []
    _ -> {
      case node.left {
        Some(left) -> {
          case int.compare(index, left.size) {
            Eq -> {
              [node]
            }
            Lt -> {
              [node, ..init_forward_stack(left, index)]
            }
            Gt -> {
              let index = index - left.size + 1
              case node.right {
                Some(right) -> init_forward_stack(right, index)
                _ -> []
              }
            }
          }
        }
        _ -> []
      }
    }
  }
}

fn init_backward_stack(node: Node(value), index: Int) -> List(Node(value)) {
  case node {
    Node(None, 0, 0, None, None) -> []
    _ -> {
      case node.right {
        Some(right) -> {
          case int.compare(index, right.size) {
            Eq -> {
              [node]
            }
            Lt -> {
              [node, ..init_backward_stack(right, index)]
            }
            Gt -> {
              let index = index - right.size + 1
              case node.left {
                Some(left) -> init_backward_stack(left, index)
                _ -> []
              }
            }
          }
        }
        _ -> []
      }
    }
  }
}

fn do_index_of(it: Iterator(#(value, Int)), item: value) -> Int {
  case
    iterator.find(it, fn(el: #(value, Int)) -> Bool {
      let #(node_val, _index) = el
      node_val == item
    })
  {
    Error(Nil) -> -1
    Ok(#(_, index)) -> index
  }
}

fn do_to_list(node: Node(value)) -> List(value) {
  case node {
    Node(Some(value), _, _, Some(left), Some(right)) -> {
      let left_list = case left {
        Node(None, 0, 0, None, None) -> []
        _ -> do_to_list(left)
      }
      let right_list = case right {
        Node(None, 0, 0, None, None) -> []
        _ -> do_to_list(right)
      }

      list.append(left_list, [value, ..right_list])
    }
    _ -> []
  }
}

fn remove_node_at(
  node: Node(value),
  index: Int,
) -> Result(#(Node(value), value), Nil) {
  use <- bool.guard(when: index < 0 || index >= node.size, return: Error(Nil))

  case node.left, node.right, node.value {
    Some(left), Some(right), Some(node_value) -> {
      use #(res, removed_value, rebalance) <- result.try(case
        int.compare(index, left.size)
      {
        Lt -> {
          use #(new_left, rval) <- result.try(remove_node_at(left, index))
          Ok(#(Node(..node, left: Some(new_left)), rval, True))
        }
        Gt -> {
          use #(new_right, rval) <- result.try(remove_node_at(
            right,
            index - left.size - 1,
          ))
          Ok(#(Node(..node, right: Some(new_right)), rval, True))
        }
        Eq -> {
          case left, right {
            Node(None, 0, 0, None, None), Node(None, 0, 0, None, None) -> {
              Ok(#(blank_node(), node_value, False))
            }
            _, Node(None, 0, 0, None, None) -> {
              Ok(#(left, node_value, False))
            }
            Node(None, 0, 0, None, None), _ -> {
              Ok(#(right, node_value, False))
            }
            _, _ -> {
              let temp = find_ultimate_left(right)
              use #(new_right, _) <- result.try(remove_node_at(right, 0))
              Ok(#(
                Node(..node, right: Some(new_right), value: temp.value),
                node_value,
                True,
              ))
            }
          }
        }
      })
      case rebalance {
        False -> Ok(#(res, removed_value))
        True -> {
          case recalculate(res) {
            Error(_) -> Error(Nil)
            Ok(node) -> {
              use balanced <- result.try(balance(node))
              Ok(#(balanced, removed_value))
            }
          }
        }
      }
    }
    _, _, _ -> Error(Nil)
  }
}

fn find_ultimate_left(node: Node(value)) -> Node(value) {
  case node.left {
    Some(Node(None, 0, 0, None, None)) -> node
    Some(left) -> find_ultimate_left(left)
    None -> panic
  }
}

fn get_node_at(node: Node(value), index: Int) -> Result(Node(value), Nil) {
  use <- bool.guard(when: index < 0 || index >= node.size, return: Error(Nil))

  case node.left {
    Some(left) -> {
      case int.compare(index, left.size) {
        Lt -> {
          get_node_at(left, index)
        }
        Gt -> {
          case node.right {
            Some(right) -> get_node_at(right, index - left.size - 1)
            _ -> Error(Nil)
          }
        }
        Eq -> Ok(node)
      }
    }
    _ -> Error(Nil)
  }
}

fn set_node_at(
  node: Node(value),
  index: Int,
  value: value,
) -> Result(Node(value), Nil) {
  use <- bool.guard(when: index < 0 || index >= node.size, return: Error(Nil))

  case node.left {
    Some(left) -> {
      case int.compare(index, left.size) {
        Lt -> {
          use new_left <- result.try(set_node_at(left, index, value))

          Ok(Node(..node, left: Some(new_left)))
        }
        Gt -> {
          case node.right {
            Some(right) -> {
              use new_right <- result.try(set_node_at(
                right,
                index - left.size - 1,
                value,
              ))
              Ok(Node(..node, right: Some(new_right)))
            }
            _ -> Error(Nil)
          }
        }
        Eq -> Ok(Node(..node, value: Some(value)))
      }
    }
    _ -> Error(Nil)
  }
}

fn insert_node_at(
  node: Node(value),
  index: Int,
  value: value,
) -> Result(Node(value), Nil) {
  use <- bool.guard(when: index < 0 || index > node.size, return: Error(Nil))

  case node {
    Node(None, 0, 0, None, None) -> Ok(new_node(value))
    _ -> {
      case node.left {
        Some(left) -> {
          use res <- result.try(case int.compare(index, left.size) {
            Lt | Eq -> {
              use new_left <- result.try(insert_node_at(left, index, value))
              Ok(Node(..node, left: Some(new_left)))
            }
            Gt -> {
              case node.right {
                Some(right) -> {
                  use new_right <- result.try(insert_node_at(
                    right,
                    index - left.size - 1,
                    value,
                  ))
                  Ok(Node(..node, right: Some(new_right)))
                }
                _ -> Error(Nil)
              }
            }
          })
          case recalculate(res) {
            Error(_) -> Error(Nil)
            Ok(node) -> balance(node)
          }
        }
        _ -> Error(Nil)
      }
    }
  }
}

fn recalculate(node: Node(value)) -> Result(Node(value), Nil) {
  use <- bool.guard(
    when: case node {
      Node(None, 0, 0, None, None) -> True
      _ -> False
    },
    return: Error(Nil),
  )

  case node.left, node.right {
    Some(left), Some(right) -> {
      use <- bool.guard(
        when: left.height < 0 || right.height < 0,
        return: Error(Nil),
      )

      use <- bool.guard(
        when: left.size < 0 || right.size < 0,
        return: Error(Nil),
      )

      let new_height = int.max(left.height, right.height) + 1
      let new_size = left.size + right.size + 1

      use <- bool.guard(
        when: new_height < 0 || new_size < 0,
        return: Error(Nil),
      )

      Ok(Node(..node, height: new_height, size: new_size))
    }
    _, _ -> Error(Nil)
  }
}

fn balance(node: Node(value)) -> Result(Node(value), Nil) {
  case node.left, node.right {
    Some(left), Some(right) -> {
      let balance = get_balance(left, right)
      use <- bool.guard(
        when: int.absolute_value(balance) > 2,
        return: Error(Nil),
      )
      let result = case balance {
        -2 -> {
          let left_balance = balance_of(left)
          use <- bool.guard(
            when: int.absolute_value(left_balance) > 1,
            return: Error(Nil),
          )

          use node <- result.try(case left_balance {
            1 -> {
              use rotated_left <- result.try(rotate_left(left))
              Ok(Node(..node, left: Some(rotated_left)))
            }
            _ -> Ok(node)
          })
          rotate_right(node)
        }
        2 -> {
          let right_balance = balance_of(right)
          use <- bool.guard(
            when: int.absolute_value(right_balance) > 1,
            return: Error(Nil),
          )

          use node <- result.try(case right_balance {
            -1 -> {
              use rotated_right <- result.try(rotate_right(right))
              Ok(Node(..node, right: Some(rotated_right)))
            }
            _ -> Ok(node)
          })
          rotate_left(node)
        }
        _ -> Ok(node)
      }
      case result {
        Error(_) -> Error(Nil)
        Ok(r) -> {
          use <- bool.guard(
            when: int.absolute_value(balance_of(r)) > 1,
            return: Error(Nil),
          )

          result
        }
      }
    }
    _, _ -> Error(Nil)
  }
}

fn rotate_left(node: Node(value)) -> Result(Node(value), Nil) {
  use <- bool.guard(
    when: case node.right {
      Some(Node(None, 0, 0, None, None)) -> True
      _ -> False
    },
    return: Error(Nil),
  )

  case node.right {
    Some(root) -> {
      use new_node <- result.try(recalculate(Node(..node, right: root.left)))

      recalculate(Node(..root, left: Some(new_node)))
    }
    _ -> Error(Nil)
  }
}

fn rotate_right(node: Node(value)) -> Result(Node(value), Nil) {
  use <- bool.guard(
    when: case node.left {
      Some(Node(None, 0, 0, None, None)) -> True
      _ -> False
    },
    return: Error(Nil),
  )

  case node.left {
    Some(root) -> {
      use new_node <- result.try(recalculate(Node(..node, left: root.right)))

      recalculate(Node(..root, right: Some(new_node)))
    }
    _ -> Error(Nil)
  }
}

fn balance_of(node: Node(_)) -> Int {
  case node.left, node.right {
    Some(left), Some(right) -> get_balance(left, right)
    _, _ -> 9999
  }
}

fn get_balance(left: Node(_), right: Node(_)) -> Int {
  right.height - left.height
}

fn get_max_int() -> Int {
  999_999
}

fn do_repeat(a: a, times: Int, acc: TreeList(a)) -> Result(TreeList(a), Nil) {
  case times <= 0 {
    True -> Ok(acc)
    False ->
      case insert(acc, 0, a) {
        Error(_) -> Error(Nil)
        Ok(new_list) -> do_repeat(a, times - 1, new_list)
      }
  }
}
