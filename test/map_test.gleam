import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/yielder
import gleeunit/should
import glib/map

pub fn new_test() {
  let a =
    map.new()
    |> should.be_ok
  map.size(a)
  |> should.equal(0)
  map.is_empty(a)
  |> should.be_true()

  map.get(a, "nothing")
  |> should.be_ok
  |> should.equal(None)
}

pub fn new_with_size_test() {
  let a =
    map.new_with_size(5)
    |> should.be_ok
  map.size(a)
  |> should.equal(0)
  map.is_empty(a)
  |> should.be_true()
}

pub fn put_test() {
  let a =
    map.new()
    |> should.be_ok

  check_size_vs_count(a)
  let new_map =
    map.put(a, "key", "123")
    |> should.be_ok
  map.size(new_map)
  |> should.equal(1)
  map.is_empty(new_map)
  |> should.equal(False)

  check_size_vs_count(new_map)

  map.get(new_map, "key")
  |> should.be_ok
  |> should.equal(Some("123"))

  // overwrite key
  let new_map = map.put(new_map, "key", "999") |> should.be_ok

  map.get(new_map, "key")
  |> should.be_ok
  |> should.equal(Some("999"))

  check_size_vs_count(new_map)

  // add new entry
  // key should hash to the same value as copykey
  // this is not the best test because if the hash
  // process changes then this test stops working
  let new_map = map.put(new_map, "copykey", "111") |> should.be_ok

  map.get(new_map, "copykey")
  |> should.be_ok
  |> should.equal(Some("111"))

  check_size_vs_count(new_map)

  // add 20 new entries
  // this should grow the map so we can test that the
  // enlarged map still contains the original entries
  let it = yielder.range(0, 19)
  let new_map = {
    it
    |> yielder.fold(new_map, fn(map, i) {
      let key = "growkey" <> int.to_string(i)
      map.put(map, key, key) |> should.be_ok
    })
  }

  check_size_vs_count(new_map)

  it
  |> yielder.all(fn(i) {
    let key = "growkey" <> int.to_string(i)
    case map.get(new_map, key) |> should.be_ok {
      None -> False
      Some(v) if v == key -> True
      _ -> False
    }
  })
  |> should.be_true()

  it
  |> yielder.all(fn(i) {
    let key = "growkey" <> int.to_string(i)
    map.contains_key(new_map, key)
  })
  |> should.be_true()
}

pub fn clear_test() {
  let a = map.new_with_size(5) |> should.be_ok
  let new_map = map.put(a, "key", 123) |> should.be_ok
  map.size(new_map)
  |> should.equal(1)

  check_size_vs_count(new_map)

  let new_map = map.clear(new_map) |> should.be_ok
  map.size(new_map)
  |> should.equal(0)

  check_size_vs_count(new_map)
}

pub fn get_test() {
  let a = map.new() |> should.be_ok

  map.get(a, "nothing")
  |> should.be_ok
  |> should.equal(None)

  let new_map = map.put(a, "test", "value") |> should.be_ok

  map.get(new_map, "test")
  |> should.be_ok
  |> should.equal(Some("value"))
}

pub fn remove_test() {
  let a = map.new() |> should.be_ok

  let new_map = map.put(a, "item1", "item1") |> should.be_ok
  new_map
  |> map.size
  |> should.equal(1)

  check_size_vs_count(new_map)

  let ret = map.remove(new_map, "item1") |> should.be_ok
  let new_map = ret.1
  ret.0
  |> should.equal(Some("item1"))
  map.size(new_map)
  |> should.equal(0)

  check_size_vs_count(new_map)

  let it = yielder.range(0, 19)
  let new_map = {
    it
    |> yielder.fold(new_map, fn(map, i) {
      let key = "growkey" <> int.to_string(i)
      map.put(map, key, key) |> should.be_ok
    })
  }

  new_map
  |> map.size
  |> should.equal(20)

  let ret = map.remove(new_map, "growkey9") |> should.be_ok
  let new_map = ret.1
  ret.0
  |> should.equal(Some("growkey9"))
  new_map
  |> map.size
  |> should.equal(19)

  check_size_vs_count(new_map)

  // Remove non-existent key
  let ret = map.remove(new_map, "growkey999") |> should.be_ok
  let new_map = ret.1
  ret.0
  |> should.equal(None)
  new_map
  |> map.size
  |> should.equal(19)

  check_size_vs_count(new_map)
}

fn check_size_vs_count(m) {
  map.size(m)
  |> should.equal(map.full_count(m))
}

pub fn random_test() {
  yielder.repeatedly(fn() { int.random(995) + 5 })
  |> yielder.take(50)
  |> yielder.each(fn(l) {
    let #(map, keys) =
      yielder.range(0, l)
      |> yielder.fold(#(map.new() |> should.be_ok, []), fn(acc, i) {
        let #(new_map, keys) = acc
        let key =
          "growkey"
          <> int.to_string(i)
          <> "_"
          <> int.to_string(int.random(1_000_000))

        #(map.put(new_map, key, key) |> should.be_ok, [key, ..keys])
      })

    list.each(keys, fn(k) {
      map.contains_key(map, k)
      |> should.be_true()
    })
  })
}
