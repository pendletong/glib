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
import gleam/iterator
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

  use value <- result.try(get(list, index))

  use new_root <- result.try(remove_node_at(list.root, index))

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

fn do_to_list(node: Node(value)) -> List(value) {
  let left = option.lazy_unwrap(node.left, fn() { blank_node() })
  let right = option.lazy_unwrap(node.right, fn() { blank_node() })

  list.append(
    case left {
      Node(None, 0, 0, None, None) -> []
      _ -> do_to_list(left)
    },
    [
      case node.value {
        None -> panic
        Some(v) -> v
      },
      ..{
        case right {
          Node(None, 0, 0, None, None) -> []
          _ -> do_to_list(right)
        }
      }
    ],
  )
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

// Internal functions

fn remove_node_at(node: Node(value), index: Int) -> Result(Node(value), Nil) {
  use <- bool.guard(when: index < 0 || index >= node.size, return: Error(Nil))
  let left = option.lazy_unwrap(node.left, fn() { blank_node() })

  use #(res, rebalance) <- result.try(case int.compare(index, left.size) {
    Lt -> {
      use new_left <- result.try(remove_node_at(left, index))
      Ok(#(Node(..node, left: Some(new_left)), True))
    }
    Gt -> {
      let right = option.lazy_unwrap(node.right, fn() { blank_node() })
      use new_right <- result.try(remove_node_at(right, index - left.size - 1))
      Ok(#(Node(..node, right: Some(new_right)), True))
    }
    Eq -> {
      let right = option.lazy_unwrap(node.right, fn() { blank_node() })
      case left, right {
        Node(None, 0, 0, None, None), Node(None, 0, 0, None, None) -> {
          Ok(#(blank_node(), False))
        }
        _, Node(None, 0, 0, None, None) -> {
          Ok(#(left, False))
        }
        Node(None, 0, 0, None, None), _ -> {
          Ok(#(right, False))
        }
        _, _ -> {
          let temp = find_ultimate_left(right)
          use new_right <- result.try(remove_node_at(right, 0))
          Ok(#(Node(..node, right: Some(new_right), value: temp.value), True))
        }
      }
    }
  })
  case rebalance {
    False -> Ok(res)
    True -> {
      case recalculate(res) {
        Error(_) -> Error(Nil)
        Ok(node) -> balance(node)
      }
    }
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

  let left = option.lazy_unwrap(node.left, fn() { blank_node() })
  case int.compare(index, left.size) {
    Lt -> {
      get_node_at(left, index)
    }
    Gt -> {
      let right = option.lazy_unwrap(node.right, fn() { blank_node() })
      get_node_at(right, index - left.size - 1)
    }
    Eq -> Ok(node)
  }
}

fn set_node_at(
  node: Node(value),
  index: Int,
  value: value,
) -> Result(Node(value), Nil) {
  use <- bool.guard(when: index < 0 || index >= node.size, return: Error(Nil))

  let left = option.lazy_unwrap(node.left, fn() { blank_node() })
  case int.compare(index, left.size) {
    Lt -> {
      use new_left <- result.try(set_node_at(left, index, value))

      Ok(Node(..node, left: Some(new_left)))
    }
    Gt -> {
      let right = option.lazy_unwrap(node.right, fn() { blank_node() })
      use new_right <- result.try(set_node_at(
        right,
        index - left.size - 1,
        value,
      ))
      Ok(Node(..node, right: Some(new_right)))
    }
    Eq -> Ok(Node(..node, value: Some(value)))
  }
}

fn insert_node_at(
  node: Node(value),
  index: Int,
  value: value,
) -> Result(Node(value), Nil) {
  use <- bool.guard(when: index < 0 || index > node.size, return: Error(Nil))

  use res <- result.try({
    case node {
      Node(None, 0, 0, None, None) -> Ok(new_node(value))
      _ -> {
        let left = option.lazy_unwrap(node.left, fn() { blank_node() })
        case int.compare(index, left.size) {
          Lt | Eq -> {
            use new_left <- result.try(insert_node_at(left, index, value))
            Ok(Node(..node, left: Some(new_left)))
          }
          Gt -> {
            let right = option.lazy_unwrap(node.right, fn() { blank_node() })
            use new_right <- result.try(insert_node_at(
              right,
              index - left.size - 1,
              value,
            ))
            Ok(Node(..node, right: Some(new_right)))
          }
        }
      }
    }
  })

  case recalculate(res) {
    Error(_) -> Error(Nil)
    Ok(node) -> balance(node)
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

  let left = option.lazy_unwrap(node.left, fn() { blank_node() })
  let right = option.lazy_unwrap(node.right, fn() { blank_node() })
  use <- bool.guard(
    when: left.height < 0 || right.height < 0,
    return: Error(Nil),
  )

  use <- bool.guard(when: left.size < 0 || right.size < 0, return: Error(Nil))

  let new_height = int.max(left.height, right.height) + 1
  let new_size = left.size + right.size + 1

  use <- bool.guard(when: new_height < 0 || new_size < 0, return: Error(Nil))

  Ok(Node(..node, height: new_height, size: new_size))
}

fn balance(node: Node(value)) -> Result(Node(value), Nil) {
  let left = option.lazy_unwrap(node.left, fn() { blank_node() })
  let right = option.lazy_unwrap(node.right, fn() { blank_node() })

  let balance = get_balance(left, right)

  use <- bool.guard(when: int.absolute_value(balance) > 2, return: Error(Nil))

  let result = case balance {
    -2 -> {
      use <- bool.guard(
        when: int.absolute_value(balance_of(left)) > 1,
        return: Error(Nil),
      )

      use node <- result.try(case balance_of(left) {
        1 -> {
          use rotated_left <- result.try(rotate_left(left))
          Ok(Node(..node, left: Some(rotated_left)))
        }
        _ -> Ok(node)
      })
      rotate_right(node)
    }
    2 -> {
      use <- bool.guard(
        when: int.absolute_value(balance_of(right)) > 1,
        return: Error(Nil),
      )

      use node <- result.try(case balance_of(right) {
        -1 -> {
          use rotated_right <- result.try(rotate_right(right))
          Ok(Node(..node, left: Some(rotated_right)))
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
        when: int.absolute_value(
          balance_of(option.lazy_unwrap(r.right, fn() { blank_node() })),
        )
          > 1,
        return: Error(Nil),
      )

      result
    }
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

  let root = option.lazy_unwrap(node.right, fn() { blank_node() })

  use new_node <- result.try(recalculate(Node(..node, right: root.left)))

  recalculate(Node(..root, left: Some(new_node)))
}

fn rotate_right(node: Node(value)) -> Result(Node(value), Nil) {
  use <- bool.guard(
    when: case node.left {
      Some(Node(None, 0, 0, None, None)) -> True
      _ -> False
    },
    return: Error(Nil),
  )

  let root = option.lazy_unwrap(node.left, fn() { blank_node() })

  use new_node <- result.try(recalculate(Node(..node, left: root.right)))

  recalculate(Node(..root, right: Some(new_node)))
}

fn balance_of(node: Node(_)) -> Int {
  let left = option.lazy_unwrap(node.left, fn() { blank_node() })
  let right = option.lazy_unwrap(node.right, fn() { blank_node() })

  get_balance(left, right)
}

fn get_balance(left: Node(_), right: Node(_)) -> Int {
  right.height - left.height
}

fn get_max_int() -> Int {
  999_999
}
