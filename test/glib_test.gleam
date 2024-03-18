import showtime
import showtime/tests/should

pub fn main() {
  showtime.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}
