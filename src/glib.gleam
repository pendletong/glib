import gleam/io
import gleam/int
import glib/map
import gleamy/bench
import gleam/list
import gleam/iterator
import gleam/dict

pub fn main() {
  tests()
  // iterator.range(1, 100)
  // |> iterator.each(fn(_i) {
  //   let map =
  //     iterator.range(0, 8)
  //     |> iterator.fold(map.new(), fn(map, i) {
  //       let k =
  //         "key_"
  //         <> int.to_string(i)
  //         <> "_"
  //         <> int.to_string(int.random(1_000_000))
  //       map.put(map, k, k)
  //     })

  //   // io.debug(map)
  //   io.debug(map.list_size(map))
  // })
  // rehash_test()
  // bench_at()
}

fn at(list: List(Int), pos: Int) {
  let assert [r, ..] = list.split(list, pos).1
  r
}

fn bench_at() {
  let inputs =
    iterator.iterate(11, fn(n) { n * 2 + 1 })
    |> iterator.take(8)
    |> iterator.to_list
    |> list.map(fn(size) {
      bench.Input("Map size " <> int.to_string(size), #(
        size / 2,
        list.range(1, size),
      ))
    })

  let tests = [
    bench.Function("Find Entry", fn(test_list: #(Int, List(Int))) {
      let _value = list.at(test_list.1, test_list.0)
      Nil
    }),
    bench.Function("Split Entry", fn(test_list: #(Int, List(Int))) {
      let _value = at(test_list.1, test_list.0)
      Nil
    }),
  ]

  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.Max, bench.P(99)])
  |> io.println
}

fn rehash_test() {
  let a = map.new()

  let new_map = map.put(a, "key", "123")

  io.debug(new_map)
  // overwrite key
  let new_map = map.put(new_map, "key", "999")
  io.debug(new_map)

  // add new entry
  // key should hash to the same value as copykey
  // this is not the best test because if the hash
  // process changes then this test stops working
  let new_map = map.put(new_map, "copykey", "111")

  io.debug(new_map)

  // add 20 new entries
  // this should grow the map so we can test that the
  // enlarged map still contains the original entries
  let it = iterator.range(0, 19)
  let new_map = {
    it
    |> iterator.fold(new_map, fn(map, i) {
      let key = "growkey" <> int.to_string(i)
      let new_map = map.put(map, key, key)
      // io.debug(new_map)
      new_map
    })
  }
}

fn tests() {
  io.println("Hello from glib!")

  map.new()
  |> map.to_string(fn(s) { s })
  |> io.debug()

  map.new()
  |> map.put("key", 123)
  |> map.to_string(fn(s) { int.to_string(s) })
  |> io.println()

  // map_bench([0, 5, 10, 15, 18, 50, 100, 1000])
  map_bench([
    7, 8, 9, 10, 16, 17, 18, 34, 35, 36, 70, 71, 72, 142, 143, 144, 286, 287,
    288, 574, 575, 576, 1150, 1151, 1152, 1153,
  ])
  dict_bench([
    7, 8, 9, 10, 16, 17, 18, 34, 35, 36, 70, 71, 72, 142, 143, 144, 286, 287,
    288, 574, 575, 576, 1150, 1151, 1152, 1153,
  ])
  // 1151, 1152])
  // dict_bench([0, 5, 10, 15, 18, 50, 100, 1000])
  // dict_bench()
  // iterator.range(1, 10)
  // |> iterator.fold(map.new(), fn(acc, i) {
  //   let kv = "key" <> int.to_string(i)
  //   map.put(acc, kv, kv)
  // })
  // |> io.debug
}

fn extra() {
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
  io.debug(map.full_count(a))
  // map_bench([0, 5, 10, 15, 18, 50, 100, 1000])
  // dict_bench([0, 5, 10, 15, 18, 50, 100, 1000])
}

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

fn dict_bench2(init_sizes: List(Int)) {
  let inputs =
    list.map(init_sizes, fn(size) {
      bench.Input("Map size " <> int.to_string(size), {
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
      })
    })

  let tests = [
    bench.Function("Add Entry", fn(test_map: dict.Dict(String, String)) {
      dict.insert(test_map, "First", "Entry")
    }),
  ]

  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println
}

fn dict_bench3() {
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
  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println
}

fn list_bench() {
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
  bench.run(inputs, tests, [bench.Warmup(100), bench.Duration(2000)])
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println
}
