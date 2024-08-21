import gleam/list

pub type Transducer(a, b, r) =
  fn(fn(r, b) -> r) -> fn(r, a) -> r

pub fn mapping(f: fn(a) -> b) -> Transducer(a, b, r) {
  fn(reducer) { fn(acc, x) { reducer(acc, f(x)) } }
}

pub fn filtering(pred: fn(a) -> Bool) -> Transducer(a, a, r) {
  fn(reducer) {
    fn(acc, x) {
      case pred(x) {
        True -> reducer(acc, x)
        False -> acc
      }
    }
  }
}

pub fn compose(
  t1: Transducer(a, b, r),
  t2: Transducer(b, c, r),
) -> Transducer(a, c, r) {
  fn(reducer) { reducer |> t2 |> t1 }
}

pub fn fold(
  data: List(a),
  initial: List(b),
  transducer: Transducer(a, b, List(b)),
) -> List(b) {
  let reducer = fn(acc: List(b), x: b) -> List(b) { [x, ..acc] }
  let transformed_reducer = transducer(reducer)
  list.fold(data, initial, transformed_reducer)
  |> list.reverse()
}
