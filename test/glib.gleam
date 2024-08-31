import gleam/io
import gleam/iterator
import gleam/result
import glib/treelist

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

  let assert Ok(l) = treelist.repeat("a", 10)

  treelist.to_iterator(l) |> iterator.to_list
  // iterator.range(0, 19)
  // |> iterator.try_fold(treelist.new(), fn(tl, i) { treelist.add(tl, i) })
  // |> io.debug
}
