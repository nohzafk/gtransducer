import gleam/int
import gleam/list
import gleeunit
import gleeunit/should

import transducer.{compose, filtering, mapping}

pub fn main() {
  gleeunit.main()
}

fn accumulate(data, transducer) {
  transducer.reduce(data, [], transducer, fn(acc, x) { [x, ..acc] })
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

  transducer.reduce(data, 0, double, sum)
  |> should.equal(30)
}

pub fn reduce_with_filtering_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let even = filtering(fn(x) { int.remainder(x, 2) == Ok(0) })
  let sum = fn(acc, x) { acc + x }

  transducer.reduce(data, 0, even, sum)
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

  transducer.reduce(data, 0, transducer, sum)
  |> should.equal(60)
}

pub fn reduce_empty_list_test() {
  let data = []
  let double = mapping(fn(x) { x * 2 })
  let sum = fn(acc, x) { acc + x }

  transducer.reduce(data, 0, double, sum)
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
