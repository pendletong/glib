import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import gleam/iterator
import gleam/int
import map

pub fn main() {
  gleeunit.main()
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
  let new_map = map.put(a, "key", "123")
  map.size(new_map)
  |> should.equal(1)
  map.is_empty(new_map)
  |> should.equal(False)

  map.get(new_map, "key")
  |> should.equal(Some("123"))

  // overwrite key
  let new_map = map.put(new_map, "key", "999")

  map.get(new_map, "key")
  |> should.equal(Some("999"))

  // add new entry
  // key should hash to the same value as copykey
  // this is not the best test because if the hash
  // process changes then this test stops working
  let new_map = map.put(new_map, "copykey", "111")

  map.get(new_map, "copykey")
  |> should.equal(Some("111"))

  // add 20 new entries
  // this should grow the map so we can test that the
  // enlarged map still contains the original entries
  let it = iterator.range(0, 19)
  let new_map = {
    it
    |> iterator.fold(new_map, fn(map, i) {
      let key = "growkey" <> int.to_string(i)
      map.put(new_map, key, key)
    })
  }

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

  let new_map = map.clear(new_map)
  map.size(new_map)
  |> should.equal(0)
}

pub fn get_test() {
  let a = map.new()

  map.get(a, "nothing")
  |> should.equal(None)

  let new_map = map.put(a, "test", "value")

  map.get(new_map, "test")
  |> should.equal(Some("value"))
}
