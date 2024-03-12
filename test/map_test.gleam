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
