import gleam/bool
import gleam/float
import gleam/int
import gleam/iterator
import gleam/list.{Continue, Stop}
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/string

pub type Fraction {
  Fraction(numerator: Int, denominator: Int)
}

pub type FractionError {
  ZeroDenominator(a: String)
  Overflow(a: String)
  TooLarge(a: String)
  ConversionError(a: String)
  DivideByZero(a: String)
}

const max_int_value = 2_147_483_647

const min_int_value = -2_147_483_648

const max_float_value = 1.7976931348623157e308

pub fn from_float(num: Float) -> Result(Fraction, FractionError) {
  let sign = case float.compare(num, 0.0) {
    Lt -> -1
    _ -> 1
  }

  let num = float.absolute_value(num)

  use <- bool.guard(
    when: num >. int.to_float(max_int_value),
    return: Error(TooLarge("> 2_147_483_647")),
  )

  let whole = float.truncate(num)
  let num = num -. int.to_float(whole)

  construct_fraction(sign, whole, num)
}

pub fn new(numerator: Int, denominator: Int) -> Result(Fraction, FractionError) {
  use <- bool.guard(
    when: denominator == 0,
    return: Error(ZeroDenominator("Denominator is zero")),
  )
  case denominator < 0 {
    True -> {
      use <- bool.guard(
        when: numerator == min_int_value || denominator == min_int_value,
        return: Error(Overflow("Denominator or Numerator is -2_147_483_648")),
      )
      Ok(Fraction(-numerator, -denominator))
    }
    False -> {
      Ok(Fraction(numerator, denominator))
    }
  }
}

pub fn new2(
  whole: Int,
  numerator: Int,
  denominator: Int,
) -> Result(Fraction, FractionError) {
  use <- bool.guard(
    when: denominator == 0,
    return: Error(ZeroDenominator("Denominator is zero")),
  )
  use <- bool.guard(
    when: denominator < 0,
    return: Error(ZeroDenominator("Denominator is less than zero")),
  )
  use <- bool.guard(
    when: numerator < 0,
    return: Error(ZeroDenominator("Numerator is less than zero")),
  )

  let numerator = case whole < 0 {
    True -> {
      whole * denominator - numerator
    }
    False -> {
      whole * denominator + numerator
    }
  }

  use <- bool.guard(
    when: numerator < min_int_value || numerator > max_int_value,
    return: Error(Overflow("Numerator overflows")),
  )

  Ok(Fraction(numerator, denominator))
}

pub fn from_string(fraction: String) -> Result(Fraction, FractionError) {
  case string.contains(fraction, ".") {
    True -> {
      case float.parse(fraction) {
        Ok(f) -> from_float(f)
        Error(_) -> Error(ConversionError(fraction))
      }
    }
    False -> {
      let parts = string.split(fraction, " ")
      case parts {
        [] -> Ok(Fraction(0, 1))
        [whole, fraction] -> {
          parse_with_whole(whole, fraction)
        }
        [fraction] -> {
          case int.parse(fraction) {
            Ok(f) -> parse_with_whole(int.to_string(f), "0/1")
            Error(_) -> parse_fraction(fraction)
          }
        }
        _ -> Error(ConversionError(fraction))
      }
    }
  }
}

pub fn reduce(fr: Fraction) -> Result(Fraction, FractionError) {
  use <- bool.guard(
    when: fr.denominator == 0,
    return: Error(ZeroDenominator("Denominator is zero")),
  )
  use <- bool.guard(when: fr.numerator == 0, return: Ok(Fraction(0, 1)))

  let fr = case fr.denominator == min_int_value, int.is_even(fr.numerator) {
    True, True -> Fraction(fr.numerator / 2, fr.denominator / 2)
    _, _ -> fr
  }

  use fr <- result.try(case fr.denominator < 0 {
    True -> {
      case fr.numerator == min_int_value, fr.denominator == min_int_value {
        False, False -> Ok(Fraction(-fr.numerator, -fr.denominator))
        _, _ -> Error(Overflow("Denominator or Numerator is -2_147_483_648"))
      }
    }
    False -> Ok(fr)
  })

  use gcd <- result.try(gcd(fr.numerator, fr.denominator))
  Ok(Fraction(fr.numerator / gcd, fr.denominator / gcd))
}

pub fn negate(fr: Fraction) -> Result(Fraction, FractionError) {
  case fr.numerator == min_int_value {
    True -> Error(Overflow("Cannot negate"))
    False -> {
      Ok(Fraction(-fr.numerator, fr.denominator))
    }
  }
}

pub fn abs(fr: Fraction) -> Result(Fraction, FractionError) {
  case fr.numerator >= 0 {
    True -> Ok(fr)
    False -> negate(fr)
  }
}

pub fn add(fr1: Fraction, fr2: Fraction) -> Result(Fraction, FractionError) {
  add_or_sub(fr1, fr2, True)
}

pub fn sub(fr1: Fraction, fr2: Fraction) -> Result(Fraction, FractionError) {
  add_or_sub(fr1, fr2, False)
}

