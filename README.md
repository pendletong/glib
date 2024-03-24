# glib

A collection (eventually) of utilities written solely in Gleam (i.e. no erlang/js dependency)

[![Package Version](https://img.shields.io/hexpm/v/glib)](https://hex.pm/packages/glib)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glib/)

```sh
gleam add glib
```
```gleam
import glib/map

pub fn main() {
  let m = map.new()
  |> map.put("Key1","value")

  io.debug(map.get(m, "Key1"))
  // -> Some("value")
}
```

Further documentation can be found at <https://hexdocs.pm/glib>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
