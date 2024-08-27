import gleam/dict
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleamy/bench
import glib/map

pub fn bench() {
  // bench_at()
  map_bench([0, 5, 10, 15, 18, 50, 100, 1000])
  dict_bench([0, 5, 10, 15, 18, 50, 100, 1000])
}

// fn at(list: List(Int), pos: Int) {
//   let assert [r, ..] = list.split(list, pos).1
//   r
// }

// fn bench_at() {
//   let inputs =
//     iterator.iterate(11, fn(n) { n * 2 + 1 })
//     |> iterator.take(8)
//     |> iterator.to_list
//     |> list.map(fn(size) {
//       bench.Input("Map size " <> int.to_string(size), #(
//         size / 2,
//         list.range(1, size),
//       ))
//     })

//   let tests = [
//     bench.Function("Find Entry", fn(test_list: #(Int, List(Int))) {
//       let _value = list.at(test_list.1, test_list.0)
//       Nil
//     }),
//     bench.Function("Split Entry", fn(test_list: #(Int, List(Int))) {
//       let _value = at(test_list.1, test_list.0)
//       Nil
//     }),
//   ]

//   bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(2000)])
//   |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
//   |> io.println
// }

fn map_bench(init_sizes: List(Int)) {
  let inputs =
    list.map(init_sizes, fn(size) {
      bench.Input("Map size " <> int.to_string(size), {
        case size {
          0 -> map.new()
          _ -> {
            iterator.range(1, size)
            |> iterator.fold(map.new(), fn(new_map, i) {
              map.put(
                new_map,
                "key"
                  <> int.to_string(i)
                  <> "_"
                  <> int.to_string(int.random(1_000_000)),
                "value" <> int.to_string(i),
              )
            })
          }
        }
      })
    })

  let tests = [
    bench.Function("Add Entry", fn(test_map: map.Map(String)) {
      map.put(test_map, "First", "Entry")
    }),
  ]

  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
  |> io.println
}

fn dict_bench(init_sizes: List(Int)) {
  let inputs =
    list.map(init_sizes, fn(size) {
      bench.Input("Map size " <> int.to_string(size), {
        case size {
          0 -> dict.new()
          _ -> {
            iterator.range(1, size)
            |> iterator.fold(dict.new(), fn(new_map, i) {
              dict.insert(
                new_map,
                "key"
                  <> int.to_string(i)
                  <> "_"
                  <> int.to_string(int.random(1_000_000)),
                "value" <> int.to_string(i),
              )
            })
          }
        }
      })
    })

  let tests = [
    bench.Function("Add Entry", fn(test_map: dict.Dict(String, String)) {
      dict.insert(test_map, "First", "Entry")
    }),
  ]

  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
  |> io.println
}
