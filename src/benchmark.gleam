import gleam/dict
import gleam/int
import gleam/iterator
import gleam/list
import glib/map
import glib/treelist
import glychee/benchmark
import glychee/configuration

pub fn main() {
  configuration.initialize()
  configuration.set_pair(configuration.Warmup, 2)
  configuration.set_pair(configuration.Parallel, 2)

  map_benchmark()
  list_benchmark()
}

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
            test_data
            |> list.fold(map.new(), fn(acc, i) { map.put(acc, i, i) })
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
