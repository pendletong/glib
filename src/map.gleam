import gleam/option.{type Option, None, Some}
import gleam/list
import gleam/int
import gleam/float
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
  let hash = calc_hash(map, key)

  let assert Ok(entry) = list.at(map.inner, hash)

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
          let new_len = list.length(map.inner)
          let hash = calc_hash(map, key)
          let gap = find_gap(map, key, { hash + 1 } % new_len, hash)

          Map(insert_at(map.inner, gap, key, value), new_len, map.load)
        }
      }
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
    {
      int.to_float(length)
      |> float.multiply(map.load)
      |> float.round()
    }
  {
    l if size >= l -> {
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
  let assert Ok(entry) = list.at(map.inner, position)

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

fn rehash(map: Map(value), new_size: Int) -> Map(value) {
  list.fold(map.inner, new_with_size(new_size), fn(new_map, el) {
    case el {
      Some(entry) -> put(new_map, entry.key, entry.value)
      None -> new_map
    }
  })
}

fn calc_hash(map: Map(value), key: String) -> Int {
  hash.hash(key) % list.length(map.inner)
  |> int.absolute_value()
}

type Entry(value) {
  Entry(key: String, value: value)
}
