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
  |> should.be_true()
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
  let new_map = map.put(a, "key", 123)
  map.size(new_map)
  |> should.equal(1)
  map.is_empty(new_map)
  |> should.equal(False)
}
