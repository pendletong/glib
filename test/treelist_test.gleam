import gleam/int
import gleam/iterator
import gleam/list
import gleam/result
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

  let list =
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

  list
  |> treelist.get(3)
  |> should.be_ok
  |> should.equal("Four")

  list
  |> treelist.size
  |> should.equal(5)
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

pub fn mass_test() {
  let new_list =
    iterator.range(1, 100_000)
    |> iterator.try_fold(treelist.new(), fn(acc, i) {
      treelist.insert(acc, 0, i)
    })
    |> should.be_ok
  new_list |> treelist.size |> should.equal(100_000)

  iterator.range(1, 100_000)
  |> iterator.each(fn(i) {
    treelist.get(new_list, i - 1) |> should.be_ok |> should.equal(100_001 - i)
  })

  let new_list =
    iterator.range(1, 100_000)
    |> iterator.try_fold(treelist.new(), fn(acc, i) { treelist.add(acc, i) })
    |> should.be_ok
  new_list |> treelist.size |> should.equal(100_000)

  iterator.range(1, 100_000)
  |> iterator.each(fn(i) {
    treelist.get(new_list, i - 1) |> should.be_ok |> should.equal(i)
  })

  // found a binary tree stress test so try that here
  let power = 16
  let tlist =
    iterator.range(power - 1, 0)
    |> iterator.fold(
      treelist.new() |> treelist.add(0) |> result.unwrap(treelist.new()),
      fn(acc, i) {
        let #(list, _j, _k) =
          iterator.repeat(i)
          |> iterator.fold_until(
            #(acc, int.bitwise_shift_left(1, i), 1),
            fn(acc2, i) {
              let #(list, j, k) = acc2
              let new_list = case treelist.insert(list, k, j) {
                Ok(n) -> n
                Error(_) -> {
                  treelist.new()
                }
                // should throw an error soon thereafter
              }
              let j = j + int.bitwise_shift_left(2, i)
              let k = k + 2
              let ret = #(new_list, j, k)
              case j < int.bitwise_shift_left(1, power) {
                True -> list.Continue(ret)
                False -> list.Stop(ret)
              }
              // panic
            },
          )
        list
      },
    )

  list.range(0, 63)
  |> list.each(fn(i) {
    treelist.get(tlist, i)
    |> should.be_ok
    |> should.equal(i)
  })
}

pub fn repeat_test() {
  treelist.repeat(999, 5)
  |> should.be_ok
  |> treelist.to_list
  |> should.equal([999, 999, 999, 999, 999])
}

pub fn to_iterator_test() {
  let l = list.range(0, 99)
  l
  |> treelist.from_list
  |> should.be_ok
  |> treelist.to_iterator
  |> iterator.to_list
  |> should.equal(l)
}
