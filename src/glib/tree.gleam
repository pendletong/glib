import gleam/option.{type Option, None, Some}
import gleam/io
import gleam/int
import gleam/list
import gleam/string
import gleam/order.{type Order, Eq, Gt, Lt}

pub opaque type Tree(value) {
  Tree(root: Option(TreeNode(value)), comparator: fn(value, value) -> Order)
}

type TreeNode(value) {
  TreeNode(
    value: value,
    count: Int,
    left: Option(TreeNode(value)),
    right: Option(TreeNode(value)),
  )
}

pub fn to_list(tree: Tree(value)) -> List(value) {
  case tree.root {
    None -> []
    Some(node) -> do_to_list(node)
  }
}

fn do_to_list(tree: TreeNode(value)) -> List(value) {
  list.concat([
    case tree.left {
      None -> []
      Some(node) -> do_to_list(node)
    },
    list.repeat(tree.value, tree.count),
    case tree.right {
      None -> []
      Some(node) -> do_to_list(node)
    },
  ])
}

pub fn add(tree: Tree(value), value: value) -> Tree(value) {
  case tree.root {
    None -> Tree(..tree, root: Some(new_node(value)))
    Some(root) -> {
      Tree(..tree, root: Some(do_add(tree, root, value)))
    }
  }
}

fn do_add(
  tree: Tree(value),
  node: TreeNode(value),
  value: value,
) -> TreeNode(value) {
  case tree.comparator(value, node.value) {
    Eq -> {
      TreeNode(..node, count: node.count + 1)
    }
    Lt -> {
      case node.left {
        None -> TreeNode(..node, left: Some(new_node(value)))
        Some(leftnode) -> {
          TreeNode(..node, left: Some(do_add(tree, leftnode, value)))
        }
      }
    }
    Gt -> {
      case node.right {
        None -> TreeNode(..node, right: Some(new_node(value)))
        Some(rightnode) -> {
          TreeNode(..node, right: Some(do_add(tree, rightnode, value)))
        }
      }
    }
  }
}

pub fn remove(tree: Tree(value), value: value) -> Tree(value) {
  case tree.root {
    None -> tree
    Some(root) -> {
      Tree(..tree, root: do_remove(tree, root, value))
    }
  }
}

fn do_remove(
  tree: Tree(value),
  node: TreeNode(value),
  value: value,
) -> Option(TreeNode(value)) {
  case tree.comparator(value, node.value) {
    Eq -> {
      case node.count > 1 {
        True -> Some(TreeNode(..node, count: node.count - 1))
        False -> {
          case node.left {
            None -> {
              case node.right {
                None -> None
                Some(_rnode) -> node.right
              }
            }
            Some(lnode) -> {
              case node.right {
                None -> node.left
                Some(rnode) -> {
                  Some(move_node(tree, lnode, rnode))
                }
              }
            }
          }
        }
      }
    }
    Lt -> {
      case node.left {
        None -> Some(node)
        Some(leftnode) -> {
          Some(TreeNode(..node, left: do_remove(tree, leftnode, value)))
        }
      }
    }
    Gt -> {
      case node.right {
        None -> Some(node)
        Some(rightnode) -> {
          Some(TreeNode(..node, right: do_remove(tree, rightnode, value)))
        }
      }
    }
  }
}

fn move_node(
  tree: Tree(value),
  root_node: TreeNode(value),
  moved_node: TreeNode(value),
) -> TreeNode(value) {
  case tree.comparator(root_node.value, moved_node.value) {
    Eq -> panic
    Lt -> {
      case root_node.left {
        None -> TreeNode(..root_node, left: Some(moved_node))
        Some(lnode) -> {
          move_node(tree, lnode, moved_node)
        }
      }
    }
    Gt -> {
      case root_node.right {
        None -> TreeNode(..root_node, right: Some(moved_node))
        Some(rnode) -> {
          move_node(tree, rnode, moved_node)
        }
      }
    }
  }
}

fn new_node(value: value) -> TreeNode(value) {
  TreeNode(value, count: 1, left: None, right: None)
}

pub fn main() {
  Tree(None, int.compare)
  |> to_list
  |> string.inspect
  |> io.println

  Tree(None, int.compare)
  |> add(123)
  |> to_list
  |> string.inspect
  |> io.println
}
