import gleam/int
import gleam/list
import gleeunit
import gleeunit/should

import transducer.{compose, filtering, mapping}

pub fn main() {
  gleeunit.main()
}

pub fn mapping_test() {
  let data = [1, 2, 3, 4, 5]
  let double = mapping(fn(x) { x * 2 })
  transducer.fold(data, [], double)
  |> should.equal([2, 4, 6, 8, 10])
}

pub fn filtering_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let even = filtering(fn(x) { int.remainder(x, 2) == Ok(0) })
  transducer.fold(data, [], even)
  |> should.equal([2, 4, 6, 8, 10])
}

pub fn compose_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let transducer =
    compose(
      mapping(fn(x) { x * 2 }),
      filtering(fn(x) { int.remainder(x, 4) == Ok(0) }),
    )
  transducer.fold(data, [], transducer)
  |> should.equal([4, 8, 12, 16, 20])
}

pub fn compose_multiple_test() {
  let data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let transducer =
    compose(
      mapping(fn(x) { x + 1 }),
      compose(filtering(fn(x) { x > 5 }), mapping(fn(x) { x * 2 })),
    )
  transducer.fold(data, [], transducer)
  |> should.equal([12, 14, 16, 18, 20, 22])
}

pub fn empty_list_test() {
  let data = []
  let transducer = compose(mapping(fn(x) { x * 2 }), filtering(fn(x) { x > 5 }))
  let result = list.fold(data, [], transducer(fn(acc, x) { [x, ..acc] }))
  result
  |> should.equal([])
}

pub fn identity_transducer_test() {
  let data = [1, 2, 3, 4, 5]
  let identity = mapping(fn(x) { x })
  let result = list.fold(data, [], identity(fn(acc, x) { [x, ..acc] }))
  result
  |> list.reverse()
  |> should.equal(data)
}
