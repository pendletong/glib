import gleam/int
import gleam/iterator
import gleam/list
import gleam/result
import gleeunit/should
import glib/treelist

@target(erlang)
const recursion_test_cycles = 1_000_000

// JavaScript engines crash when exceeding a certain stack size:
//
// - Chrome 106 and NodeJS V16, V18, and V19 crash around 10_000+
// - Firefox 106 crashes around 35_000+.
// - Safari 16 crashes around 40_000+.
@target(javascript)
const recursion_test_cycles = 40_000

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

  ["One", "Two", "Three", "Four", "Five"]
  |> list.fold(treelist.new(), fn(l, val) {
    treelist.insert(l, 0, val)
    |> should.be_ok
  })
  |> treelist.size
  |> should.equal(5)
}

pub fn to_list_test() {
  ["One", "Two", "Three", "Four", "Five"]
  |> list.fold(treelist.new(), fn(l, val) {
    treelist.insert(l, treelist.size(l), val)
    |> should.be_ok
  })
  |> treelist.to_list
  |> should.equal(["One", "Two", "Three", "Four", "Five"])
}

pub fn large_list_test() {
  let l = list.range(0, 499)
  let tl =
    l
    |> list.fold(treelist.new(), fn(l, val) {
      treelist.insert(l, treelist.size(l), val)
      |> should.be_ok
    })
  tl
  |> treelist.size()
  |> should.equal(500)
  tl |> treelist.get(200) |> should.be_ok |> should.equal(200)
  tl |> treelist.to_list |> should.equal(l)
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
  list2 |> treelist.size |> should.equal(99)

  let l =
    treelist.from_list(list.range(0, 49) |> list.map(int.to_string))
    |> should.be_ok

  let #(e, l) =
    treelist.remove(l, 2)
    |> should.be_ok
  e |> should.equal("2")
  l |> treelist.size |> should.equal(49)
  let #(e, l) =
    treelist.remove(l, 25)
    |> should.be_ok
  e |> should.equal("26")
  l |> treelist.size |> should.equal(48)
  let #(e, l) =
    treelist.remove(l, 40)
    |> should.be_ok
  e |> should.equal("42")
  l |> treelist.size |> should.equal(47)
  l |> treelist.remove(99) |> should.be_error
  let #(e, l) =
    treelist.remove(l, 1)
    |> should.be_ok
  e |> should.equal("1")
  l |> treelist.size |> should.equal(46)
  let #(e, l) =
    treelist.remove(l, 10)
    |> should.be_ok
  e |> should.equal("12")
  l |> treelist.size |> should.equal(45)
  let #(e, l) =
    treelist.remove(l, 2)
    |> should.be_ok
  e |> should.equal("4")
  l |> treelist.size |> should.equal(44)
}

