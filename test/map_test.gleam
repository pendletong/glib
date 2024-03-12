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
  case map.put(a, "key", 123) {
    Ok(m) -> {
      map.size(m)
      |> should.equal(1)
      map.is_empty(m)
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}
