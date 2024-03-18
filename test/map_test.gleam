import showtime
import showtime/tests/should
import gleam/option.{None, Some}
import gleam/iterator
import gleam/int
import map.{type Map}
import gleam/io

pub fn main() {
  showtime.main()
}

pub fn new_test() {
  let a = map.new()
  map.size(a)
  |> should.equal(0)
  map.is_empty(a)
  |> should.be_true()

  map.get(a, "nothing")
  |> should.equal(None)
}

pub fn new_with_size_test() {
  let a = map.new_with_size(5)
  map.size(a)
  |> should.equal(0)
  map.is_empty(a)
  |> should.be_true()
}

pub fn put_test() {
  let a = map.new()

  check_size_vs_count(a)

  let new_map = map.put(a, "key", "123")
  map.size(new_map)
  |> should.equal(1)
  map.is_empty(new_map)
  |> should.equal(False)

  check_size_vs_count(new_map)

  map.get(new_map, "key")
  |> should.equal(Some("123"))

  // overwrite key
  let new_map = map.put(new_map, "key", "999")

  map.get(new_map, "key")
  |> should.equal(Some("999"))

  check_size_vs_count(new_map)

  // add new entry
  // key should hash to the same value as copykey
  // this is not the best test because if the hash
  // process changes then this test stops working
  let new_map = map.put(new_map, "copykey", "111")

  map.get(new_map, "copykey")
  |> should.equal(Some("111"))

  check_size_vs_count(new_map)

  // add 20 new entries
  // this should grow the map so we can test that the
  // enlarged map still contains the original entries
  let it = iterator.range(0, 19)
  let new_map = {
    it
    |> iterator.fold(new_map, fn(map, i) {
      let key = "growkey" <> int.to_string(i)
      map.put(map, key, key)
    })
  }

  check_size_vs_count(new_map)

  it
  |> iterator.all(fn(i) {
    let key = "growkey" <> int.to_string(i)
    case map.get(new_map, key) {
      None -> False
      Some(v) if v == key -> True
      _ -> False
    }
  })
}

pub fn clear_test() {
  let a = map.new_with_size(5)
  let new_map = map.put(a, "key", 123)
  map.size(new_map)
  |> should.equal(1)

  check_size_vs_count(new_map)

  let new_map = map.clear(new_map)
  map.size(new_map)
  |> should.equal(0)

  check_size_vs_count(new_map)
}

pub fn get_test() {
  let a = map.new()

  map.get(a, "nothing")
  |> should.equal(None)

  let new_map = map.put(a, "test", "value")

  map.get(new_map, "test")
  |> should.equal(Some("value"))
}

pub fn remove_test() {
  let a = map.new()

  let new_map = map.put(a, "item1", "item1")
  new_map
  |> map.size
  |> should.equal(1)

  check_size_vs_count(new_map)

  let ret = map.remove(new_map, "item1")
  let new_map = ret.1
  ret.0
  |> should.equal(Some("item1"))
  map.size(new_map)
  |> should.equal(0)

  check_size_vs_count(new_map)

  let it = iterator.range(0, 19)
  let new_map = {
    it
    |> iterator.fold(new_map, fn(map, i) {
      let key = "growkey" <> int.to_string(i)
      map.put(map, key, key)
    })
  }

  new_map
  |> map.size
  |> should.equal(20)

  let ret = map.remove(new_map, "growkey9")
  let new_map = ret.1
  ret.0
  |> should.equal(Some("growkey9"))
  new_map
  |> map.size
  |> should.equal(19)

  check_size_vs_count(new_map)

  // Remove non-existent key
  let ret = map.remove(new_map, "growkey999")
  let new_map = ret.1
  ret.0
  |> should.equal(None)
  new_map
  |> map.size
  |> should.equal(19)

  check_size_vs_count(new_map)
}

fn check_size_vs_count(map: Map(value)) {
  map.size(map)
  |> should.equal(map.full_count(map))
}
