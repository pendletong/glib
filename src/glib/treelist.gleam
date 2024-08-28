import gleam/bool
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/result

pub type TreeList(value) {
  TreeList(root: Node(value))
}

pub type Node(value) {
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

pub fn new() -> TreeList(value) {
  TreeList(blank_node())
}

pub fn size(list: TreeList(value)) -> Int {
  list.root.size
}

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

pub fn set(
  list: TreeList(value),
  index: Int,
  value: value,
) -> Result(TreeList(value), Nil) {
  use <- bool.guard(index < 0 || index >= size(list), return: Error(Nil))

  use new_root <- result.try(set_node_at(list.root, index, value))

  Ok(TreeList(new_root))
}

pub fn add(list: TreeList(value), value: value) -> Result(TreeList(value), Nil) {
  insert(list, size(list), value)
}

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

pub fn remove(
  list: TreeList(value),
  index: Int,
) -> Result(#(value, TreeList(value)), Nil) {
  use <- bool.guard(when: index < 0 || index > size(list), return: Error(Nil))

  use value <- result.try(get(list, index))

  use new_root <- result.try(remove_node_at(list.root, index))

  Ok(#(value, TreeList(new_root)))
}

pub fn to_list(list: TreeList(value)) -> Result(List(value), Nil) {
  case size(list) {
    0 -> Ok([])
    n -> {
      iterator.range(n - 1, 0)
      |> iterator.try_fold([], fn(acc, i) {
        use el <- result.try(get(list, i))
        Ok([el, ..acc])
      })
    }
  }
}

pub fn from_list(list: List(value)) -> Result(TreeList(value), Nil) {
  list.try_fold(list, new(), fn(acc, val) { add(acc, val) })
}

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
