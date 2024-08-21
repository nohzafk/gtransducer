# transducer

[![Package Version](https://img.shields.io/hexpm/v/gtransducer)](https://hex.pm/packages/gtransducer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gtransducer/)

A Gleam library for composable algorithmic transformations.

## Usage

```sh
gleam add gtransducer
```

## Features

Efficient: Processes data in a single pass

- `mapping`: Transform each element in a collection
- `filtering`: Select elements from a collection based on a predicate
- `compose`: Combine multiple transducers into a single operation
- `reduce`: Process data with a transducer and custom reducer function
- `parallel_reduce`: Process data in parallel with a transducer

## Examples

### Using `reduce`

```gleam
import gtransducer.{compose, filtering, mapping}
import gleam/int

let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
let transducer = compose(
  mapping(fn(x) { x * 2 }),
  filtering(fn(x) { int.remainder(x, 4) == Ok(0) })
)

gtransducer.reduce(data, 0, transducer, fn(acc, x) { acc + x })
// result: 60

gtransducer.reduce(data, [], transducer, fn(acc, x) { [x, ..acc] }) |> list.reverse()
// result: [4, 8, 12, 16, 20]
```

### Using `parallel_reduce`

```gleam
import gtransducer.{compose, filtering, mapping}
import gleam/int
import gleam/list

let data = list.range(1, 1_000_000)
let transducer = compose(
  mapping(fn(x) { x * 2 }),
  filtering(fn(x) { int.remainder(x, 4) == Ok(0) })
)

let result = gtransducer.parallel_reduce(
  data: data,
  initial: 0,
  transducer: transducer,
  reducer: fn(acc, x) { acc + x },
  combiner: fn(a, b) { a + b },
  neutral_element: fn() { 0 },
  num_workers: 4
)
// result: sum of all elements that pass the transducer
```

`parallel_reduce` allows processing large datasets in parallel, potentially improving performance on multi-core systems. It splits the input data into chunks, processes each chunk with a separate worker, and then combines the results.


In `parallel_reduce`, `initial` and `neutral_element` serve different purposes:

1. `initial`: This is the starting value for the overall reduction. It's used only once, at the very end of the parallel reduction process. After all parallel computations are done and their results are combined, `initial` is combined with the final result.

2. `neutral_element`: This function returns the starting value for each individual worker's reduction. It's called for each worker to provide an initial value for processing its chunk of data. The neutral element should be an identity value for the `combiner` function.

The process works like this:

1. The data is split into chunks.
2. For each chunk:
   - A worker is started.
   - The worker calls `neutral_element()` to get its starting value.
   - The worker processes its chunk using `reduce` with the transducer and the neutral element as the initial value.
3. The results from all workers are collected.
4. These results are combined using the `combiner` function, starting with the `initial` value.

This approach allows you to have a meaningful initial value for the overall computation (`initial`), while still enabling efficient parallel processing (`neutral_element`).

For example, if you're summing numbers, `initial` might be 0 or some pre-existing sum, while `neutral_element` would always return 0. If you're collecting results into a list, `initial` might be an existing list to prepend to, while `neutral_element` would return an empty list.


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

This project is licensed under the MIT License.
