import gleam/int
import gleam/list
import gleeunit
import gleeunit/should

import gtransducer.{compose, filtering, mapping}

pub fn main() {
  gleeunit.main()
}

fn accumulate(data, transducer) {
  gtransducer.reduce(data, [], transducer, fn(acc, x) { [x, ..acc] })
  |> list.reverse()
}

pub fn mapping_test() {
  let data = [1, 2, 3, 4, 5]
  let double = mapping(fn(x) { x * 2 })
  accumulate(data, double)
  |> should.equal([2, 4, 6, 8, 10])
}

pub fn filtering_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let even = filtering(fn(x) { int.remainder(x, 2) == Ok(0) })
  accumulate(data, even)
  |> should.equal([2, 4, 6, 8, 10])
}

pub fn reduce_test() {
  let data = [1, 2, 3, 4, 5]
  let double = mapping(fn(x) { x * 2 })
  let sum = fn(acc, x) { acc + x }

  gtransducer.reduce(data, 0, double, sum)
  |> should.equal(30)
}

pub fn reduce_with_filtering_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let even = filtering(fn(x) { int.remainder(x, 2) == Ok(0) })
  let sum = fn(acc, x) { acc + x }

  gtransducer.reduce(data, 0, even, sum)
  |> should.equal(30)
}

pub fn reduce_with_compose_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let transducer =
    compose(
      mapping(fn(x) { x * 2 }),
      filtering(fn(x) { int.remainder(x, 4) == Ok(0) }),
    )
  let sum = fn(acc, x) { acc + x }

  gtransducer.reduce(data, 0, transducer, sum)
  |> should.equal(60)
}

pub fn reduce_empty_list_test() {
  let data = []
  let double = mapping(fn(x) { x * 2 })
  let sum = fn(acc, x) { acc + x }

  gtransducer.reduce(data, 0, double, sum)
  |> should.equal(0)
}

pub fn compose_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let transducer =
    compose(
      mapping(fn(x) { x * 2 }),
      filtering(fn(x) { int.remainder(x, 4) == Ok(0) }),
    )
  accumulate(data, transducer)
  |> should.equal([4, 8, 12, 16, 20])
}

pub fn compose_multiple_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let transducer =
    compose(
      mapping(fn(x) { x + 1 }),
      compose(filtering(fn(x) { x > 5 }), mapping(fn(x) { x * 2 })),
    )
  accumulate(data, transducer)
  |> should.equal([12, 14, 16, 18, 20, 22])
}

pub fn parallel_reduce_test() {
  let data = list.range(1, 100)
  let double = mapping(fn(x) { x * 2 })
  let sum = fn(acc, x) { acc + x }
  let combine = fn(a, b) { a + b }
  let initial = 7

  let parallel_result =
    gtransducer.parallel_reduce(
      data: data,
      initial: initial,
      transducer: double,
      reducer: sum,
      combiner: combine,
      neutral_element: fn() { 0 },
      num_workers: 4,
    )

  let sequential_result = gtransducer.reduce(data, initial, double, sum)

  parallel_result
  |> should.equal(sequential_result)

  parallel_result
  |> should.equal(initial + 10_100)
}

pub fn parallel_reduce_compose_test() {
  let data = list.range(1, 1_000_000)

  let t =
    compose(
      mapping(fn(x) { x * 2 }),
      filtering(fn(x) { int.remainder(x, 4) == Ok(0) }),
    )

  let parallel_result =
    gtransducer.parallel_reduce(
      data: data,
      initial: 0,
      transducer: t,
      reducer: fn(acc, x) { acc + x },
      combiner: fn(a, b) { a + b },
      neutral_element: fn() { 0 },
      num_workers: 4,
    )

  let sequential_result =
    gtransducer.reduce(
      data: data,
      initial: 0,
      transducer: t,
      reducer: fn(acc, x) { acc + x },
    )

  parallel_result |> should.equal(sequential_result)
}

pub fn compose_order_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  // Order 1: Filter even numbers, then multiply by 2
  let xform1 =
    compose(
      filtering(fn(x) { int.remainder(x, 2) == Ok(0) }),
      mapping(fn(x) { x * 2 }),
    )

  gtransducer.reduce(data, [], xform1, fn(acc, x) { [x, ..acc] })
  |> should.equal([20, 16, 12, 8, 4])

  // Order 2: Multiply by 2, then filter even numbers
  let xform2 =
    compose(
      mapping(fn(x) { x * 2 }),
      filtering(fn(x) { int.remainder(x, 2) == Ok(0) }),
    )

  gtransducer.reduce(data, [], xform2, fn(acc, x) { [x, ..acc] })
  |> should.equal([20, 18, 16, 14, 12, 10, 8, 6, 4, 2])
}

pub fn example_test() {
  let data = list.range(1, 10)

  // Using list.reduce
  let list_result =
    data
    |> list.filter(fn(x) { x % 2 == 0 })
    |> list.map(fn(x) { x * x })
    |> list.fold(0, fn(acc, x) { acc + x })

  list_result |> should.equal(220)

  // Using transducer.reduce
  let xform = compose(filtering(fn(x) { x % 2 == 0 }), mapping(fn(x) { x * x }))

  let transducer_result =
    gtransducer.reduce(
      data: data,
      initial: 0,
      transducer: xform,
      reducer: fn(acc, x) { acc + x },
    )

  list_result |> should.equal(transducer_result)
}
