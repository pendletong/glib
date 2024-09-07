import gleam/int
import gleam/io
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleeunit/should
import glib/fraction.{Fraction}

pub fn new_test() {
  fraction.new(0, 1)
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.new(0, 2)
  |> should.be_ok
  |> should.equal(Fraction(0, 2))

  fraction.new(-1, 1)
  |> should.be_ok
  |> should.equal(Fraction(-1, 1))

  fraction.new(2, 1)
  |> should.be_ok
  |> should.equal(Fraction(2, 1))

  fraction.new(37, 444)
  |> should.be_ok
  |> should.equal(Fraction(37, 444))

  fraction.new(22, 7)
  |> should.be_ok
  |> should.equal(Fraction(22, 7))

  fraction.new(-5, 8)
  |> should.be_ok
  |> should.equal(Fraction(-5, 8))

  fraction.new(3, -4)
  |> should.be_ok
  |> should.equal(Fraction(-3, 4))

  fraction.new(-2, -7)
  |> should.be_ok
  |> should.equal(Fraction(2, 7))

  fraction.new(1, 0)
  |> should.be_error
  fraction.new(-5, 0)
  |> should.be_error

  fraction.new(1, -2_147_483_648)
  |> should.be_error
}

pub fn new2_test() {
  fraction.new2(0, 0, 1)
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.new2(5, 0, 2)
  |> should.be_ok
  |> should.equal(Fraction(10, 2))

  fraction.new2(0, 3, 4)
  |> should.be_ok
  |> should.equal(Fraction(3, 4))

  fraction.new2(1, 1, 4)
  |> should.be_ok
  |> should.equal(Fraction(5, 4))

  fraction.new2(2, -1, 2)
  |> should.be_error
  fraction.new2(2, 1, -2)
  |> should.be_error

  fraction.new2(-2, 1, 2)
  |> should.be_ok
  |> should.equal(Fraction(-5, 2))

  fraction.new2(2, 1, 0)
  |> should.be_error
  fraction.new2(0, 1, 0)
  |> should.be_error
  fraction.new2(-1, 1, 0)
  |> should.be_error
  fraction.new2(2_147_483_647, 1, 2)
  |> should.be_error
  fraction.new2(-2_147_483_647, 1, 2)
  |> should.be_error

  fraction.new2(-1, 0, 2_147_483_647)
  |> should.be_ok
  |> should.equal(Fraction(-2_147_483_647, 2_147_483_647))

  fraction.new2(0, 1, -2_147_483_648)
  |> should.be_error
  fraction.new2(1, 1, 2_147_483_647)
  |> should.be_error
  fraction.new2(-1, 2, 2_147_483_647)
  |> should.be_error
}

pub fn from_float_test() {
  fraction.from_float(0.0)
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.from_float(1.0)
  |> should.be_ok
  |> should.equal(Fraction(1, 1))

  fraction.from_float(0.5)
  |> should.be_ok
  |> should.equal(Fraction(1, 2))

  fraction.from_float(0.75)
  |> should.be_ok
  |> should.equal(Fraction(3, 4))

  fraction.from_float(-0.3125)
  |> should.be_ok
  |> should.equal(Fraction(-5, 16))

  fraction.from_float(2.5)
  |> should.be_ok
  |> should.equal(Fraction(5, 2))

  fraction.from_float(0.33333)
  |> should.be_ok
  |> should.equal(Fraction(1, 3))

  fraction.from_float(-0.16666)
  |> should.be_ok
  |> should.equal(Fraction(-1, 6))

  fraction.from_float(1.0 /. 10_001.0)
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.from_float(2_147_483_648.0)
  |> should.be_error

  fraction.from_float(-2_147_483_649.0)
  |> should.be_error

  list.range(1, 100)
  |> list.each(fn(i) {
    list.range(1, i)
    |> list.each(fn(j) {
      let f1 = fraction.from_float(int.to_float(j) /. int.to_float(i))
      let f2 = fraction.reduced_fraction(Fraction(j, i))
      f1 |> should.equal(f2)
    })
  })

  list.range(1001, 10_000)
  |> list.filter(fn(i) { int.modulo({ i - 1 }, 500) == Ok(0) })
  |> list.each(fn(i) {
    list.range(1, i)
    |> list.each(fn(j) {
      let f1 = fraction.from_float(int.to_float(j) /. int.to_float(i))
      let f2 = fraction.reduced_fraction(Fraction(j, i))
      f1 |> should.equal(f2)
    })
  })
}

