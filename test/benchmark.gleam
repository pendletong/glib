import gleam/bool
import gleam/dict
import gleam/int
import gleam/iterator
import gleam/list
import gleam/result
import glib/map
import glib/treelist.{type TreeList}
import glychee/benchmark
import glychee/configuration

@target(erlang)
pub fn main() {
  configuration.initialize()
  configuration.set_pair(configuration.Warmup, 2)
  configuration.set_pair(configuration.Parallel, 2)

  map_benchmark()
  list_benchmark()
  list_iterator_benchmark()
  list_remove_benchmark()
  list_reverse_benchmark()
  to_list_benchmark()
}

@target(erlang)
fn list_reverse_benchmark() {
  let l100 = list.range(0, 99)
  let l1000 = list.range(0, 999)
  let l10000 = list.range(0, 9999)
  let l100000 = list.range(0, 99_999)

  benchmark.run(
    [
      benchmark.Function(label: "treelist reverse", callable: fn(test_data) {
        fn() {
          let #(l, _) = test_data
          treelist.reverse(l)
          Nil
        }
      }),
      benchmark.Function(label: "list remove", callable: fn(test_data) {
        fn() {
          let #(_, l) = test_data
          list.reverse(l)
          Nil
        }
      }),
    ],
    [
      benchmark.Data(label: "100 items", data: {
        #(result.lazy_unwrap(treelist.from_list(l100), fn() { panic }), l100)
      }),
      benchmark.Data(label: "1000 items", data: {
        #(result.lazy_unwrap(treelist.from_list(l1000), fn() { panic }), l1000)
      }),
      benchmark.Data(label: "10000 items", data: {
        #(
          result.lazy_unwrap(treelist.from_list(l10000), fn() { panic }),
          l10000,
        )
      }),
      benchmark.Data(label: "100000 items", data: {
        #(
          result.lazy_unwrap(treelist.from_list(l100000), fn() { panic }),
          l100000,
        )
      }),
    ],
  )
}

@target(erlang)
fn to_list_benchmark() {
  benchmark.run(
    [
      benchmark.Function(label: "treelist to_list", callable: fn(test_data) {
        fn() { treelist.to_list(test_data) }
      }),
    ],
    [
      benchmark.Data(label: "1000 items", data: {
        list.range(0, 99)
        |> treelist.from_list
        |> result.unwrap(treelist.new())
      }),
      benchmark.Data(label: "10000 items", data: {
        list.range(0, 9999)
        |> treelist.from_list
        |> result.unwrap(treelist.new())
      }),
      benchmark.Data(label: "100000 items", data: {
        list.range(0, 99_999)
        |> treelist.from_list
        |> result.unwrap(treelist.new())
      }),
    ],
  )
}

@target(erlang)
fn list_remove_benchmark() {
  let l100 = list.range(0, 99)
  let l1000 = list.range(0, 999)
  let l10000 = list.range(0, 9999)

  benchmark.run(
    [
      benchmark.Function(label: "treelist remove", callable: fn(test_data) {
        fn() {
          let #(l, _, removals) = test_data
          list.fold(removals, l, fn(acc, r) {
            let assert Ok(#(_, l)) = treelist.remove(acc, r)
            l
          })
          Nil
        }
      }),
      benchmark.Function(label: "treelist filter", callable: fn(test_data) {
        fn() {
          let #(l, _, removals) = test_data
          treelist.filter(l, fn(val) {
            bool.negate(list.contains(removals, val))
          })
          Nil
        }
      }),
      benchmark.Function(label: "list remove", callable: fn(test_data) {
        fn() {
          let #(_, l, removals) = test_data
          list.fold(removals, l, fn(acc, r) {
            let #(l1, l2) = list.split(acc, r)
            list.append(l1, list.drop(l2, 1))
          })
          Nil
        }
      }),
      benchmark.Function(label: "list filter", callable: fn(test_data) {
        fn() {
          let #(_, l, removals) = test_data
          list.filter(l, fn(v) { bool.negate(list.contains(removals, v)) })
          Nil
        }
      }),
    ],
    [
      benchmark.Data(label: "100 items", data: {
        #(
          result.lazy_unwrap(treelist.from_list(l100), fn() { panic }),
          l100,
          list.range(0, 50)
            |> list.map(fn(v) { int.random(100 - v) }),
        )
      }),
      benchmark.Data(label: "1000 items", data: {
        #(
          result.lazy_unwrap(treelist.from_list(l1000), fn() { panic }),
          l1000,
          list.range(0, 500)
            |> list.map(fn(v) { int.random(1000 - v) }),
        )
      }),
      benchmark.Data(label: "10000 items", data: {
        #(
          result.lazy_unwrap(treelist.from_list(l10000), fn() { panic }),
          l10000,
          list.range(0, 5000)
            |> list.map(fn(v) { int.random(10_000 - v) }),
        )
      }),
    ],
  )
}

