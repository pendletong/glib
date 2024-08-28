import gleam/iterator
import gleam/list
import gleeunit/should
import glib/treelist

pub fn new_test() {
  treelist.new()
  |> treelist.size
  |> should.equal(0)
}

pub fn add_test() {
  treelist.new()
  |> treelist.add("New")
  |> should.be_ok
  |> treelist.get(0)
  |> should.be_ok
  |> should.equal("New")

  treelist.new()
  |> treelist.add("New")
  |> should.be_ok
  |> treelist.add("Two")
  |> should.be_ok
  |> treelist.get(1)
  |> should.be_ok
  |> should.equal("Two")

  treelist.new()
  |> treelist.add("New")
  |> should.be_ok
  |> treelist.add("Two")
  |> should.be_ok
  |> treelist.add("Three")
  |> should.be_ok
  |> treelist.add("Four")
  |> should.be_ok
  |> treelist.add("Five")
  |> should.be_ok
  |> treelist.get(3)
  |> should.be_ok
  |> should.equal("Four")
}

pub fn insert_test() {
  treelist.new()
  |> treelist.insert(0, "New")
  |> should.be_ok
  |> treelist.get(0)
  |> should.be_ok
  |> should.equal("New")

  treelist.new()
  |> treelist.insert(1, "New")
  |> should.be_error

  treelist.new()
  |> treelist.insert(0, "New")
  |> should.be_ok
  |> treelist.insert(1, "Two")
  |> should.be_ok
  |> treelist.get(1)
  |> should.be_ok
  |> should.equal("Two")

  treelist.new()
  |> treelist.insert(0, "New")
  |> should.be_ok
  |> treelist.insert(0, "Two")
  |> should.be_ok
  |> treelist.get(1)
  |> should.be_ok
  |> should.equal("New")

  treelist.new()
  |> treelist.insert(0, "New")
  |> should.be_ok
  |> treelist.insert(0, "Two")
  |> should.be_ok
  |> treelist.insert(3, "Three")
  |> should.be_error

  iterator.from_list(["One", "Two", "Three", "Four", "Five"])
  |> iterator.fold(treelist.new(), fn(l, val) {
    treelist.insert(l, 0, val)
    |> should.be_ok
  })
  |> treelist.size
  |> should.equal(5)
}

pub fn to_list_test() {
  iterator.from_list(["One", "Two", "Three", "Four", "Five"])
  |> iterator.fold(treelist.new(), fn(l, val) {
    treelist.insert(l, treelist.size(l), val)
    |> should.be_ok
  })
  |> treelist.to_list
  |> should.equal(["One", "Two", "Three", "Four", "Five"])
}

pub fn large_list_test() {
  let list =
    iterator.range(0, 499)
    |> iterator.fold(treelist.new(), fn(l, val) {
      treelist.insert(l, treelist.size(l), val)
      |> should.be_ok
    })
  list
  |> treelist.size()
  |> should.equal(500)
  list |> treelist.get(200) |> should.be_ok |> should.equal(200)
}

pub fn from_list_test() {
  treelist.from_list(list.range(0, 100))
  |> should.be_ok
  |> treelist.get(50)
  |> should.be_ok
  |> should.equal(50)

  let l = ["a", "b", "c", "d", "e"]
  treelist.from_list(l)
  |> should.be_ok
  |> treelist.to_list
  |> should.equal(l)
}

pub fn remove_test() {
  let list =
    treelist.from_list(list.range(0, 99))
    |> should.be_ok

  list
  |> treelist.get(50)
  |> should.be_ok
  |> should.equal(50)

  let #(removed, list2) =
    treelist.remove(list, 50)
    |> should.be_ok
  removed |> should.equal(50)
  list2
  |> treelist.get(50)
  |> should.be_ok
  |> should.equal(51)
}