pub fn from_string_test() {
  fraction.from_string("")
  |> should.be_error
  fraction.from_string("haha")
  |> should.be_error
  fraction.from_string("2147483648")
  |> should.be_error
  fraction.from_string(".")
  |> should.be_error

  fraction.from_string("0")
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.from_string("1")
  |> should.be_ok
  |> should.equal(Fraction(1, 1))

  fraction.from_string("7")
  |> should.be_ok
  |> should.equal(Fraction(7, 1))

  fraction.from_string("0.0")
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.from_string("1.0")
  |> should.be_ok
  |> should.equal(Fraction(1, 1))

  fraction.from_string("0.5")
  |> should.be_ok
  |> should.equal(Fraction(1, 2))

  fraction.from_string("0.75")
  |> should.be_ok
  |> should.equal(Fraction(3, 4))

  fraction.from_string("-0.3125")
  |> should.be_ok
  |> should.equal(Fraction(-5, 16))

  fraction.from_string("2.5")
  |> should.be_ok
  |> should.equal(Fraction(5, 2))

  fraction.from_string("0.33333")
  |> should.be_ok
  |> should.equal(Fraction(1, 3))

  fraction.from_string("-0.16666")
  |> should.be_ok
  |> should.equal(Fraction(-1, 6))

  fraction.from_string("0/1")
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.from_string("1/4")
  |> should.be_ok
  |> should.equal(Fraction(1, 4))

  fraction.from_string("-2/3")
  |> should.be_ok
  |> should.equal(Fraction(-2, 3))

  fraction.from_string("5/4")
  |> should.be_ok
  |> should.equal(Fraction(5, 4))

  fraction.from_string("5/x")
  |> should.be_error
  fraction.from_string("/2")
  |> should.be_error
  fraction.from_string("5/")
  |> should.be_error
  fraction.from_string("/")
  |> should.be_error

  fraction.from_string("0 0/1")
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  fraction.from_string("1 0/1")
  |> should.be_ok
  |> should.equal(Fraction(1, 1))

  fraction.from_string("2 1/4")
  |> should.be_ok
  |> should.equal(Fraction(9, 4))

  fraction.from_string("1 2/3")
  |> should.be_ok
  |> should.equal(Fraction(5, 3))

  fraction.from_string("-2 3/4")
  |> should.be_ok
  |> should.equal(Fraction(-11, 4))

  fraction.from_string("2 3")
  |> should.be_error
  fraction.from_string("x 3")
  |> should.be_error
  fraction.from_string("1 a/3")
  |> should.be_error
  fraction.from_string("3 ")
  |> should.be_error
  fraction.from_string(" 3")
  |> should.be_error
  fraction.from_string(" ")
  |> should.be_error
}

pub fn abs_test() {
  fraction.new(1, 5)
  |> should.be_ok
  |> fraction.abs
  |> should.be_ok
  |> should.equal(Fraction(1, 5))

  fraction.new(-1, 5)
  |> should.be_ok
  |> fraction.abs
  |> should.be_ok
  |> should.equal(Fraction(1, 5))

  fraction.new(2_147_483_647, 1)
  |> should.be_ok
  |> fraction.abs
  |> should.be_ok
  |> should.equal(Fraction(2_147_483_647, 1))

  fraction.new(2_147_483_647, -1)
  |> should.be_ok
  |> fraction.abs
  |> should.be_ok
  |> should.equal(Fraction(2_147_483_647, 1))

  fraction.new(-2_147_483_648, 1)
  |> should.be_ok
  |> fraction.abs
  |> should.be_error
}

pub fn negate_test() {
  fraction.new(1, 5)
  |> should.be_ok
  |> fraction.negate
  |> should.be_ok
  |> should.equal(Fraction(-1, 5))

  fraction.new(-1, 5)
  |> should.be_ok
  |> fraction.negate
  |> should.be_ok
  |> should.equal(Fraction(1, 5))

  fraction.new(2_147_483_646, 2_147_483_647)
  |> should.be_ok
  |> fraction.negate
  |> should.be_ok
  |> should.equal(Fraction(-2_147_483_646, 2_147_483_647))

  fraction.new(-2_147_483_648, 1)
  |> should.be_ok
  |> fraction.negate
  |> should.be_error
}

