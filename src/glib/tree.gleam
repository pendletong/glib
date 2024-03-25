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