pub fn compare(fr1: Fraction, fr2: Fraction) -> Order {
  use <- bool.guard(when: fr1 == fr2, return: Eq)
  int.compare(fr1.numerator * fr2.denominator, fr1.denominator * fr2.numerator)
}

pub fn equals(fr1: Fraction, fr2: Fraction) -> Bool {
  compare(fr1, fr2) == Eq
}

pub fn to_float(fr1: Fraction) -> Float {
  int.to_float(fr1.numerator) /. int.to_float(fr1.denominator)
}

pub fn to_int(fr1: Fraction) -> Int {
  fr1.numerator / fr1.denominator
}

pub fn numerator(fr1: Fraction) -> Int {
  fr1.numerator
}

pub fn denominator(fr1: Fraction) -> Int {
  fr1.denominator
}

pub fn proper_numerator(fr1: Fraction) -> Int {
  int.absolute_value(fr1.numerator % fr1.denominator)
}

pub fn proper_whole(fr1: Fraction) -> Int {
  to_int(fr1)
}

pub fn inverse(fr1: Fraction) -> Result(Fraction, FractionError) {
  use <- bool.guard(
    when: fr1.numerator == 0,
    return: Error(ZeroDenominator("Inverse")),
  )
  use <- bool.guard(
    when: fr1.numerator == -2_147_483_648,
    return: Error(Overflow("Inverse")),
  )

  case fr1.numerator < 0 {
    True -> Ok(Fraction(-fr1.denominator, -fr1.numerator))
    False -> Ok(Fraction(fr1.denominator, fr1.numerator))
  }
}

pub fn multiply(fr1: Fraction, fr2: Fraction) -> Result(Fraction, FractionError) {
  use <- bool.guard(
    when: fr1.numerator == 0 || fr2.numerator == 0,
    return: Ok(Fraction(0, 1)),
  )

  use gcd1 <- result.try(gcd(fr1.numerator, fr2.denominator))
  use gcd2 <- result.try(gcd(fr2.numerator, fr1.denominator))
  use multnum <- result.try(mul_check(
    fr1.numerator / gcd1,
    fr2.numerator / gcd2,
  ))
  use multden <- result.try(mul_pos(
    fr1.denominator / gcd2,
    fr2.denominator / gcd1,
  ))
  reduce(Fraction(multnum, multden))
}

pub fn divide(fr1: Fraction, fr2: Fraction) -> Result(Fraction, FractionError) {
  use <- bool.guard(when: fr2.numerator == 0, return: Error(DivideByZero("")))

  use fr2_inv <- result.try(inverse(fr2))
  multiply(fr1, fr2_inv)
}

pub fn power(fr1: Fraction, pow: Int) -> Result(Fraction, FractionError) {
  use <- bool.guard(when: pow == 1, return: Ok(fr1))
  use <- bool.guard(when: pow == 0, return: Ok(Fraction(1, 1)))

  case pow < 0 {
    True -> {
      case pow == min_int_value {
        True -> {
          use inv <- result.try(inverse(fr1))
          use sq <- result.try(power(inv, 2))

          let half_pow = pow / 2
          power(sq, -half_pow)
        }
        False -> {
          use inv <- result.try(inverse(fr1))
          power(inv, -pow)
        }
      }
    }
    False -> {
      use fr2 <- result.try(multiply(fr1, fr1))
      use half_pow <- result.try(power(fr2, pow / 2))
      case int.is_even(pow) {
        True -> {
          Ok(half_pow)
        }
        False -> {
          multiply(half_pow, fr1)
        }
      }
    }
  }
}

// Internal functions

fn add_or_sub(
  fr1: Fraction,
  fr2: Fraction,
  add: Bool,
) -> Result(Fraction, FractionError) {
  use <- bool.guard(when: fr1.numerator == 0, return: case add {
    True -> Ok(fr2)
    False -> negate(fr2)
  })
  use <- bool.guard(when: fr2.numerator == 0, return: Ok(fr1))

  use gcd1 <- result.try(gcd(fr1.denominator, fr2.denominator))
  use <- bool.guard(when: gcd1 == 1, return: {
    use uvp <- result.try(mul_check(fr1.numerator, fr2.denominator))
    use upv <- result.try(mul_check(fr2.numerator, fr1.denominator))
    use new_numerator <- result.try(case add {
      True -> add_check(uvp, upv)
      False -> sub_check(uvp, upv)
    })
    use new_denominator <- result.try(mul_pos(fr1.denominator, fr2.denominator))
    Ok(Fraction(new_numerator, new_denominator))
  })

  let uvp = fr1.numerator * { fr2.denominator / gcd1 }
  let upv = fr2.numerator * { fr1.denominator / gcd1 }
  let t = case add {
    True -> uvp + upv
    False -> uvp - upv
  }

  let tmod = t % gcd1

  use gcd2 <- result.try(case tmod == 0 {
    True -> Ok(gcd1)
    False -> gcd(tmod, gcd1)
  })

  let w = t / gcd2

  case w > max_int_value || w < min_int_value {
    True -> Error(Overflow(int.to_string(w) <> " overflows"))
    False -> {
      use new_denominator <- result.try(mul_pos(
        fr1.denominator / gcd1,
        fr2.denominator / gcd2,
      ))
      Ok(Fraction(w, new_denominator))
    }
  }
}

