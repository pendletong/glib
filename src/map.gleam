import gleam/option.{type Option, None, Some}
import gleam/list.{Continue, Stop}
import gleam/int
import gleam/io
import gleam/float
import hash

const default_size = 11

const default_load = 0.75

pub type MapError {
  NoSpaceError
  RehashError
}

pub opaque type Map(value) {
  Map(inner: List(Option(Entry(value))))
}

pub fn new() -> Map(value) {
  new_with_size(default_size)
}

pub fn new_with_size(size: Int) -> Map(vale) {
  //    glimt.info(log, "Creating Map of size "<>int.to_string(size))
  io.println("Creating Map of size " <> int.to_string(size))
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

pub fn put(
  map: Map(value),
  key: String,
  value: value,
) -> Result(Map(value), MapError) {
  let hash = hash(map, key)
  let current_length = list.length(map.inner)

  let map = check_capacity(map, current_length)

  case map {
    Error(_) -> map
    Ok(map) -> {
      let gap = find_gap(map, { hash + 1 } % current_length, hash)
      io.println(
        "Outputting "
        <> key
        <> " to hash "
        <> int.to_string(hash)
        <> " gap "
        <> int.to_string(gap),
      )

      case gap {
        -1 -> Error(NoSpaceError)
        _ ->
          Ok(Map(
            list.map_fold(map.inner, 0, fn(i, e) {
              case i {
                i if i == gap -> #(i + 1, Some(Entry(key, value)))
                i -> #(i + 1, e)
              }
            }).1,
          ))
      }
    }
  }
}

fn check_capacity(map: Map(value), length: Int) -> Result(Map(value), MapError) {
  let size = size(map)
  case
    {
      int.to_float(length)
      |> float.multiply(default_load)
      |> float.round()
    }
  {
    l if size > l -> rehash(map, length * 2 + 1)
    _ -> Ok(map)
  }
}

fn find_gap(map: Map(value), last_position: Int, position: Int) -> Int {
  case list.at(map.inner, position) {
    Ok(None) -> position
    Ok(Some(_e)) -> {
      case position {
        position if position == last_position -> -1
        0 -> find_gap(map, last_position, list.length(map.inner) - 1)
        position -> find_gap(map, last_position, position - 1)
      }
    }
    _ -> -1
  }
}

fn rehash(map: Map(value), new_size: Int) -> Result(Map(value), MapError) {
  list.fold_until(map.inner, Ok(new_with_size(new_size)), fn(new_map, el) {
    case el {
      Some(entry) ->
        Stop({
          case new_map {
            Ok(m) -> put(m, entry.key, entry.value)
            _ -> Error(RehashError)
          }
        })
      None -> Continue(new_map)
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