pub fn add_test() {
  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(1, 5)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(4, 5))

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(2, 5)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(1, 1))

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok

  fraction.add(f1, f1)
  |> should.be_ok
  |> should.equal(Fraction(6, 5))

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(-4, 5)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(-1, 5))

  let f1 =
    fraction.new(2_147_483_647 - 1, 1)
    |> should.be_ok
  let f2 =
    fraction.new(1, 1)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(2_147_483_647, 1))

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(1, 2)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(11, 10))

  let f1 =
    fraction.new(3, 8)
    |> should.be_ok
  let f2 =
    fraction.new(1, 6)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(13, 24))

  let f1 =
    fraction.new(0, 5)
    |> should.be_ok
  let f2 =
    fraction.new(1, 5)
    |> should.be_ok
  let f3 =
    fraction.add(f1, f2)
    |> should.be_ok
  let f4 =
    fraction.add(f1, f2)
    |> should.be_ok
  f3
  |> should.equal(f4)

  let f1 =
    fraction.new(-1, 13 * 13 * 2 * 2)
    |> should.be_ok
  let f2 =
    fraction.new(-2, 13 * 17 * 2)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(-17 - 2 * 13 * 2, 13 * 13 * 17 * 2 * 2))

  let f1 =
    fraction.new(1, 32_768 * 3)
    |> should.be_ok
  let f2 =
    fraction.new(1, 59_049)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(52_451, 1_934_917_632))

  let f1 =
    fraction.new(-2_147_483_648, 3)
    |> should.be_ok
  let f2 =
    fraction.new(1, 3)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(-2_147_483_647, 3))

  let f1 =
    fraction.new(2_147_483_647 - 1, 1)
    |> should.be_ok
  let f2 =
    fraction.new(1, 1)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(2_147_483_647, 1))

  let f1 =
    fraction.new(2_147_483_647, 1)
    |> should.be_ok
  let f2 =
    fraction.new(1, 1)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_error

  let f1 =
    fraction.new(-2_147_483_648, 5)
    |> should.be_ok
  let f2 =
    fraction.new(-1, 5)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_error

  let f1 =
    fraction.new(2_147_483_647, 1)
    |> should.be_ok

  fraction.add(f1, f1)
  |> should.be_error

  let f1 =
    fraction.new(-2_147_483_647, 1)
    |> should.be_ok

  fraction.add(f1, f1)
  |> should.be_error

  let f1 =
    fraction.new(3, 327_680)
    |> should.be_ok
  let f2 =
    fraction.new(2, 59_049)
    |> should.be_ok
  fraction.add(f1, f2)
  |> should.be_error
}

pub fn sub_test() {
  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(1, 5)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(2, 5))

  let f1 =
    fraction.new(7, 5)
    |> should.be_ok
  let f2 =
    fraction.new(2, 5)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(1, 1))

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(3, 5)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(0, 1))

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(-4, 5)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(7, 5))

  let f1 =
    fraction.new(0, 1)
    |> should.be_ok
  let f2 =
    fraction.new(4, 5)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(-4, 5))

  let f1 =
    fraction.new(0, 1)
    |> should.be_ok
  let f2 =
    fraction.new(-4, 5)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(4, 5))

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(1, 2)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(1, 10))

  let f1 =
    fraction.new(1, 5)
    |> should.be_ok
  let f2 =
    fraction.new(0, 1)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(f1)

  let f1 =
    fraction.new(1, 32_768 * 3)
    |> should.be_ok
  let f2 =
    fraction.new(1, 59_049)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(-13_085, 1_934_917_632))

  let f1 =
    fraction.new(-2_147_483_648, 3)
    |> should.be_ok
  let f2 =
    fraction.new(1, 3)
    |> should.be_ok
    |> fraction.negate
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(-2_147_483_648 + 1, 3))

  let f1 =
    fraction.new(2_147_483_647, 1)
    |> should.be_ok
  let f2 =
    fraction.new(1, 1)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_ok
  |> should.equal(Fraction(2_147_483_647 - 1, 1))

  let f1 =
    fraction.new(1, 2_147_483_647)
    |> should.be_ok
  let f2 =
    fraction.new(1, 2_147_483_647 - 1)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_error

  let f1 =
    fraction.new(-2_147_483_648, 5)
    |> should.be_ok
  let f2 =
    fraction.new(1, 5)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_error

  let f1 =
    fraction.new(-2_147_483_648, 1)
    |> should.be_ok
  let f2 =
    fraction.new(1, 1)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_error

  let f1 =
    fraction.new(2_147_483_647, 1)
    |> should.be_ok
  let f2 =
    fraction.new(1, 1)
    |> should.be_ok
    |> fraction.negate
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_error

  let f1 =
    fraction.new(3, 327_680)
    |> should.be_ok
  let f2 =
    fraction.new(2, 59_049)
    |> should.be_ok
  fraction.sub(f1, f2)
  |> should.be_error
}

