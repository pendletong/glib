//// Maps are a structure similar to dict in that they map keys to values.
//// Duplicate keys cannot exist and a key can map to at most one value
//// 
//// The Keys are strings, values can be any type but values must be of the same type
//// 
//// Maps are unordered

import gleam/float
import gleam/int
import gleam/iterator
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glib/hash
import glib/treelist.{type TreeList}

const default_size = 11

const default_load = 0.75

type Entry(value) {
  Entry(key: String, value: value)
}

pub opaque type Map(value) {
  Map(
    inner: TreeList(Option(Entry(value))),
    size: Int,
    load: Int,
    num_entries: Int,
    resizing: Bool,
  )
}

/// Creates an empty map
/// The size and loading factor are set to the default
/// The size is the starting size for the list that contains the values
/// The loading factor is the value 0 -> 1 that determines when the
/// list is resized. This is the percentage of the backing list that is filled.
/// For example, if the loading factor was 0.5 then when one half of the backing
/// list is populated, the next addition to the Map will trigger a resize to
/// ensure the map has usable space
pub fn new() -> Result(Map(value), Nil) {
  new_with_size(default_size)
}

/// Creates an empty map with specified size
/// The loading factor is set to default
pub fn new_with_size(size: Int) -> Result(Map(value), Nil) {
  //    glimt.info(log, "Creating Map of size "<>int.to_string(size))
  new_with_size_and_load(size, default_load)
}

/// Creates an empty map with specified size and loading factor
/// load is a value 0->1 (non-inclusive) which specifies a percentage (e.g. 0.5 is 50%)
/// at which point the backing list is resized
/// This should be kept around 0.6-0.8 to avoid either excessive resizing or
/// excessive key hash collisions
pub fn new_with_size_and_load(size: Int, load: Float) -> Result(Map(value), Nil) {
  let load =
    case load >=. 1.0 || load <. 0.0 {
      True -> default_load
      False -> load
    }
    *. 100.0
  let size = case size < 1 {
    True -> 1
    False -> size
  }
  use backing_list <- result.try(treelist.repeat(None, size))
  Ok(Map(backing_list, size, float.round(load), 0, False))
}

