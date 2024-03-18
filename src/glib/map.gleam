//// Maps are a structure similar to dict in that they map keys to values.
//// Duplicate keys cannot exist and a key can map to at most one value
//// 
//// The Keys are strings, values can be any type but values must be of the same type
//// 
//// Maps are unordered

import gleam/option.{type Option, None, Some}
import gleam/list
import gleam/int
import gleam/float
import gleam/string
import gleam/result
import glib/hash

const default_size = 11

const default_load = 0.75

type Entry(value) {
  Entry(key: String, value: value)
}

pub opaque type Map(value) {
  Map(inner: List(Option(Entry(value))), size: Int, load: Int, num_entries: Int)
}

/// Creates an empty map
/// The size and loading factor are set to the default
/// The size is the starting size for the list that contains the values
/// The loading factor is the value 0 -> 1 that determines when the
/// list is resized. This is the percentage of the backing list that is filled.
/// For example, if the loading factor was 0.5 then when one half of the backing
/// list is populated, the next addition to the Map will trigger a resize to
/// ensure the map has usable space
pub fn new() -> Map(value) {
  new_with_size(default_size)
}

/// Creates an empty map with specified size
/// The loading factor is set to default
pub fn new_with_size(size: Int) -> Map(value) {
  //    glimt.info(log, "Creating Map of size "<>int.to_string(size))
  new_with_size_and_load(size, default_load)
}

/// Creates an empty map with specified size and loading factor
/// load is a value 0->1 (non-inclusive) which specifies a percentage (e.g. 0.5 is 50%)
/// at which point the backing list is resized
/// This should be kept around 0.6-0.8 to avoid either excessive resizing or
/// excessive key hash collisions
pub fn new_with_size_and_load(size: Int, load: Float) -> Map(value) {
  let load = case load >=. 1.0 || load <. 0.0 {
    True -> default_load
    False -> load
  }
  let size = case size < 1 {
    True -> 1
    False -> size
  }
  Map(list.repeat(None, size), size, float.round(load *. 100.0), 0)
}

/// Creates a new empty map with the same sizing/loading properties as the
/// passed map
pub fn clear(previous_map: Map(value)) -> Map(value) {
  new_with_size_and_load(
    previous_map.size,
    int.to_float(previous_map.load) /. 100.0,
  )
}

/// Determines whether the map is empty, i.e. contains no key/values
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> is_empty
/// // -> True
/// ```
/// 
/// ```gleam
/// new() |> put("key", "value") |> is_empty
/// // -> False
/// ```
/// 
pub fn is_empty(map: Map(value)) -> Bool {
  size(map) == 0
}

/// Determines whether size of the map, i.e. the number of key/values
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> size
/// // -> 0
/// ```
/// 
/// ```gleam
/// new() |> put("key", "value") |> size
/// // -> 1
/// ```
/// 
pub fn size(map: Map(value)) -> Int {
  map.num_entries
}