@target(erlang)
fn list_iterator_benchmark() {
  let l100 = list.range(0, 99)
  let l10000 = list.range(0, 9999)
  benchmark.run(
    [
      benchmark.Function(
        label: "treelist iterator",
        callable: fn(test_data: #(TreeList(Int), List(Int))) {
          fn() {
            treelist.to_iterator(test_data.0)
            |> iterator.to_list
          }
        },
      ),
      benchmark.Function(
        label: "iterator",
        callable: fn(test_data: #(TreeList(Int), List(Int))) {
          fn() {
            iterator.from_list(test_data.1)
            |> iterator.to_list
          }
        },
      ),
    ],
    [
      benchmark.Data(label: "100 items", data: {
        #(
          l100
            |> treelist.from_list
            |> result.unwrap(treelist.new()),
          l100,
        )
      }),
      benchmark.Data(label: "10000 items", data: {
        #(
          l10000
            |> treelist.from_list
            |> result.unwrap(treelist.new()),
          l10000,
        )
      }),
    ],
  )
}

@target(erlang)
fn list_benchmark() {
  let gen_data = fn(count: Int) {
    benchmark.Data(
      label: int.to_string(count) <> " items",
      data: iterator.range(1, count)
        |> iterator.to_list,
    )
  }
  benchmark.run(
    [
      benchmark.Function(
        label: "treelist add",
        callable: fn(test_data: List(Int)) {
          fn() {
            let _ =
              test_data
              |> list.try_fold(treelist.new(), fn(acc, i) {
                treelist.add(acc, i)
              })
            Nil
          }
        },
      ),
      benchmark.Function(
        label: "treelist insert",
        callable: fn(test_data: List(Int)) {
          fn() {
            let _ =
              test_data
              |> list.try_fold(treelist.new(), fn(acc, i) {
                treelist.insert(acc, 0, i)
              })
            Nil
          }
        },
      ),
      benchmark.Function(label: "list add", callable: fn(test_data: List(Int)) {
        fn() {
          test_data
          |> list.fold([], fn(acc, i) { [i, ..acc] })
          Nil
        }
      }),
      benchmark.Function(
        label: "list append",
        callable: fn(test_data: List(Int)) {
          fn() {
            test_data
            |> list.fold([], fn(acc, i) {
              list.reverse([i, ..list.reverse(acc)])
            })
            Nil
          }
        },
      ),
      benchmark.Function(
        label: "list insert",
        callable: fn(test_data: List(Int)) {
          fn() {
            test_data
            |> list.fold([], fn(acc, i) {
              let #(l1, l2) = list.split(acc, i / 2)
              list.append(l1, [i, ..l2])
            })
            Nil
          }
        },
      ),
      benchmark.Function(
        label: "treelist insert mid",
        callable: fn(test_data: List(Int)) {
          fn() {
            let _ =
              test_data
              |> list.try_fold(treelist.new(), fn(acc, i) {
                treelist.insert(acc, i / 2, i)
              })
            Nil
          }
        },
      ),
    ],
    [gen_data(10), gen_data(50), gen_data(100), gen_data(1000)],
  )
}

@target(erlang)
fn map_benchmark() {
  let gen_data = fn(count: Int) {
    benchmark.Data(
      label: int.to_string(count) <> " items",
      data: iterator.repeatedly(fn() {
        "key_" <> int.to_string(int.random(1_000_000))
      })
        |> iterator.take(count)
        |> iterator.to_list,
    )
  }
  benchmark.run(
    [
      benchmark.Function(
        label: "map insert",
        callable: fn(test_data: List(String)) {
          fn() {
            let new_map = result.lazy_unwrap(map.new(), fn() { panic })
            test_data
            |> list.fold(new_map, fn(acc, i) {
              result.unwrap(map.put(acc, i, i), new_map)
            })
            Nil
          }
        },
      ),
      benchmark.Function(
        label: "dict insert",
        callable: fn(test_data: List(String)) {
          fn() {
            test_data
            |> list.fold(dict.new(), fn(acc, i) { dict.insert(acc, i, i) })
            Nil
          }
        },
      ),
    ],
    [
      gen_data(5),
      gen_data(10),
      gen_data(15),
      gen_data(18),
      gen_data(50),
      gen_data(100),
      gen_data(1000),
    ],
  )
}
