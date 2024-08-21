import gleam/erlang/process
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

pub fn reduce(
  data data: List(a),
  initial initial: r,
  transducer transducer: Transducer(a, b, r),
  reducer reducer: fn(r, b) -> r,
) -> r {
  let transformed_reducer = transducer(reducer)
  list.fold(data, initial, transformed_reducer)
}

pub fn parallel_reduce(
  data data: List(a),
  initial initial: r,
  transducer transducer: Transducer(a, b, r),
  reducer reducer: fn(r, b) -> r,
  combiner combiner: fn(r, r) -> r,
  neutral_element neutral_element: fn() -> r,
  num_workers num_workers: Int,
) -> r {
  let chunks = list.chunk(data, fn(_) { num_workers })
  let parent_subject = process.new_subject()

  chunks
  |> list.map(fn(chunk) {
    process.start(linked: True, running: fn() {
      let child_subject = process.new_subject()
      process.send(parent_subject, child_subject)
      let assert Ok(reply) = process.receive(child_subject, 5000)
      let result = reduce(chunk, neutral_element(), transducer, reducer)
      process.send(reply, result)
    })
  })

  chunks
  |> list.map(fn(_) {
    let assert Ok(child_subject) = process.receive(parent_subject, 5000)
    process.call(child_subject, fn(subject) { subject }, 5000)
  })
  // Use initial only in the final combination
  |> list.fold(initial, combiner)
}