/// Inserts a value into the map with the given key
/// 
/// Will replace value if key already exists
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> put("key", 999) |> to_string(fn(i) { int.to_string(i) })
/// // -> {"key":999}
/// ```
/// 
/// ```gleam
/// new() |> put("key", 999) |> put("key2", 111) |> to_string(fn(i) { int.to_string(i) })
/// // -> {"key":999, "key2":111}
/// ```
/// 
/// ```gleam
/// new() |> put("key", 999) |> put("key", 123) |> to_string(fn(i) { int.to_string(i) })
/// // -> {"key":123}
/// ```
/// 
pub fn put(map: Map(value), key: String, value: value) -> Map(value) {
  let hash = calc_hash(map, key)

  case list.at(map.inner, hash.0) {
    Ok(None) | Error(Nil) ->
      Map(
        insert_at(map.inner, hash.0, Some(Entry(key, value))),
        map.size,
        map.load,
        map.num_entries + 1,
      )
    Ok(Some(e)) -> {
      case e.key == key {
        True -> {
          Map(
            insert_at(map.inner, hash.0, Some(Entry(key, value))),
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

          Map(
            insert_at(map.inner, new_pos.0, Some(Entry(key, value))),
            map.size,
            map.load,
            case new_pos.1 {
              True -> map.num_entries
              False -> map.num_entries + 1
            },
          )
        }
      }
    }
  }
}

/// Retrieves the option wrapped value from the map for the stored key
/// 
/// The key may not exist so then None is returned
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> put("key", "value") |> get("key")
/// // -> Ok("value")
/// ```
/// 
/// ```gleam
/// new() |> put("key", "value") |> get("non-existent")
/// // -> None
/// ```
/// 
pub fn get(map: Map(value), key: String) -> Option(value) {
  let hash = calc_hash(map, key)

  case list.at(map.inner, hash.0) {
    Ok(None) | Error(Nil) -> None
    Ok(Some(e)) -> {
      case e.key == key {
        True -> Some(e.value)
        False -> {
          find_key(map, key, { hash.0 + 1 } % map.size, hash.0, ret_value)
        }
      }
    }
  }
}

/// Returns the existence in the map for the stored key
/// 
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> put("key", "value") |> contains_key("key")
/// // -> True
/// ```
/// 
/// ```gleam
/// new() |> put("key", "value") |> contains_key("non-existent")
/// // -> False
/// ```
/// 
pub fn contains_key(map: Map(value), key: String) -> Bool {
  let hash = calc_hash(map, key)

  case list.at(map.inner, hash.0) {
    Ok(None) | Error(Nil) -> False
    Ok(Some(e)) -> {
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

/// Removes the specified key from the map and returns a tuple containing
/// the removed option wrapped value or None and the altered map without the
/// specified key
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> put("key", "value") |> remove("key")
/// // -> #(Some("value"), {})
/// ```
/// 
/// ```gleam
/// new() |> put("key", "value") |> remove("non-existent")
/// // -> #(None, {"key": "value"})
/// ```
pub fn remove(map: Map(value), key: String) -> #(Option(value), Map(value)) {
  let hash = calc_hash(map, key)

  case list.at(map.inner, hash.0) {
    Ok(None) | Error(Nil) -> #(None, map)
    Ok(Some(e)) -> {
      case e.key == key {
        True -> do_remove(map, hash.0, e.value)
        False -> {
          let item =
            find_key(
              map,
              key,
              { hash.0 + 1 } % map.size,
              hash.0,
              ret_index_and_value,
            )
          case item {
            None -> #(None, map)
            Some(#(index, value)) -> do_remove(map, index, value)
          }
        }
      }
    }
  }
}

/// Returns a list of the keys contained in the map
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> keys
/// // -> []
/// ```
/// 
/// ``` gleam
/// new() |> put("key", "value") |> keys
/// // -> ["key"]
/// ```
/// 
pub fn keys(map: Map(value)) -> List(String) {
  list.filter_map(map.inner, fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(en.key)
    }
  })
}

/// Returns a list of the values contained in the map
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> values
/// // -> []
/// ```
/// 
/// ``` gleam
/// new() |> put("key", "value") |> values
/// // -> ["value"]
/// ```
/// 
pub fn values(map: Map(value)) -> List(value) {
  list.filter_map(map.inner, fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(en.value)
    }
  })
}

/// Returns a list of the tuples #(key, value) contained in the map
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> entries
/// // -> []
/// ```
/// 
/// ``` gleam
/// new() |> put("key", "value") |> entries
/// // -> [#("key", "value")]
/// ```
/// 
pub fn entries(map: Map(value)) -> List(#(String, value)) {
  list.filter_map(map.inner, fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(#(en.key, en.value))
    }
  })
}

/// Returns a string representation of the passed map
/// Requires a value_to_string fn to generate the output
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> to_string(fn(v) { v })
/// // -> {}
/// ```
/// 
/// ```gleam
/// new() |> put("key", "value") |> to_string(fn(v) { v })
/// // -> {"key": "value"}
/// ```
/// 
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
  entry: Option(Entry(value)),
) -> List(Option(Entry(value))) {
  let split_list = list.split(map_list, at)
  list.concat([
    split_list.0,
    [entry],
    result.unwrap(list.rest(split_list.1), []),
  ])
}

fn do_remove(
  map: Map(value),
  index: Int,
  value: value,
) -> #(Option(value), Map(value)) {
  // This just does the same as insert_at but passes a None 'entry'
  // and reduces the num_entries
  let new_map =
    Map(
      insert_at(map.inner, index, None),
      map.size,
      map.load,
      map.num_entries - 1,
    )
  #(Some(value), new_map)
}

fn check_capacity(map: Map(value)) -> Map(value) {
  case map.num_entries >= { map.size * map.load / 100 } {
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
  case list.at(map.inner, position) {
    Ok(None) | Error(Nil) -> #(position, False)
    Ok(Some(e)) -> {
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
  case list.at(map.inner, position) {
    Ok(None) | Error(Nil) -> None
    Ok(Some(e)) -> {
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

fn ret_index_and_value(index: Int, value: value) -> #(Int, value) {
  #(index, value)
}

fn rehash(map: Map(value), new_size: Int) -> Map(value) {
  list.fold(
    map.inner,
    new_with_size_and_load(new_size, int.to_float(map.load) /. 100.0),
    fn(new_map, el) {
      case el {
        Some(entry) -> put(new_map, entry.key, entry.value)
        None -> new_map
      }
    },
  )
}

fn fix_hash(map: Map(value), hash: Int) -> Int {
  hash % map.size
  |> int.absolute_value()
}

fn calc_hash(map: Map(value), key: String) -> #(Int, Int) {
  let hash_value = hash.hash(key)
  #(fix_hash(map, hash_value), hash_value)
}

pub fn full_count(map: Map(value)) -> Int {
  list.fold(map.inner, 0, fn(acc, e) {
    case e {
      None -> acc
      Some(_) -> acc + 1
    }
  })
}