fn mul_check(x: Int, y: Int) -> Result(Int, FractionError) {
  let m = x * y
  case m < min_int_value || m > max_int_value {
    True ->
      Error(Overflow(
        "multiplying " <> int.to_string(x) <> " and " <> int.to_string(y),
      ))
    False -> Ok(m)
  }
}

fn add_check(x: Int, y: Int) -> Result(Int, FractionError) {
  let a = x + y
  case a < min_int_value || a > max_int_value {
    True ->
      Error(Overflow(
        "adding " <> int.to_string(x) <> " and " <> int.to_string(y),
      ))
    False -> Ok(a)
  }
}

fn sub_check(x: Int, y: Int) -> Result(Int, FractionError) {
  let s = x - y
  case s < min_int_value || s > max_int_value {
    True ->
      Error(Overflow(
        "subtracting " <> int.to_string(y) <> " from " <> int.to_string(x),
      ))
    False -> Ok(s)
  }
}

fn mul_pos(x: Int, y: Int) -> Result(Int, FractionError) {
  let m = x * y
  case m > max_int_value {
    True ->
      Error(Overflow(
        "multiplying " <> int.to_string(x) <> " and " <> int.to_string(y),
      ))
    False -> Ok(m)
  }
}

fn parse_with_whole(
  whole: String,
  fraction: String,
) -> Result(Fraction, FractionError) {
  use whole <- result.try(
    int.parse(whole) |> result.replace_error(ConversionError(whole)),
  )

  case string.split(fraction, "/") {
    [numer, denom] -> {
      use numer <- result.try(
        int.parse(numer) |> result.replace_error(ConversionError(numer)),
      )
      use denom <- result.try(
        int.parse(denom) |> result.replace_error(ConversionError(denom)),
      )

      new2(whole, numer, denom)
    }
    _ -> Error(ConversionError(fraction))
  }
}

fn parse_fraction(fraction: String) -> Result(Fraction, FractionError) {
  case string.split(fraction, "/") {
    [numer, denom] -> {
      use numer <- result.try(
        int.parse(numer) |> result.replace_error(ConversionError(numer)),
      )
      use denom <- result.try(
        int.parse(denom) |> result.replace_error(ConversionError(denom)),
      )

      new(numer, denom)
    }
    _ -> Error(ConversionError(fraction))
  }
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
) -> Result(Fraction, FractionError) {
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
    InternalFraction(v0: Fraction(-1, -1), ..) ->
      Error(ConversionError("Too many iterations"))
    _ ->
      reduce(Fraction(
        sign * { fr.v0.numerator + whole * fr.v0.denominator },
        fr.v0.denominator,
      ))
  }
}

fn gcd(u: Int, v: Int) -> Result(Int, FractionError) {
  case u == 0 || v == 0 {
    True -> {
      case u == min_int_value || v == min_int_value {
        True -> Error(Overflow("gcd"))
        False -> Ok(int.absolute_value(u) + int.absolute_value(v))
      }
    }
    False -> {
      case int.absolute_value(u) == 1 || int.absolute_value(v) == 1 {
        True -> Ok(1)
        False -> {
          let u = case u > 0 {
            True -> -u
            False -> u
          }
          let v = case v > 0 {
            True -> -v
            False -> v
          }

          let #(u, v, k) =
            list.range(0, 31)
            |> list.fold_until(#(u, v, 0), fn(vals, k) {
              let #(u, v, _) = vals
              case k == 31 {
                True -> Stop(#(-1, -1, -1))
                False -> {
                  case int.is_odd(u) || int.is_odd(v) {
                    False -> Continue(#(vals.0 / 2, vals.1 / 2, k))
                    True -> Stop(#(u, v, k))
                  }
                }
              }
            })
          use <- bool.guard(
            when: k == -1,
            return: Error(Overflow("gcd iteration")),
          )

          let t = case int.is_odd(u) {
            True -> v
            False -> -u / 2
          }
          let u = reduce_t(t, #(u, v))
          Ok(-u * int.bitwise_shift_left(1, k))
        }
      }
    }
  }
}

fn reduce_t(t: Int, uv: #(Int, Int)) -> Int {
  let #(u, v) = uv
  let t = divide_while_even(t)
  let #(u, v) = case int.compare(t, 0) {
    Gt -> #(-t, v)
    _ -> #(u, t)
  }

  let t = { v - u } / 2

  case t == 0 {
    True -> u
    False -> reduce_t(t, #(u, v))
  }
}

fn divide_while_even(t: Int) -> Int {
  case int.is_even(t) {
    True -> divide_while_even(t / 2)
    False -> t
  }
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
