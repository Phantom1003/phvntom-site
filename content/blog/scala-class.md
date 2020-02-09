# Scala: Class vs Case Class

## What is Class
Suppose we want to implement the addition of two rational numbers.
```scala
def addRationalNumerator(n1: Int, d1: Int, n2: Int, d2: Int): Int
def addRationalDenominator(n1: Int, d1: Int, n2: Int, d2: Int): Int
```
It would be difficult to manage all these numerators and denominators!

A better choice is to combine the numerator and denominator of a rational number in a data structure by defining a class:
```scala
class Rational(x: Int, y: Int) {
  def numer = x
  def denom = y
}
```
In Scala, a class implicitly introduces a constructor. This one is called `the primary constructor` of the class.
- takes the parameters of the class
- executes all statements in the class body (such as the require a couple of slides back).

Scala also allows the declaration of auxiliary constructors.These are methods named `this`:
```scala
class Rational(x: Int, y: Int) {
  def this(x: Int) = this(x, 1)
}
```

### OBJECTS
We call the elements of a class type objects.

We create an object by prefixing an application of the constructor of the class with the operator `new`.
```scala
val num = new Rational(1, 2) 
// x: Rational = Rational@2abe0e27
num.numer // 1
num.x 
// error: value x is not a member of Rational
```
### METHODS
One can go further and also package functions operating on a data abstraction in the data abstraction itself. Such functions are called methods.
```scala
class Rational(x: Int, y: Int) {
  private def gcd(a: Int, b: Int): Int = if (b == 0) a else gcd(b, a % b)
  private val g = gcd(x, y)
  def numer = x / g
  def denom = y / g
  def add(r: Rational) =
    new Rational(numer * r.denom + r.numer * denom, denom * r.denom)
  def + (r: Rational) =
    new Rational( numer * r.denom + r.numer * denom, denom * r.denom)
  def less(that: Rational) =
  this.numer * that.denom < that.numer * this.denom
  override def toString = numer + "/" + denom
}
```
This can be advantageous if it is expected that the functions numer and denom are called infrequently.
```scala
class Rational(x: Int, y: Int) {
  private def gcd(a: Int, b: Int): Int = if (b == 0) a else gcd(b, a % b)
  val numer = x / gcd(x, y)
  val denom = y / gcd(x, y)
}
```
This can be advantageous if the functions numer and denom are called often.

### PRECONDITIONS
```scala
class precond(x: Int, y: Int) {
  require(y > 0, "[!]requirement failed")
  assert(x > 0, "[!]assertion failed")
}
// Not Neccessary in Class
```
Both require and assert false will also throw an exception, but it's a different one: `AssertionError` for assert, `IllegalArgumentException` for require. This reflects a difference in intent:  
require is used to enforce a precondition on the caller of a function.
assert is used as to check the code of the function itself.

### ABSTRACT CLASSES
Abstract classes can contain members which are missing an implementation (in our case, incl and contains).

Consequently, no instances of an abstract class can be created with the operator new.

```scala
abstract class IntSet {
  def incl(x: Int): IntSet
  def contains(x: Int): Boolean
}

class Empty extends IntSet {
  def contains(x: Int): Boolean = false
  def incl(x: Int): IntSet = new NonEmpty(x, new Empty, new Empty)
}

class NonEmpty(elem: Int, left: IntSet, right: IntSet) extends IntSet {

  def contains(x: Int): Boolean =
    if (x < elem) left contains x
    else if (x > elem) right contains x
    else true

  def incl(x: Int): IntSet =
    if (x < elem) new NonEmpty(elem, left incl x, right)
    else if (x > elem) new NonEmpty(elem, left, right incl x)
    else this
}
```

`IntSet` is called the **superclass** of `Empty` and `NonEmpty`.

`Empty` and `NonEmpty` are **subclasses** of `IntSet`.

In Scala, any user-defined class extends another class.

If no superclass is given, the standard class `Object` in the Java package `java.lang` is assumed.

The **direct** or **indirect** **superclasses** of a class C are called base classes of C.

**So, the base classes of NonEmpty are IntSet and Object.**

It may seem overkill to have the user create many instances of it, since there is really only a single empty IntSet. We can express this case better with an object definition:
```scala
object Empty extends IntSet {
  def contains(x: Int): Boolean = false
  def incl(x: Int): IntSet = new NonEmpty(x, Empty, Empty)
}
```
No other Empty instances can be created. Singleton objects are values, so Empty **evaluates to itself**.

## TRAITS
In Scala, a class can only have one superclass. But what if a class has several natural supertypes to which it conforms or from which it wants to inherit code?

A `trait` is declared like an abstract class, just with trait instead of abstract class.
``` scala
trait Planar {
  def height: Int
  def width: Int
  def surface = height * width
}
```
Classes, objects and traits can inherit from at `most one class` but `arbitrary many traits`:
``` scala
class Square extends Shape with Planar with Movable …
```
**On the other hand, traits cannot have (value) parameters, only classes can.**

## EQUIVALENCE
In Scala, two instance of a same class with same args are different.
```scala
val x = new Rational(1,2)
val y = new Rational(1,2)
x == y // false
val y = x
x == y // true
```

## What is Case Class
Programs are systems that process information. Therefore, programming languages provide ways to model the domain of a program.

We use a *note* model to aggregate several data and express this in Scala by using a case class definition:
```scala
case class Note( name: String, duration: String, octave: Int)

val c3 = Note("C", "Quarter", 3)
c3.name // C
```

