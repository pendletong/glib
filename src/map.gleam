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
  Map(
    inner: List(Option(Entry(value))),
    size: Int,
    load: Float,
    num_entries: Int,
  )
}

pub fn new() -> Map(value) {
  new_with_size(default_size)
}

pub fn new_with_size(size: Int) -> Map(value) {
  //    glimt.info(log, "Creating Map of size "<>int.to_string(size))
  new_with_size_and_load(size, default_load)
}

pub fn new_with_size_and_load(size: Int, load: Float) -> Map(value) {
  Map(list.repeat(None, size), size, load, 0)
}

pub fn clear(previous_map: Map(value)) -> Map(value) {
  new_with_size_and_load(previous_map.size, previous_map.load)
}

pub fn is_empty(map: Map(value)) -> Bool {
  size(map) == 0
}

pub fn size(map: Map(value)) -> Int {
  map.num_entries
}

pub fn put(map: Map(value), key: String, value: value) -> Map(value) {
  let hash = calc_hash(map, key)

  let entry = result.unwrap(list.at(map.inner, hash.0), None)

  case entry {
    None ->
      Map(
        insert_at(map.inner, hash.0, key, value),
        map.size,
        map.load,
        map.num_entries + 1,
      )
    Some(e) -> {
      case e.key == key {
        True -> {
          Map(
            insert_at(map.inner, hash.0, key, value),
            map.size,
            map.load,
            map.num_entries,
          )
        }
        False -> {
          let map = check_capacity(map)
          let new_hash = fix_hash(map, hash.1)
          let new_pos =
            find_gap(map, key, { new_hash + 1 } % map.size, new_hash)
          let new_size = case new_pos {
            #(_, True) -> map.num_entries + 1
            #(_, False) -> map.num_entries
          }
          Map(
            insert_at(map.inner, new_pos.0, key, value),
            map.size,
            map.load,
            new_size,
          )
        }
      }
    }
  }
}

pub fn get(map: Map(value), key: String) -> Option(value) {
  let hash = calc_hash(map, key)

  let entry = result.unwrap(list.at(map.inner, hash.0), None)

  case entry {
    None -> None
    Some(e) -> {
      case e.key == key {
        True -> Some(e.value)
        False -> {
          find_key(map, key, { hash.0 + 1 } % map.size, hash.0, ret_value)
        }
      }
    }
  }
}

pub fn contains_key(map: Map(value), key: String) -> Bool {
  let hash = calc_hash(map, key)

  let entry = result.unwrap(list.at(map.inner, hash.0), None)

  case entry {
    None -> False
    Some(e) -> {
      case e.key == key {
        True -> True
        False -> {
          option.unwrap(
            find_key(map, key, { hash.0 + 1 } % map.size, hash.0, ret_exists),
            False,
          )
        }
      }
    }
  }
}

pub fn keys(map: Map(value)) -> List(String) {
  list.filter_map(map.inner, fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(en.key)
    }
  })
}

pub fn values(map: Map(value)) -> List(value) {
  list.filter_map(map.inner, fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(en.value)
    }
  })
}

pub fn entries(map: Map(value)) -> List(#(String, value)) {
  list.filter_map(map.inner, fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(#(en.key, en.value))
    }
  })
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
  case
    map.num_entries
    >= {
      int.to_float(map.size)
      |> float.multiply(map.load)
      |> float.round()
    }
  {
    True -> {
      rehash(map, map.size * 2 + 1)
    }
    _ -> map
  }
}

fn find_gap(
  map: Map(value),
  key: String,
  last_position: Int,
  position: Int,
) -> #(Int, Bool) {
  let entry = result.unwrap(list.at(map.inner, position), None)

  case entry {
    None -> #(position, False)
    Some(e) -> {
      case e.key == key {
        True -> #(position, True)
        False -> {
          case position {
            position if position == last_position -> #(-1, False)
            0 -> find_gap(map, key, last_position, map.size - 1)
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
  ret_fn: fn(Int, value) -> ret_val,
) -> Option(ret_val) {
  let entry = result.unwrap(list.at(map.inner, position), None)

  case entry {
    None -> None
    Some(e) -> {
      case e.key == key {
        True -> Some(ret_fn(position, e.value))
        False -> {
          case position {
            position if position == last_position -> None
            0 -> find_key(map, key, last_position, map.size - 1, ret_fn)
            position -> find_key(map, key, last_position, position - 1, ret_fn)
          }
        }
      }
    }
  }
}

fn ret_value(_index: Int, value: value) -> value {
  value
}

fn ret_exists(_index: Int, _value: value) -> Bool {
  True
}

fn rehash(map: Map(value), new_size: Int) -> Map(value) {
  list.fold(
    map.inner,
    new_with_size_and_load(new_size, map.load),
    fn(new_map, el) {
      case el {
        Some(entry) -> put(new_map, entry.key, entry.value)
        None -> new_map
      }
    },
  )
}

pub fn fix_hash(map: Map(value), hash: Int) -> Int {
  hash % map.size
  |> int.absolute_value()
}

pub fn calc_hash(map: Map(value), key: String) -> #(Int, Int) {
  let hash_value = hash.hash(key)
  #(fix_hash(map, hash_value), hash_value)
}

type Entry(value) {
  Entry(key: String, value: value)
}
