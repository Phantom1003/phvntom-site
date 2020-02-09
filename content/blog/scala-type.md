# Scala: Type

## Identifier
When use your own abstract data structure, there is a noticeable difference:

- We write x + y, if x and y are integers, but
- We write r.add(s) if r and s are rational numbers.

In Scala, we can eliminate this difference because operators can be used as identifiers (Since function is a object). Thus, an identifier can be:

- Alphanumeric: starting with a letter, followed by a sequence of letters or numbers
- Symbolic: starting with an operator symbol, followed by other operator symbols.
- The underscore character '_' counts as a letter.
- Alphanumeric identifiers can also end in an underscore, followed by some operator symbols.

Examples of identifiers:

```scala
val asc123 = 1
val asc123_ = 1
val asc_123 = 1
val asc123_+ = 1
val asc_+123 = 1 // error
val +-*/ = 1
val +-*/xxx = 1 // error
val +-*/_ = 1 // error
val +-*/_xxx = 1 // error
val +-_*/ = 1 // error
```
The precedence of an operator is determined by its first character.

The following table lists the characters in increasing order of priority precedence:
```
(all letters)
|
^
&
< >
= !
:
+ -
* / %
(all other special characters)
```

### Tempelate
We can generalize the definition using a type parameter:
```scala
// class
abstract class Set[A] {
  def incl(a: A): Set[A]
  def contains(a: A): Boolean
}
class Empty[A] extends Set[A] {
  …
}
class NonEmpty[A](elem: A, left: Set[A], right: Set[A]) extends Set[A] {
  …
}

// fuction
def singleton[A](elem: A) = new NonEmpty[A](elem, new Empty[A], new Empty[A])
singleton[Int](1)
singleton[Boolean](true)
```
In fact, the Scala compiler can usually deduce the correct type parameters from the value arguments of a function call.

So, in most cases, type parameters can be left out. You could also write:
```scala
singleton(1)
singleton(true)
```
Type parameters are written in square brackets, e.g. [A].

