import gleam/io
import gleam/regexp.{Options}

pub fn main() {
  io.println("Hello world")

  // let it = iterator.range(0, 19)
  // let new_map = {
  //   it
  //   |> iterator.fold(result.lazy_unwrap(map.new(), fn() { panic }), fn(map, i) {
  //     let key = "growkey" <> int.to_string(i)
  //     result.lazy_unwrap(map.put(map, key, key), fn() { panic })
  //   })
  // }

  // io.debug(map.to_string(new_map, fn(s) { s }))
  // let l = result.unwrap(treelist.repeat("a", 10), treelist.new())
  // let l = result.unwrap(treelist.add(l, "b"), treelist.new())
  // io.debug(treelist.to_list(l))
  // let l = result.unwrap(treelist.filter(l, fn(e) { e == "a" }), treelist.new())
  // io.debug(treelist.to_list(l))

  // iterator.range(0, 19)
  // |> iterator.try_fold(treelist.new(), fn(tl, i) { treelist.add(tl, i) })
  // |> io.debug

  // let assert Ok(f1) = fraction.new(min_int_value, 3)
  // let assert Ok(f2) = fraction.new(1, 3)

  // fraction.add(f1, f2)
  // |> io.debug

  // io.debug(int.to_float(10_000_000_000) /. int.to_float(max_int_value))
  // let fr =
  //   fraction.from_float(
  //     int.to_float(10_000_000_000) /. int.to_float(max_int_value),
  //   )
  //   |> io.debug

  // fraction.from_string("0.333333") |> io.debug
  // fraction.from_float(0.33333333333333333) |> io.debug
  // 1.0 /. 10_001.0
  // |> io.debug
  // |> fraction.from_float
  // |> io.debug
  // fraction.from_string("0.0") |> io.debug
  // fraction.from_float(0.0) |> io.debug

  let options = Options(case_insensitive: False, multi_line: True)
  let assert Ok(re) =
    regexp.compile(
      "^[\u{4E00}-\u{9FAF}\u{3040}-\u{3096}\u{30A1}-\u{30FA}\u{FF66}-\u{FF9D}\u{31F0}-\u{31FF}]*$",
      with: options,
    )
  regexp.check(re, "abc")
  |> io.debug
}

const max_int_value = 9_007_199_254_740_991

const min_int_value = -9_007_199_254_740_991