And we know that musical symbols can be either notes or rests (but nothing else). So, we want to introduce the concept of symbol, as something that can be embodied by a fixed set of alternatives: *a note or rest*. We can express this in Scala using a sealed trait definition:
```scala
sealed trait Symbol
case class Note(name: String, duration: String, octave: Int) extends Symbol
case class Rest(duration: String) extends Symbol
```

### PATTERN MATCHING
```scala
def symbolDuration(symbol: Symbol): String =
  symbol match {
    case Note(name, duration, octave) => duration
    case Rest(duration) => duration
  }
```

### EQUALS
It is worth noting that, since the purpose of case classes is to aggregate values, comparing case class instances compares their values:
```scala
case class Note(name: String, duration: String, octave: Int)
val c3 = Note("C", "Quarter", 3)
val otherC3 = Note("C", "Quarter", 3)
val f3 = Note("F", "Quarter", 3)
(c3 == otherC3) // true
(c3 == f3) // true
```

### ENUMERATIONS
Our above definition of the Note type allows users to create instances with invalid names and durations:
```scala
val invalidNote = Note("not a name", "not a duration", 3)
```
If we want to restrict the space of the possible note names and durations to a set of fixed alternatives, we can express the fact that note names are a fixed set of alternatives by using a sealed trait, but in contrast to the previous example alternatives are not case classes because they aggregate no information:
```scala
sealed trait NoteName
case object A extends NoteName
case object A(name: String) extends NoteName
// error: traits or objects may not have parameters
```

## Relationship between Classes and Case Classes
### CREATION AND MANIPULATION
```scala
class BankAccount {

  private var balance = 0

  def deposit(amount: Int): Unit = {
    if (amount > 0) balance = balance + amount
  }

  def withdraw(amount: Int): Int =
    if (0 < amount && amount <= balance) {
      balance = balance - amount
      balance
    } else throw new Error("insufficient funds")
}

case class Note(name: String, duration: String, octave: Int)

val aliceAccount = new BankAccount
val c3 = Note("C", "Quarter", 3)
c3.name // C
```
We see that creating a class instance requires the keyword new, whereas this is not required for case classes.

Also, we see that the case class constructor parameters are promoted to members, whereas this is not the case with regular classes.

## EQUALITY
```scala
val aliceAccount = new BankAccount
val bobAccount = new BankAccount

aliceAccount == bobAccount // false 


val c3 = Note("C", "Quarter", 3)
val cThree = Note("C", "Quarter", 3)

c3 == cThree // true 
```
In the above example, the same definitions of bank accounts lead to different values, whereas the same definitions of notes lead to equal values.

As we have seen in the previous sections, stateful classes introduce a notion of identity that does not exist in case classes. Indeed, the value of BankAccount can change over time whereas the value of a Note is immutable.

In Scala, by default, comparing objects will compare their identity, but in the case of case class instances, the equality is redefined to compare the values of the aggregated information.

### PATTERN MATCHING
We saw how pattern matching can be used to extract information from a case class instance:
```scala
c3 match {
  case Note(name, duration, octave) => s"The duration of c3 is $duration"
}
```
By default, pattern matching does not work with regular classes.

### EXTENSIBILITY
A class can extend another class, whereas a case class can not extend another case class (because it would not be possible to correctly implement their equality).

### CASE CLASSES ENCODING
We saw the main differences between classes and case classes.

It turns out that case classes are just a special case of classes, whose purpose is to aggregate several values into a single value.

The Scala language provides explicit support for this use case because it is very common in practice.

So, when we define a case class, the Scala compiler defines a class enhanced with some more methods and a companion object.

For instance, the following case class definition:

```scala
case class Note(name: String, duration: String, octave: Int)
```
Expands to the following class definition:
```scala
class Note(_name: String, _duration: String, _octave: Int) extends Serializable {

  // Constructor parameters are promoted to members
  val name = _name
  val duration = _duration
  val octave = _octave

  // Equality redefinition
  override def equals(other: Any): Boolean = other match {
    case that: Note =>
      (that canEqual this) &&
        name == that.name &&
        duration == that.duration &&
        octave == that.octave
    case _ => false
  }

  def canEqual(other: Any): Boolean = other.isInstanceOf[Note]

  // Java hashCode redefinition according to equality
  override def hashCode(): Int = {
    val state = Seq(name, duration, octave)
    state.map(_.hashCode()).foldLeft(0)((a, b) => 31 * a + b)
  }

  // toString redefinition to return the value of an instance instead of its memory addres
  override def toString = s"Note($name,$duration,$octave)"

  // Create a copy of a case class, with potentially modified field values
  def copy(name: String = name, duration: String = duration, octave: Int = octave): Note =
    new Note(name, duration, octave)
}

object Note {

  // Constructor that allows the omission of the `new` keyword
  def apply(name: String, duration: String, octave: Int): Note =
    new Note(name, duration, octave)

  // Extractor for pattern matching
  def unapply(note: Note): Option[(String, String, Int)] =
    if (note eq null) None
    else Some((note.name, note.duration, note.octave))
}
```















### Reference
* https://www.scala-exercises.org/scala_tutorial/object_oriented_programming
* https://www.scala-exercises.org/scala_tutorial/structuring_information

* https://www.scala-exercises.org/scala_tutorial/classes_vs_case_classes