pub fn mass_test() {
  let new_list =
    list.range(1, 100_000)
    |> list.try_fold(treelist.new(), fn(acc, i) { treelist.insert(acc, 0, i) })
    |> should.be_ok
  new_list |> treelist.size |> should.equal(100_000)
  list.range(1, 100_000)
  |> list.each(fn(i) {
    treelist.get(new_list, i - 1) |> should.be_ok |> should.equal(100_001 - i)
  })

  let new_list =
    list.range(1, 100_000)
    |> list.try_fold(treelist.new(), fn(acc, i) { treelist.add(acc, i) })
    |> should.be_ok
  new_list |> treelist.size |> should.equal(100_000)

  list.range(1, 100_000)
  |> list.each(fn(i) {
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

pub fn to_iterator_reverse_test() {
  let l = list.range(0, 99)
  l
  |> treelist.from_list
  |> should.be_ok
  |> treelist.to_iterator_reverse
  |> iterator.to_list
  |> should.equal(list.reverse(l))
}

pub fn index_of_test() {
  let l =
    list.range(0, 99)
    |> treelist.from_list
    |> should.be_ok
  l
  |> treelist.index_of(49)
  |> should.equal(49)

  l
  |> treelist.index_of(0)
  |> should.equal(0)

  l
  |> treelist.index_of(99)
  |> should.equal(99)

  l
  |> treelist.index_of(999)
  |> should.equal(-1)

  let l =
    treelist.set(l, 49, 999)
    |> should.be_ok
  l
  |> treelist.index_of(49)
  |> should.equal(-1)
  l
  |> treelist.index_of(999)
  |> should.equal(49)
}

pub fn last_index_of_test() {
  let l =
    list.range(0, 99)
    |> treelist.from_list
    |> should.be_ok
  l
  |> treelist.last_index_of(49)
  |> should.equal(49)
  l
  |> treelist.last_index_of(0)
  |> should.equal(0)

  l
  |> treelist.last_index_of(99)
  |> should.equal(99)

  l
  |> treelist.last_index_of(999)
  |> should.equal(-1)

  let l =
    treelist.set(l, 99, 49)
    |> should.be_ok

  l
  |> treelist.last_index_of(49)
  |> should.equal(99)
  l
  |> treelist.index_of(49)
  |> should.equal(49)

  treelist.from_list([9, 9, 9, 9, 9])
  |> should.be_ok
  |> treelist.last_index_of(9)
  |> should.equal(4)
}

pub fn set_test() {
  treelist.set(treelist.new(), 0, "New")
  |> should.be_error

  let l =
    treelist.from_list([0, 0, 0, 0, 0])
    |> should.be_ok

  treelist.to_list(l) |> should.equal([0, 0, 0, 0, 0])

  treelist.set(l, 2, 999)
  |> should.be_ok
  |> treelist.to_list
  |> should.equal([0, 0, 999, 0, 0])

  treelist.set(l, 4, 999)
  |> should.be_ok
  |> treelist.to_list
  |> should.equal([0, 0, 0, 0, 999])

  treelist.set(l, 5, 999) |> should.be_error
}

pub fn filter_test() {
  let l = treelist.from_list(list.range(0, 99)) |> should.be_ok

  treelist.size(l) |> should.equal(100)

  let l2 = treelist.filter(l, fn(el) { int.is_even(el) })
  treelist.size(l2) |> should.equal(50)
  list.range(0, 99)
  |> list.each(fn(i) {
    treelist.index_of(l2, i)
    |> should.equal(case int.is_even(i) {
      False -> -1
      True -> i / 2
    })
  })

  treelist.filter(l, fn(el) { el >= 90 })
  |> treelist.size
  |> should.equal(10)

  treelist.filter(l, fn(el) { el >= 100 })
  |> treelist.size
  |> should.equal(0)

  treelist.filter(l, fn(el) { el >= 0 })
  |> treelist.size
  |> should.equal(100)

  treelist.filter(treelist.new(), fn(_el) { True })
  |> should.equal(treelist.new())

  // TCO test
  list.range(0, recursion_test_cycles)
  |> treelist.from_list
  |> should.be_ok
  |> treelist.filter(fn(x) { x == -1 })
}

pub fn reverse_test() {
  treelist.reverse(treelist.new())
  |> should.equal(treelist.new())

  let assert Ok(l) = treelist.from_list([1])
  l
  |> treelist.reverse
  |> treelist.to_list
  |> should.equal([1])

  let assert Ok(l) = treelist.from_list([1, 2])
  l
  |> treelist.reverse
  |> treelist.to_list
  |> should.equal([2, 1])

  let assert Ok(l) = treelist.from_list([1, 2, 3, 4, 5])
  l
  |> treelist.reverse
  |> treelist.to_list
  |> should.equal([5, 4, 3, 2, 1])

  // TCO test
  let assert Ok(l) = treelist.repeat(0, recursion_test_cycles)
  l
  |> treelist.reverse
}

pub fn first_test() {
  let assert Ok(l) = treelist.from_list([0, 4, 5, 7])
  treelist.first(l)
  |> should.equal(Ok(0))

  treelist.first(treelist.new())
  |> should.equal(Error(Nil))
}

pub fn last_test() {
  let assert Ok(l) = treelist.from_list([0, 4, 5, 7])
  treelist.last(l)
  |> should.equal(Ok(7))

  treelist.last(treelist.new())
  |> should.equal(Error(Nil))
}

pub fn contains_test() {
  let assert Ok(l) = treelist.from_list([0, 4, 5, 1])
  treelist.contains(l, 1)
  |> should.be_true

  let assert Ok(l) = treelist.from_list([0, 4, 5, 7])
  treelist.contains(l, 1)
  |> should.be_false

  treelist.contains(treelist.new(), 1)
  |> should.be_false

  // TCO test
  let assert Ok(l) = treelist.repeat(0, recursion_test_cycles)
  l
  |> treelist.contains(1)
}

pub fn rest_test() {
  let assert Ok(l) = treelist.from_list([0, 4, 5, 7])
  treelist.rest(l)
  |> should.be_ok
  |> treelist.to_list
  |> should.equal([4, 5, 7])

  let assert Ok(l) = treelist.from_list([0])
  treelist.rest(l)
  |> should.be_ok
  |> treelist.to_list
  |> should.equal([])

  treelist.rest(treelist.new())
  |> should.equal(Error(Nil))
}

pub fn filter_map_test() {
  let assert Ok(l) = treelist.from_list([2, 4, 6, 1])
  l
  |> treelist.filter_map(fn(x) { Ok(x + 1) })
  |> treelist.to_list
  |> should.equal([3, 5, 7, 2])

  l
  |> treelist.filter_map(Error)
  |> treelist.to_list
  |> should.equal([])

  // TCO test
  treelist.repeat(0, recursion_test_cycles)
  |> should.be_ok
  |> treelist.filter_map(fn(x) { Ok(x + 1) })
}

pub fn map_test() {
  treelist.new()
  |> treelist.map(fn(x) { x * 2 })
  |> should.equal(treelist.new())

  let assert Ok(l) = treelist.from_list([0, 4, 5, 7, 3])
  l
  |> treelist.map(fn(x) { x * 2 })
  |> treelist.to_list
  |> should.equal([0, 8, 10, 14, 6])

  // TCO test
  treelist.repeat(0, recursion_test_cycles)
  |> should.be_ok
  |> treelist.map(fn(x) { x })
}

pub fn try_map_test() {
  let fun = fn(x) {
    case x == 6 || x == 5 || x == 4 {
      True -> Ok(x * 2)
      False -> Error(x)
    }
  }

  let assert Ok(l) = treelist.from_list([5, 6, 5, 6])

  l
  |> treelist.try_map(fun)
  |> should.be_ok
  |> treelist.to_list
  |> should.equal([10, 12, 10, 12])

  let assert Ok(l) = treelist.from_list([4, 6, 5, 7, 3])
  l
  |> treelist.try_map(fun)
  |> should.equal(Error(7))

  // TCO test
  treelist.repeat(6, recursion_test_cycles)
  |> should.be_ok
  |> treelist.try_map(fun)
}

pub fn drop_test() {
  treelist.new()
  |> treelist.drop(5)
  |> treelist.to_list
  |> should.equal([])

  let assert Ok(list) = treelist.from_list([1, 2, 3, 4, 5, 6, 7, 8])
  list
  |> treelist.drop(5)
  |> treelist.to_list
  |> should.equal([6, 7, 8])

  // TCO test
  let assert Ok(list) = treelist.repeat(0, recursion_test_cycles)

  list
  |> treelist.drop(recursion_test_cycles)
}
