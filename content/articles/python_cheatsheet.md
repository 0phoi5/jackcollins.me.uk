---
author:
  name: "Jack Collins"
title: "Python Basics"
subtitle: "jackcollins.me.uk | Platform Engineer & Linux Admin | UK"
date: 2023-04-18T06:00:00+01:00
draft: false
toc: false
images:
tags:
  - cheatsheet
  - python
---

- [Strings](#strings)
- [Advanced Strings](#advstrings)
- [Math](#math)
- [Variables](#vars)
- [TypeError](#intstrerr) ("Can only concatenate str")
- [Functions](#functions)
- [Booleans](#bool) (LT, GT, EQ, AND, OR, NOT)
- [Conditional Statements](#conditionals) (IF, ELIF, ELSE)
- [Lists](#lists)
- [Tuples](#tuples)
- [Looping](#loops) (FOR, WHILE)
- [Importing Modules](#modules)
- [Dictionaries](#dict) (Key:Value Pairs)
- [Sockets](#sockets)

---

## Strings{#strings}

`print(”Hello, world!”)` # Double quotes

`print(’Hello, world!’)` # Single quotes

`print(”This string is “+”awesome!”)` # Concatenate

`print(’\n’)` # New line

`print(variable_name)` # Print a str variable

`print(”””This string runs`

`multiple lines!”””)` # Multi-line string

---

## Advanced Strings{#advstrings}

    my_name = “Roger”

`print(my_name[0])` # Print first letter of variable

`print(my_name[-1])` # Print last letter of variable

    sentence = “This is a sentence”

`print(sentence[:4])` # Print the word ‘This’

`print(sentence[-9:-1])` # Print the word ‘sentence’

`print(sentence.split())` # Splits the variable in to separate Tuple items, with the default delimiter being a space

`sentence_split = sentence.split()` # Splits out the variable sentence_split

`sentence_join = ‘ ‘.join(sentence_split)` # Join together, using a space delimiter, all of the items in Tuple sentence_split

`quote = “He said, ‘give me all your money’”` # An example of the fact that you need to use single quotes and double quotes, similar to other languages, rather than being able to use all single quotes or all double quotes, or…

`quote = “He said, \"give me all your money"\”` # Escape the characters you want inside the string

    too_much_space = “     hello     “

`print(too_much_space.strip())` # Strip white space from string

`print(”A” in “Apple”) # Returns True`

`print(”a” in “Apple”) # Returns False`

    letter = “a”
    word = “Apple”

`print(letter.lower() in word.lower()` # Returns True, because we’ve lowercased everything

    movie = “LOTR”

`print(”My favourite movie is {}.”.format(movie)` # An improvement over using the ‘+’ concatenation method, to add in the variable ‘movie’. Python now knows to place the variable ‘movie’ in to the curly braces.

---

## Math{#math}

`print(50 + 50)` # Addition

`print(50 - 50)` # Subtraction

`print(50 * 50)` # Multiplication

`print(50 / 50)` # Division

`print(50 + 50 - 50 * 50 / 50)` # PEMDAS / BODMAS

`print(50 ** 50)` # Exponents (50 to the 50th power)

`print(50 % 6)` # Modulo (How many times 6 goes in to 50, Modulo is the left over number, so in this case 2)

`print(50 // 6)` # Divison with no leftovers (in this case, rounds to 8)

---

## Variables & Methods{#vars}

    foo = “This is a variable.”

`print(foo)` # Print variable

`print(foo.upper())` # Print variable in uppercase

`print(foo.lower())` # Print variable in lowercase

`print(foo.title())` # Print variable as a Title (capitalises all first letters)

`print(len(foo))` # Prints the character length of a variable

`bar = 30` # Integer (full number)

`foobar = 3.7` # Float (decimals)

`print (int(bar))` # Will print 30

`print(int(foobar))` # Will print 3, as integers are full numbers only, and ***don’t*** round up

`print(type(bar))` # Tells us what class/type a variable is, in this case ‘int’

`print(type(foobar))` # Tells us what class/type a variable is, in this case ‘float’

    age = 18

`age += 1`

`print(age)` # We’ve added 1 to the variable ‘age’, which would give us 19.

    birthday = 1

`age += birthday`

`print(age)` # We’ve added 1 to the variable ‘age’, via the variable ‘birthday’, which would also give us 19.

---

### TypeError: can only concatenate str (not “int”) to str{#intstrerr}

    name = “Bob”  
    age = “23”

`print(”My name is “ + name + “ and I am “ + age + “ years old.”)` # **This will error!** You cannot concatenate a string with an integer ( ‘+’ and the variable ‘age’). Instead, you need to;

`print(”My name is “ + name + “ and I am “ + str(age) + “ years old.”)` # We converted the integer in to a string, now it works!

`print(type(variable_name))` # Confirms what class/type a variable is, such as int, bool or float.

---

## Functions{#functions}

Use indentation correctly!

Note that variables defined ***within*** a function are only available ***within*** the function.

```python
# Define a function
def who_am_i():
  name = “Bob”
  age = “23”
  print(”My name is “ + name + “ and I am “ + str(age) + “ years old.”)
```

`who_am_i()` # Run the above function

`def add_one_hundred(num):` # Define a function with a variable input requirement. When we call the function, we must give it a variable to work with, of the correct type (str,int,float)

`print(num + 100)`

`add_one_hundred(50)` # Runs the above function, adding 100 to 50, giving us 150

`def add(x,y):` # Define a function with two input requirements. When we call the function, we must give it two variables to work with, of the correct type (str,int,float)

`print (x + y)` # Prints the result of x + y

`add(7,10)` # Runs the above function, adding 7 and 10 together, giving us 17

`def multiply(x,y):` # Prints the result of x * y

`return x * y` # Stores the output of the function for later use. The print, below, prints it out, instead of defining print on this line. Maybe we want to do something else with the output, instead of print.

`print(mutiple(7,7))` # Prints the result of 7 * 7

`def square_root(num)` # Prints the Square Root of *num*

`print(num ** .5)` # Variable ‘num’ to the power of 0.5, which is the same as ‘the square root of’

`square_root(64)` # Prints the Square Root of 64

`def nl():
print(’\n’)` # Example of a new line function, saving us time and effort going forwards

`nl()` # Run the 'new line' function we just created above

---

## Boolean Expressions (True / False){#bool}

Note, there is a difference between True and “True”. The first is a Boolean, the second is a String.

    bool_1 = True
    bool_2 = 3*3 == 9
    bool_3 = False
    bool_4 = 3*3 != 9

`print(bool_1,bool_2,bool_3,bool_4)` # Prints ‘True True False False’, because bool_2 is a True statement whereas bool_4 is a False statement.

`print(type(bool_1))` # Tells us what class/type a variable is, in this case ‘bool’

`print(”A” in “Apple”)` # Returns True

`print(”a” in “Apple”)` # Returns False, because the Boolean search is case sensitive

    letter = “a”
    word = “Apple”

`print(letter.lower() in word.lower()` # Returns True, because we’ve lowercased everything

---

## Relational & Boolean Operators (LT, GT, EQ, AND, OR, NOT)

`greater_than = 7 > 5` # More than is an operator. This will return **True**.

`less_than = 5 < 7` # Less than is also an operator. This will also return **True**.

`great_than_equal_to = 7 >= 7` # Returns True

`less_than_equal_to = 7 <= 7` # Returns True

`test_and = (7 > 5) and (5 < 7)` # AND Operator, returns True

`test_and2 = (7 > 5) and (5 > 7)` # AND Operator, returns False

`test_or = (7 > 5) or (5 > 7)` # OR Operator, returns True

`test_not = not True` # False

`test_not2 = not False` # True

---

## Conditional Statements (IF, ELIF, ELSE){#conditionals}

#### Example of an IF statement;

```python
def drink(money):
if money => 2:
  return “You’ve got yourself a drink!”
else
  return “No drink for you!”
```

`print(drink(3))` # Call the ‘drink’ IF statement, set the input variable as 3. Will return Success

`print(drink(1))` # Will return Failure

#### Example of an IF / ELSE statement; 
```python
def alcohol(age,money):
if (age >= 18) and (money >= 5):
  return “You’ve got yourself an alchoholic drink!”
elif (age >= 18) and (money < 5):
  return “Come back with more money!”
elif (age < 18) and (money >= 5)
  return “You’re not old enough to drink! Nice try.”
else:
  return “You’re too poor and too young!”
```

`print(alcohol(21,5))` # Got a drink!

`print(alcohol(18,3))` # Old enough, too poor!

`print(alcohol(17,9))` # Too young!

---

## Lists{#lists}

Everything inside a list is called an Item.

Lists ***always*** live within square brackets [ ].

The first item in a list is ***zero***.

If you define a range, the range stops ***just before the last defined item (up to, not including).***

    movies = [”LOTR”,”The Hobbit”,”Blood and Chrome”]

`print(movies[1])` #Print the ***second*** item from a list. Remember, the first item is 0, not 1.

`print(movies[1:3])` #Print items 1 and 2 from a list. Note that the list stops ***just before the last defined item***, so this doesn’t print item 3, just ***up to 3***.

`print(movies[2:])` #Print item 2 and everything after it

`print(movies[:2])` #Print items 0 and 1 from a list. In a similar way to the [1:3] above, the list stops ***just before the last defined item***, so this doesn’t print item 2, just ***up to 2***.

`print(movies[-1])` #Print the very last item from a list using -1

`print(len(movies))` #Print the number of items in a list

`movies.append(”JAWS”)` #Append/add to the end of a list

`movies.pop()` #Delete the ***last*** item in a list

`movies.pop(1)` #Delete item number 1 from a list

---

## Tuples{#tuples}

Similar to Lists, however Lists are amendable and Tuples are not.  
Tuples are more memory efficient than Lists, so basically if you need a "list" of items but have no requirement to amend it at any point, use a Tuple instead.

They use Parentheses rather than square brackets ( )

    grades = (”a”,”b”,”c”,”d”)

`print(grades[2])`

`print(grades[-1])`

etc.

The same as the above Lists, but without the commands to append, pop or edit in any way.

---

## Looping (FOR, WHILE){#loops}

    vegetables = [”Avacado”,”Cucumber”,”Courgette”,”Pepper”]

```python
for x in vegetables:
print(x)
```

#### Looping until we reach 10, adding 1 to variable 'i' each time

```python
i = 1
while i < 10:
  print(i)
  i += 1    # Prints numbers 1 to 9
```

---

## Importing Modules{#modules}

Python has it’s own library of modules that you can import right off-the-bat. If you want to use a module that isn’t “standard”, you will need to add it to your Python Library.

Imports go directly after the shebang - `#!/usr/bin/python`

`import sys` # Import a module called sys, which is used for system functions and parameters

`print(sys.version)` # Now that we’ve imported the sys module, this command will print the version of Python we’re using

`sys.exit()` # Exit Python cleanly. Requires the sys module.

`from datetime import datetime` # Only import a specific command from a module, instead of the whole thing.

`print(datetime.now())` # Prints the current date and time, using ***just*** the command we imported on the line above.

`from datetime import datetime as dt` # Imports the specific datetime command, from module datetime, but gives it the **alias** of dt

`print(dt.now())` # Prints the current date and time

---

## Dictionaries (Key:Value Pairs){#dict}

Uses curly braces { }

`drinks = {”White Russian”: 7, “Old Fashioned”: 10, “Lemon Drop: 8}` # Drink is the key, price is the value

`print(drinks)`

`employees =  {”Finance”: [”Bob,”Linda”,”Tina”], “IT”: [”Gene”,”Louise”,”Teddy”], “HR”: [”Jimmy Jr.”,”Mort”]}` # Example of multiple Key:Value pairs

`employees[’Legal’] = [”Mr. Frond”]` # Adds a new Key:Value pair to employees

`employees.update({”Sales”: [”Andie”, “Ollie”]})` # Also adds a new Key:Value pair to employees

    drinks = {”White Russian”: 7, “Old Fashioned”: 10, “Lemon Drop": 8}

`drinks[’White Russian’] = 8` # Change the Value of a Key

`print(drinks.get(”White Russian”))` # Pull a specific Key from a dictionary

---

## Sockets{#sockets}

A module called ‘socket’ can be used to establish and work with connections, via IPs and Ports.

Don’t call a file socket.py, it will cause issues because Linux will think it’s an actual socket.

```python
!#/usr/bin/python

import socket

HOST = ‘127.0.0.1’
PORT = ‘1234’

# Define a short variable that refers to to the socket module, socket command,
# with the parameters of AF_INET (IPv4 connection related) and SOCK_STREAM
# (port usage related)
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Using the above, establish a connection to the specified host and port
s.connect((HOST,PORT))
```

---

[Top of page](#top)