/// Creates a new empty map with the same sizing/loading properties as the
/// passed map
pub fn clear(previous_map: Map(value)) -> Result(Map(value), Nil) {
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

/// Determines the size of the map, i.e. the number of key/values
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
pub fn put(
  map: Map(value),
  key: String,
  value: value,
) -> Result(Map(value), Nil) {
  let #(hash, original_hash) = calc_hash(map.size, key)

  use entry <- result.try(treelist.get(map.inner, hash))
  use #(map, entry_pos, overwrite) <- result.try(case entry {
    Some(e) if e.key == key -> {
      Ok(#(map, hash, True))
    }
    _ -> {
      use #(map, new_hash) <- result.try(check_capacity(map, original_hash))
      let new_hash = option.unwrap(new_hash, hash)

      use #(entry_pos, overwrite) <- result.try(find_gap(
        map,
        key,
        { new_hash + 1 } % map.size,
        new_hash,
      ))
      Ok(#(map, entry_pos, overwrite))
    }
  })
  use inner <- result.try(treelist.set(
    map.inner,
    entry_pos,
    Some(Entry(key, value)),
  ))
  Ok(
    Map(
      ..map,
      inner: inner,
      num_entries: case overwrite {
        True -> map.num_entries
        False -> map.num_entries + 1
      },
    ),
  )
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
pub fn get(map: Map(value), key: String) -> Result(Option(value), Nil) {
  let #(hash, _original_hash) = calc_hash(map.size, key)
  use entry <- result.try(treelist.get(map.inner, hash))
  case entry {
    None -> Ok(None)
    Some(e) -> {
      case e.key == key {
        True -> Ok(Some(e.value))
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

  case treelist.get(map.inner, hash) {
    Error(_) | Ok(None) -> False
    Ok(Some(e)) -> {
      case e.key == key {
        True -> True
        False -> {
          option.unwrap(
            result.unwrap(
              find_key(map, key, { hash + 1 } % map.size, hash, ret_exists),
              None,
            ),
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
pub fn remove(
  map: Map(value),
  key: String,
) -> Result(#(Option(value), Map(value)), Nil) {
  let #(hash, _original_hash) = calc_hash(map.size, key)

  use entry <- result.try(treelist.get(map.inner, hash))
  case entry {
    None -> Ok(#(None, map))
    Some(e) -> {
      case e.key == key {
        True -> do_remove(map, hash, e.value)
        False -> {
          use item <- result.try(find_key(
            map,
            key,
            { hash + 1 } % map.size,
            hash,
            ret_index_and_value,
          ))
          case item {
            None -> Ok(#(None, map))
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
  treelist.to_iterator(map.inner)
  |> iterator.filter_map(fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(en.key)
    }
  })
  |> iterator.to_list
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
  treelist.to_iterator(map.inner)
  |> iterator.filter_map(fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(en.value)
    }
  })
  |> iterator.to_list
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
  treelist.to_iterator(map.inner)
  |> iterator.filter_map(fn(e: Option(Entry(value))) {
    case e {
      None -> Error(Nil)
      Some(en) -> Ok(#(en.key, en.value))
    }
  })
  |> iterator.to_list
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
) -> Result(String, Nil) {
  Ok(
    "{"
    <> string.join(
      treelist.to_iterator(map.inner)
        |> iterator.filter_map(fn(opt) {
          case opt {
            None -> Error(opt)
            Some(e) ->
              Ok("\"" <> e.key <> "\"" <> ":" <> value_to_string(e.value))
          }
        })
        |> iterator.to_list,
      with: ",",
    )
    <> "}",
  )
}

fn do_remove(
  map: Map(value),
  index: Int,
  value: value,
) -> Result(#(Option(value), Map(value)), Nil) {
  // This just does the same as insert_at but passes a None 'entry'
  // and reduces the num_entries
  use entry <- result.try(treelist.set(map.inner, index, None))
  let new_map = Map(..map, inner: entry, num_entries: map.num_entries - 1)
  Ok(#(Some(value), new_map))
}

/// Checks whether the current map contains >= load entries
/// If so return a tuple containing the new resized map and the new hash of the 
/// key we are currently processing
/// Otherwise just return the a tuple containing the original map and None to signify
/// no change to the capacity
fn check_capacity(
  map: Map(value),
  original_hash: Int,
) -> Result(#(Map(value), Option(Int)), Nil) {
  case map.resizing, map.num_entries >= { map.size * map.load / 100 } {
    False, True -> {
      use new_map <- result.try(basic_rehash(map, map.size * 2 + 1))

      Ok(#(
        Map(..new_map, resizing: False),
        Some(fix_hash(new_map.size, original_hash)),
      ))
    }
    _, _ -> Ok(#(map, None))
  }
}

fn find_gap(
  map: Map(value),
  key: String,
  last_position: Int,
  position: Int,
) -> Result(#(Int, Bool), Nil) {
  use entry <- result.try(treelist.get(map.inner, position))
  case entry {
    None -> Ok(#(position, False))
    Some(e) -> {
      case e.key == key {
        True -> Ok(#(position, True))
        False -> {
          case position {
            position if position == last_position -> Ok(#(-1, False))
            0 -> {
              find_gap(map, key, last_position, map.size - 1)
            }
            position -> {
              find_gap(map, key, last_position, position - 1)
            }
          }
        }
      }
    }
  }
}

// Attempt at a faster list index view
// fn at(list: List(v), pos: Int) -> v {
//   let assert [r, ..] = list.split(list, pos).1
//   r
// }

fn find_key(
  map: Map(value),
  key: String,
  last_position: Int,
  position: Int,
  ret_fn: fn(Int, value) -> ret_val,
) -> Result(Option(ret_val), Nil) {
  use entry <- result.try(treelist.get(map.inner, position))
  case entry {
    None -> Ok(None)
    Some(e) -> {
      case e.key == key {
        True -> Ok(Some(ret_fn(position, e.value)))
        False -> {
          case position {
            position if position == last_position -> Ok(None)
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

// Naive rehash routine
// fn rehash(map: Map(value), new_size: Int) -> Map(value) {
//   list.fold(
//     map.inner,
//     new_with_size_and_load(new_size, int.to_float(map.load) /. 100.0),
//     fn(new_map, el) {
//       case el {
//         Some(entry) -> {
//           put(new_map, entry.key, entry.value)
//         }
//         None -> new_map
//       }
//     },
//   )
// }

// type RehashData(a) {
//   RehashData(
//     new_map_list: TreeList(Option(Entry(a))),
//     duplicates: List(#(#(Int, Int), Entry(a))),
//     index: Int,
//     count: Int,
//   )
// }

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
// fn optimised_rehash(map: Map(value), new_size: Int) -> Map(value) {
//   let entries =
//     list.fold(map.inner, [], fn(acc, en) {
//       case en {
//         Some(entry) -> {
//           [#(calc_hash(new_size, entry.key), entry), ..acc]
//         }
//         None -> acc
//       }
//     })
//     |> list.sort(fn(i1, i2) {
//       let #(#(hash1, _), _) = i1
//       let #(#(hash2, _), _) = i2
//       int.compare(hash2, hash1)
//     })

//   let proc_list =
//     list.fold(
//       entries,
//       RehashData([], [], new_size, 0),
//       fn(acc: RehashData(value), en) {
//         let #(#(hash, _), _) = en
//         case acc.index == hash {
//           True -> RehashData(..acc, duplicates: [en, ..acc.duplicates])
//           False -> {
//             RehashData(
//               [
//                 Some(en.1),
//                 ..prepend_none(acc.index - hash - 1, acc.new_map_list)
//               ],
//               acc.duplicates,
//               hash,
//               acc.count + 1,
//             )
//           }
//         }
//       },
//     )
//   let it = case proc_list.index == 0 {
//     True -> iterator.empty()
//     False -> iterator.range(proc_list.index - 1, 0)
//   }
//   let res_list =
//     iterator.fold(it, proc_list, fn(acc, _en) {
//       RehashData(..acc, new_map_list: [None, ..acc.new_map_list])
//     })
//   res_list.duplicates
//   |> list.fold(
//     Map(res_list.new_map_list, new_size, map.load, res_list.count),
//     fn(acc, en) {
//       let entry = en.1
//       put(acc, entry.key, entry.value)
//     },
//   )
// }

fn basic_rehash(map: Map(value), new_size: Int) -> Result(Map(value), Nil) {
  use new_map <- result.try(new_with_size_and_load(
    new_size,
    int.to_float(map.load) /. 100.0,
  ))

  treelist.to_iterator(map.inner)
  |> iterator.try_fold(Map(..new_map, resizing: True), fn(map, entry) {
    case entry {
      Some(entry) -> put(map, entry.key, entry.value)
      None -> Ok(map)
    }
  })
}

fn prepend_none(times: Int, acc: List(Option(Entry(a)))) {
  case times <= 0 {
    True -> acc
    False -> prepend_none(times - 1, [None, ..acc])
  }
}

fn do_repeat(a: a, times: Int, acc: List(a)) -> List(a) {
  case times <= 0 {
    True -> acc
    False -> do_repeat(a, times, [a, ..acc])
  }
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

/// Returns the internal storage size of the map
/// This is mainly for testing use
pub fn list_size(map: Map(value)) -> Int {
  treelist.size(map.inner)
}

/// Returns a count of the number of entries in the map
/// This is used for testing to compare against the cached size
/// Performs a full iteration of the list incrementing for all Some(_)
/// entries
pub fn full_count(map: Map(value)) -> Int {
  treelist.to_iterator(map.inner)
  |> iterator.fold(0, fn(acc, e) {
    case e {
      None -> acc
      Some(_) -> acc + 1
    }
  })
}
