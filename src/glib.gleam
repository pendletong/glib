import gleam/io
import gleam/int
import map
import gleamy/bench
import gleam/list
import gleam/iterator
import gleam/dict
import gleam/result

pub fn main() {
  io.println("Hello from glib!")

  let a = map.new()
  let a = map.put(a, "key", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  let a = map.put(a, "key2", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  let a = map.put(a, "key7", 123)
  let a = map.put(a, "key9", 123)
  let a = map.put(a, "key123", 123)
  let a = map.put(a, "keygds", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  let a = map.put(a, "keygz", 123)
  let a = map.put(a, "keygza", 123)
  let a = map.put(a, "keygpo", 123)
  let a = map.put(a, "keygpo", 123)
  let a = map.put(a, "keygpo", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  io.debug(map.size(a))

  io.debug(map.is_empty(a))
  io.debug(map.get(a, "keygpo"))
  io.debug(map.keys(a))
  io.debug(map.values(a))
  io.debug(map.entries(a))
  io.debug(map.contains_key(a, "keygpo"))
  io.debug(map.contains_key(a, "keygpozzz"))
  map_bench()
  dict_bench()
  // let l = list.range(1, 50)
  // let s = list.split(l, 1)
  // io.debug(list.concat([s.1, s.0]))
  // bench.run(
  //   [bench.Input("reversed list", list.range(1, 1000))],
  //   [bench.Function("list.sort()", split_join)],
  //   [bench.Duration(1000), bench.Warmup(100)],
  // )
  // |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  // |> io.println()

  // bench.run(
  //   [bench.Input("reversed list", list.range(1, 1000))],
  //   [bench.Function("list.sort()", insert_at)],
  //   [bench.Duration(1000), bench.Warmup(100)],
  // )
  // |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  // |> io.println()
}

fn find_600(l: List(Int), i) {
  case result.unwrap(list.at(l, i), 600) {
    600 -> True
    _ -> find_600(l, i + 1)
  }
}

fn split_join(l: List(Int)) {
  let l2 = list.split(l, 500)
  let _l3 = list.concat([l2.0, [999], result.unwrap(list.rest(l2.1), [])])
}

fn insert_at(l: List(Int)) {
  list.map_fold(l, 0, fn(i, e) {
    case i == 500 {
      True -> #(i + 1, 999)
      False -> #(i + 1, e)
    }
  })
}

fn map_bench() {
  let inputs = [bench.Input("simple test", #("First", "Entry"))]

  let map_test = fn(test_map: map.Map(value), entry: #(String, value)) {
    map.put(test_map, entry.0, entry.1)
  }

  let init_sizes = [0, 5, 10, 15, 18, 50, 100, 1000]
  let tests =
    list.map(init_sizes, fn(size) {
      bench.Function("Map size " <> int.to_string(size), map_test(
        {
          case size {
            0 -> map.new()
            _ -> {
              iterator.range(1, size)
              |> iterator.to_list
              |> list.fold(map.new(), fn(new_map, i) {
                map.put(
                  new_map,
                  "key" <> int.to_string(i),
                  "value" <> int.to_string(i),
                )
              })
            }
          }
        },
        _,
      ))
    })
  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(1000)])
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println
}

fn dict_bench() {
  let inputs = [bench.Input("simple test", #("First", "Entry"))]

  let map_test = fn(test_map: dict.Dict(String, value), entry: #(String, value)) {
    dict.insert(test_map, entry.0, entry.1)
  }

  let init_sizes = [0, 5, 10, 15, 18, 50, 100, 1000]
  let tests =
    list.map(init_sizes, fn(size) {
      bench.Function("Map size " <> int.to_string(size), map_test(
        {
          case size {
            0 -> dict.new()
            _ -> {
              iterator.range(1, size)
              |> iterator.to_list
              |> list.fold(dict.new(), fn(new_map, i) {
                dict.insert(
                  new_map,
                  "key" <> int.to_string(i),
                  "value" <> int.to_string(i),
                )
              })
            }
          }
        },
        _,
      ))
    })
  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(1000)])
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println
}
