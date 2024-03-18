import gleam/list
import gleam/string

pub fn hash(value: String) -> Int {
  string.to_utf_codepoints(value)
  |> list.fold(from: 0, with: fn(acc, x) {
    string.utf_codepoint_to_int(x) + 31 * acc
  })
}