pub fn compare_test() {
  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  fraction.compare(f1, f1)
  |> should.equal(Eq)

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(2, 5)
    |> should.be_ok
  fraction.compare(f1, f2)
  |> should.equal(Gt)
  fraction.compare(f2, f2)
  |> should.equal(Eq)

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(4, 5)
    |> should.be_ok
  fraction.compare(f1, f2) |> should.equal(Lt)
  fraction.compare(f2, f2) |> should.equal(Eq)

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(3, 5)
    |> should.be_ok
  fraction.compare(f1, f2) |> should.equal(Eq)

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new(6, 10)
    |> should.be_ok
  fraction.compare(f1, f2) |> should.equal(Eq)

  let f1 =
    fraction.new(3, 5)
    |> should.be_ok
  let f2 =
    fraction.new2(-1, 1, 2_147_483_647)
    |> should.be_ok
  fraction.compare(f1, f2) |> should.equal(Gt)
  fraction.compare(f2, f2) |> should.equal(Eq)
}

pub fn conversion_test() {
  let f1 =
    fraction.new2(3, 7, 8)
    |> should.be_ok

  fraction.to_int(f1)
  |> should.equal(3)

  fraction.to_float(f1)
  |> should.equal(3.875)
}

pub fn get_test() {
  let f1 =
    fraction.new2(3, 5, 6)
    |> should.be_ok

  fraction.numerator(f1) |> should.equal(23)
  fraction.denominator(f1) |> should.equal(6)
  fraction.proper_numerator(f1) |> should.equal(5)
  fraction.proper_whole(f1) |> should.equal(3)

  let f1 =
    fraction.new2(-3, 5, 6)
    |> should.be_ok

  fraction.numerator(f1) |> should.equal(-23)
  fraction.denominator(f1) |> should.equal(6)
  fraction.proper_numerator(f1) |> should.equal(5)
  fraction.proper_whole(f1) |> should.equal(-3)

  let f1 =
    fraction.new2(-2_147_483_648, 0, 1)
    |> should.be_ok

  fraction.numerator(f1) |> should.equal(-2_147_483_648)
  fraction.denominator(f1) |> should.equal(1)
  fraction.proper_numerator(f1) |> should.equal(0)
  fraction.proper_whole(f1) |> should.equal(-2_147_483_648)
}

pub fn inverse_test() {
  let f1 =
    fraction.new(10, 30)
    |> should.be_ok

  fraction.inverse(f1)
  |> should.be_ok
  |> should.equal(Fraction(30, 10))

  let f1 =
    fraction.new(102, 20)
    |> should.be_ok

  fraction.inverse(f1)
  |> should.be_ok
  |> should.equal(Fraction(20, 102))

  let f1 =
    fraction.new(-10, 30)
    |> should.be_ok

  fraction.inverse(f1)
  |> should.be_ok
  |> should.equal(Fraction(-30, 10))

  let f1 =
    fraction.new(0, 30)
    |> should.be_ok

  fraction.inverse(f1)
  |> should.be_error

  let f1 =
    fraction.new(-2_147_483_648, 1)
    |> should.be_ok

  fraction.inverse(f1)
  |> should.be_error

  let f1 =
    fraction.new(2_147_483_647, 1)
    |> should.be_ok

  fraction.inverse(f1)
  |> should.be_ok
  |> should.equal(Fraction(1, 2_147_483_647))
}
