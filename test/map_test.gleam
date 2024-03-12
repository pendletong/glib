import gleeunit
import gleeunit/should
import map

pub fn main() {
  gleeunit.main()
}

pub fn new_test() {
  let a = map.new()
  map.size(a)
  |> should.equal(0)
  map.is_empty(a)
  |> should.equal(True)
}

pub fn put_test() {
  let a = map.new()
  let a = map.put(a, "key", 123)
  map.size(a)
  |> should.equal(1)
  map.is_empty(a)
  |> should.equal(False)
}
