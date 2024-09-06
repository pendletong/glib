import gleam/int
import gleam/io
import gleam/list
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