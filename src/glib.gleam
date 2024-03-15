import gleam/io
import gleam/int
import map

pub fn main() {
  io.println("Hello from glib!")

  let a = map.new()
  let a = map.put(a, "key", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  let a = map.put(a, "key2", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  let a = map.put(a, "key7", 123)
  let a = map.put(a, "key9", 123)
  let a = map.put(a, "key123", 123)
  let a = map.put(a, "keygds", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  let a = map.put(a, "keygz", 123)
  let a = map.put(a, "keygza", 123)
  let a = map.put(a, "keygpo", 123)
  let a = map.put(a, "keygpo", 123)
  let a = map.put(a, "keygpo", 123)
  io.println(map.to_string(a, fn(v) { int.to_string(v) }))
  io.debug(map.size(a))

  io.debug(map.is_empty(a))
  io.debug(map.get(a, "keygpo"))
}
