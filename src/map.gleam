import gleam/option.{type Option, None, Some}
import gleam/list
import gleam/int
import hash

const default_size = 16

pub opaque type Map(value) {
  Map(inner: List(Option(Entry(value))))
}

pub fn new() -> Map(value) {
  new_with_size(default_size)
}

pub fn new_with_size(size: Int) -> Map(vale) {
  Map(list.repeat(None, size))
}

pub fn clear(_previous_map: Map(value)) -> Map(value) {
  new()
}

pub fn is_empty(map: Map(value)) -> Bool {
  size(map) == 0
}

pub fn size(map: Map(value)) -> Int {
  get_size(map.inner, 0)
}

fn get_size(list: List(Option(Entry(value))), accumulator: Int) -> Int {
  case list {
    [] -> accumulator
    [first, ..rest] -> {
      let inc = case first {
        None -> 0
        Some(_a) -> 1
      }
      get_size(rest, inc + accumulator)
    }
  }
}

pub fn put(map: Map(value), key: String, value: value) -> Map(value) {
  todo
  let entry = Entry(key, value)
  let hash = hash(map, key)

  map
}

fn find_gap(map: Map(value), orig_position: Int, position: Int) -> Int {
  case list.at(map.inner, position) {
    Ok(None) -> position
    Ok(Some(_e)) -> {
      case position {
        position if position == orig_position -> -1
        position if position == 0 ->
          find_gap(map, orig_position, list.length(map.inner) - 1)
        position -> find_gap(map, orig_position, position - 1)
      }
    }
    _ -> -1
  }
}

fn rehash(map: Map(value), new_size: Int) -> Map(value) {
  list.fold(map.inner, new_with_size(new_size), fn(new_map, el) {
    case el {
      Some(entry) -> put(new_map, entry.key, entry.value)
      None -> new_map
    }
  })
}

fn hash(map: Map(value), key: String) -> Int {
  hash.hash(key) % list.length(map.inner)
  |> int.absolute_value()
}

type Entry(value) {
  Entry(key: String, value: value)
}
