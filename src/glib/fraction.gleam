import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list.{Continue, Stop}
import gleam/order.{Lt}
import gleam/result

pub type Fraction {
  Fraction(numerator: Int, denominator: Int)
}

pub fn new(numerator: Int, denominator: Int) -> Fraction {
  Fraction(numerator, denominator)
}

const max_int_value = 2_147_483_647

const min_int_value = -2_147_483_648

const max_float_value = 1.7976931348623157e308

pub fn from_float(num: Float) -> Result(Fraction, Nil) {
  let sign = case float.compare(num, 0.0) {
    Lt -> -1
    _ -> 1
  }

  let num = float.absolute_value(num)

  use <- bool.guard(
    when: num >. int.to_float(max_int_value),
    return: Error(Nil),
  )

  let whole = float.truncate(num)
  let num = num -. int.to_float(whole)

  construct_fraction(sign, whole, num) |> io.debug
}

type InternalFraction {
  InternalFraction(
    v0: Fraction,
    v1: Fraction,
    a1: Int,
    x1: Float,
    y1: Float,
    delta1: Float,
    delta2: Float,
  )
}

fn construct_fraction(
  sign: Int,
  whole: Int,
  value: Float,
) -> Result(Fraction, Nil) {
  let a =
    InternalFraction(
      v0: Fraction(0, 1),
      v1: Fraction(1, 0),
      a1: 0,
      x1: 1.0,
      y1: value,
      delta1: 0.0,
      delta2: max_float_value,
    )

  let fr =
    iterator.range(0, 24)
    |> iterator.fold_until(a, fn(fr, i) {
      let fr = internal_calc(value, fr)

      case
        fr.delta1 >. fr.delta2
        && fr.v1.denominator <= 10_000
        && fr.v1.denominator > 0
      {
        False -> Stop(fr)
        True -> {
          case i {
            24 -> Stop(InternalFraction(..a, v0: Fraction(-1, -1)))
            _ -> Continue(fr)
          }
        }
      }
    })

  case fr {
    InternalFraction(v0: Fraction(-1, -1), ..) -> Error(Nil)
    _ ->
      reduced_fraction(Fraction(
        sign * { fr.v0.numerator + whole * fr.v0.denominator },
        fr.v0.denominator,
      ))
  }
}

pub fn reduced_fraction(fr: Fraction) -> Result(Fraction, Nil) {
  use <- bool.guard(when: fr.denominator == 0, return: Error(Nil))
  use <- bool.guard(when: fr.numerator == 0, return: Ok(Fraction(0, 1)))

  let fr = case fr.denominator == min_int_value, int.is_even(fr.numerator) {
    True, True -> Fraction(fr.numerator / 2, fr.denominator / 2)
    _, _ -> fr
  }

  use fr <- result.try(case fr.denominator < 0 {
    True -> {
      case fr.numerator == min_int_value, fr.denominator == min_int_value {
        False, False -> Ok(Fraction(-fr.numerator, -fr.denominator))
        _, _ -> Error(Nil)
      }
    }
    False -> Ok(fr)
  })

  let gcd = gcd(fr.numerator, fr.denominator)

  Ok(Fraction(fr.numerator / gcd, fr.denominator / gcd))
}

fn gcd(v1: Int, v2: Int) -> Int {
  1
}

fn internal_calc(value: Float, fr: InternalFraction) -> InternalFraction {
  let a2 =
    float.truncate(case fr.y1 == 0.0 {
      True -> int.to_float(max_int_value)
      False -> fr.x1 /. fr.y1
    })
  let x2 = fr.y1
  let y2 = fr.x1 -. int.to_float(a2) *. fr.y1
  let fr2 =
    Fraction(
      mult_32(fr.a1, fr.v1.numerator) + fr.v0.numerator,
      mult_32(fr.a1, fr.v1.denominator) + fr.v0.denominator,
    )
  let fraction = int.to_float(fr2.numerator) /. int.to_float(fr2.denominator)
  let delta2 = float.absolute_value(value -. fraction)
  InternalFraction(
    v0: fr.v1,
    v1: fr2,
    a1: a2,
    x1: x2,
    y1: y2,
    delta1: fr.delta2,
    delta2: delta2,
  )
}

fn mult_32(x1: Int, x2: Int) -> Int {
  let x3 = x1 * x2
  let x4 = int.bitwise_and(x3, max_int_value)
  x4
  - case int.bitwise_and(x3, max_int_value + 1) {
    0 -> 0
    _ -> max_int_value + 1
  }
}
