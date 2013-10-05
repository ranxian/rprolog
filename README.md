rprolog
=======

A prolog interpreter's rough implementation in Ruby

## Try it

```
% gem install readline msgpack
% ruby prolog1.rb <prolog program filename>
```
You'll see prompt start with `> ?-`, this is a prompt and then you can execute your query.

## Example
```
ruby prolog1.rb family.pl
> ?- grandmother(alice, paul).
NO.
> ?- grandmother(alice, Who).
{"Who"=>"sam"}
{"Who"=>"peter"}
YES.
```
