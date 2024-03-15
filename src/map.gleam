import gleam/option.{type Option, None, Some}
import gleam/list
import gleam/int
import gleam/float
import gleam/string
import gleam/result
import hash

const default_size = 11

const default_load = 0.75

pub opaque type Map(value) {
  Map(inner: List(Option(Entry(value))), size: Int, load: Float)
}

pub fn new() -> Map(value) {
  new_with_size(default_size)
}

pub fn new_with_size(size: Int) -> Map(value) {
  //    glimt.info(log, "Creating Map of size "<>int.to_string(size))
  new_with_size_and_load(size, default_load)
}

pub fn new_with_size_and_load(size: Int, load: Float) -> Map(value) {
  Map(list.repeat(None, size), size, load)
}

pub fn clear(previous_map: Map(value)) -> Map(value) {
  new_with_size_and_load(previous_map.size, previous_map.load)
}

pub fn is_empty(map: Map(value)) -> Bool {
  size(map) == 0
}

pub fn size(map: Map(value)) -> Int {
  get_size(map.inner, 0)
}

pub fn put(map: Map(value), key: String, value: value) -> Map(value) {
  let hash = calc_hash(map, key)

  let entry = result.unwrap(list.at(map.inner, hash), None)

  case entry {
    None ->
      Map(
        insert_at(map.inner, hash, key, value),
        list.length(map.inner),
        map.load,
      )
    Some(e) -> {
      case e.key == key {
        True -> {
          Map(
            insert_at(map.inner, hash, key, value),
            list.length(map.inner),
            map.load,
          )
        }
        False -> {
          let map = check_capacity(map)
          let hash = calc_hash(map, key)
          let gap = find_gap(map, key, { hash + 1 } % map.size, hash)

          Map(insert_at(map.inner, gap, key, value), map.size, map.load)
        }
      }
    }
  }
}

pub fn get(map: Map(value), key: String) -> Option(value) {
  let hash = calc_hash(map, key)

  let entry = result.unwrap(list.at(map.inner, hash), None)

  case entry {
    None -> None
    Some(e) -> {
      case e.key == key {
        True -> Some(e.value)
        False -> {
          find_key(map, key, { hash + 1 } % map.size, hash)
        }
      }
    }
  }
}

pub fn to_string(
  map: Map(value),
  value_to_string: fn(value) -> String,
) -> String {
  "{"
  <> string.join(
    list.filter_map(map.inner, fn(opt) {
      case opt {
        None -> Error(opt)
        Some(e) -> Ok("\"" <> e.key <> "\"" <> ":" <> value_to_string(e.value))
      }
    }),
    with: ",",
  )
  <> "}"
}

fn get_size(list: List(Option(Entry(value))), accumulator: Int) -> Int {
  case list {
    [] -> accumulator
    [first, ..rest] -> {
      let inc = case first {
        None -> 0
        _ -> 1
      }
      get_size(rest, inc + accumulator)
    }
  }
}

fn insert_at(
  map_list: List(Option(Entry(value))),
  at: Int,
  key: String,
  value: value,
) -> List(Option(Entry(value))) {
  list.map_fold(map_list, 0, fn(i, e) {
    case i {
      i if i == at -> #(i + 1, Some(Entry(key, value)))
      i -> #(i + 1, e)
    }
  }).1
}

fn check_capacity(map: Map(value)) -> Map(value) {
  let size = size(map)
  let length = list.length(map.inner)

  case
    size
    >= {
      int.to_float(length)
      |> float.multiply(map.load)
      |> float.round()
    }
  {
    True -> {
      rehash(map, length * 2 + 1)
    }
    _ -> map
  }
}

fn find_gap(
  map: Map(value),
  key: String,
  last_position: Int,
  position: Int,
) -> Int {
  let entry = result.unwrap(list.at(map.inner, position), None)

  case entry {
    None -> position
    Some(e) -> {
      case e.key == key {
        True -> position
        False -> {
          case position {
            position if position == last_position -> -1
            0 -> find_gap(map, key, last_position, list.length(map.inner) - 1)
            position -> find_gap(map, key, last_position, position - 1)
          }
        }
      }
    }
  }
}

fn find_key(
  map: Map(value),
  key: String,
  last_position: Int,
  position: Int,
) -> Option(value) {
  let entry = result.unwrap(list.at(map.inner, position), None)

  case entry {
    None -> None
    Some(e) -> {
      case e.key == key {
        True -> Some(e.value)
        False -> {
          case position {
            position if position == last_position -> None
            0 -> find_key(map, key, last_position, list.length(map.inner) - 1)
            position -> find_key(map, key, last_position, position - 1)
          }
        }
      }
    }
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

pub fn calc_hash(map: Map(value), key: String) -> Int {
  hash.hash(key) % list.length(map.inner)
  |> int.absolute_value()
}

type Entry(value) {
  Entry(key: String, value: value)
}
