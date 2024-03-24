import gleamy/bench
import gleam/list
import gleam/iterator
import gleam/int
import gleam/io

pub fn bench() {
  bench_at()
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
