# transducer

[![Package Version](https://img.shields.io/hexpm/v/transducer)](https://hex.pm/packages/transducer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/transducer/)

A Gleam library for composable algorithmic transformations.

```sh
gleam add transducer
```

## Usage

```gleam
import transducer.{compose, filtering, mapping}
import gleam/int
import gleam/list

pub fn main() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  let transducer = compose(
    mapping(fn(x) { x * 2 }),
    filtering(fn(x) { int.remainder(x, 4) == Ok(0) })
  )

  let result = transducer.fold(data, [], transducer)

  // result: [4, 8, 12, 16, 20]
}
```

## Features

- `mapping`: Transform each element in a collection
- `filtering`: Select elements from a collection based on a predicate
- `compose`: Combine multiple transducers into a single operation
- Efficient: Processes data in a single pass

## Documentation

For detailed documentation and more examples, visit [https://hexdocs.pm/transducer](https://hexdocs.pm/transducer).

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE).
