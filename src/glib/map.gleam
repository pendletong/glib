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
import gleam/iterator

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
  let #(hash, original_hash) = calc_hash(map.size, key)

  case list.at(map.inner, hash) {
    Ok(Some(e)) if e.key == key -> {
      Map(
        insert_at(map.inner, hash, Some(Entry(key, value))),
        map.size,
        map.load,
        map.num_entries,
      )
    }
    _ -> {
      let #(map, new_hash) = check_capacity(map, original_hash)
      let new_hash = option.unwrap(new_hash, hash)
      let #(position, overwrite) =
        find_gap(map, key, { new_hash + 1 } % map.size, new_hash)
      Map(
        ..map,
        inner: insert_at(map.inner, position, Some(Entry(key, value))),
        num_entries: case overwrite {
          True -> map.num_entries
          False -> map.num_entries + 1
        },
      )
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
  let #(hash, _original_hash) = calc_hash(map.size, key)
  case list.at(map.inner, hash) {
    Ok(None) | Error(Nil) -> None
    Ok(Some(e)) -> {
      case e.key == key {
        True -> Some(e.value)
        False -> {
          find_key(map, key, { hash + 1 } % map.size, hash, ret_value)
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
  let #(hash, _original_hash) = calc_hash(map.size, key)

  case list.at(map.inner, hash) {
    Ok(None) | Error(Nil) -> False
    Ok(Some(e)) -> {
      case e.key == key {
        True -> True
        False -> {
          option.unwrap(
            find_key(map, key, { hash + 1 } % map.size, hash, ret_exists),
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
  let #(hash, _original_hash) = calc_hash(map.size, key)

  case list.at(map.inner, hash) {
    Ok(None) | Error(Nil) -> #(None, map)
    Ok(Some(e)) -> {
      case e.key == key {
        True -> do_remove(map, hash, e.value)
        False -> {
          let item =
            find_key(
              map,
              key,
              { hash + 1 } % map.size,
              hash,
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
  let #(split_left, split_right) = list.split(map_list, at)
  list.concat([
    split_left,
    [entry],
    case split_right {
      [] -> []
      [_, ..right] -> right
    },
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

/// Checks whether the current map contains >= load entries
/// If so return a tuple containing the new resized map and the new hash of the 
/// key we are currently processing
/// Otherwise just return the a tuple containing the original map and None to signify
/// no change to the capacity
fn check_capacity(
  map: Map(value),
  original_hash: Int,
) -> #(Map(value), Option(Int)) {
  case map.num_entries >= { map.size * map.load / 100 } {
    True -> {
      let new_map = optimised_rehash(map, map.size * 2 + 1)
      #(new_map, Some(fix_hash(new_map.size, original_hash)))
    }
    _ -> #(map, None)
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
            0 -> {
              // io.debug("_")
              find_gap(map, key, last_position, map.size - 1)
            }
            position -> {
              // io.debug("+")
              find_gap(map, key, last_position, position - 1)
            }
          }
        }
      }
    }
  }
}

fn at(list: List(v), pos: Int) -> v {
  let assert [r, ..] = list.split(list, pos).1
  r
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
        Some(entry) -> {
          put(new_map, entry.key, entry.value)
        }
        None -> new_map
      }
    },
  )
}

type RehashData(a) {
  RehashData(
    new_map_list: List(Option(Entry(a))),
    duplicates: List(#(#(Int, Int), Entry(a))),
    index: Int,
    count: Int,
  )
}

/// Optimised method of rehashing. Much better than just creating a new
/// map and reinserting everything :P
/// 
/// The algorithm is as follows
/// Construct list of new hash values for all current entries
/// Reverse this list because prepnding is quicker so go from tail of the list
/// Iterate the list
///   If the current index is the same as the new index of the head entry
///     -> If the list is empty then this is the start so add to the new list
///     -> Otherwise add to a duplicates list. This will be processed later
///   Otherwise the new index must be less than the current index. If it is not the
///   next index then insert the correct number of Nones to the head of the list
/// This will result in a list containing the unique entries. Process the duplicates
/// that got built up during the above process in the usual 'put' way
/// (A slight optimisation might be possible here to use the duplicate list while
/// inserting Nones. Basically drain the list instead of outputting nones. The data structures
/// around the none insertion are pretty gnarly so I'll leave that as a future endeavour)
fn optimised_rehash(map: Map(value), new_size: Int) -> Map(value) {
  let entries =
    list.fold(map.inner, [], fn(acc, en) {
      case en {
        Some(entry) -> {
          [#(calc_hash(new_size, entry.key), entry), ..acc]
        }
        None -> acc
      }
    })
    |> list.sort(fn(i1, i2) { int.compare({ i2.0 }.0, { i1.0 }.0) })

  let proc_list =
    list.fold(
      entries,
      RehashData([], [], new_size, 0),
      fn(acc: RehashData(value), en) {
        case acc.index == { en.0 }.0 {
          True -> RehashData(..acc, duplicates: [en, ..acc.duplicates])
          False -> {
            RehashData(
              list.append(
                [Some(en.1), ..list.repeat(None, acc.index - { en.0 }.0 - 1)],
                acc.new_map_list,
              ),
              acc.duplicates,
              { en.0 }.0,
              acc.count + 1,
            )
          }
        }
      },
    )
  let it = case proc_list.index == 0 {
    True -> iterator.empty()
    False -> iterator.range(proc_list.index - 1, 0)
  }
  let res_list =
    iterator.fold(it, proc_list, fn(acc, _en) {
      RehashData(..acc, new_map_list: [None, ..acc.new_map_list])
    })
  res_list.duplicates
  |> list.fold(
    Map(res_list.new_map_list, new_size, map.load, res_list.count),
    fn(acc, en) {
      let entry = en.1
      put(acc, entry.key, entry.value)
    },
  )
}

fn fix_hash(map_size: Int, hash: Int) -> Int {
  {
    hash
    |> int.absolute_value()
  }
  % map_size
}

fn calc_hash(map_size: Int, key: String) -> #(Int, Int) {
  let hash_value = hash.hash(key)
  #(fix_hash(map_size, hash_value), hash_value)
}

pub fn list_size(map: Map(value)) -> Int {
  list.length(map.inner)
}

pub fn full_count(map: Map(value)) -> Int {
  list.fold(map.inner, 0, fn(acc, e) {
    case e {
      None -> acc
      Some(_) -> acc + 1
    }
  })
}
