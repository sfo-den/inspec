# Internals of FilterTable

If you just want to _use_ FilterTable, see filtertable-usage.md .  Reading this may make you more confused, not less.

## What makes this hard?

The terminology used for many concepts does not help the reader understand what is going on.  Additionally, the ways in which the classes relate is not straightforward.  Finally, variable names within the classes are often re-used ('filter' is a favorite) or are too short to be meaningful (x and c are both used as variable names, in long blocks).

FilterTable was created in 2016 in an attempt to consolidate the pluralization features of several resources.  They each had slightly different featuresets, and were all in the wild, so FilterTable exposes some extensive side-effects to provide those features.

## Where is the code?

The main FilterTable code is in [utils/filter.rb](https://github.com/chef/inspec/blob/master/lib/utils/filter.rb).

Also educational is the unit test for Filtertable, at test/unit/utils/filter_table_test.rb

The file utils/filter_array.rb appears to be unrelated.

## What are the classes involved?

### FilterTable::Factory

This class is responsible for the definition of the filtertable.  It provides the methods that are used by the resource author to configure the filtertable.

FilterTable::Factory initializes three instance variables:
```
  @accessors = []
  @connectors = {}
  @resource = nil
```

### FilterTable::Table

This is the actual innards of the implementation.  The Factory's goal is to configure a Table subclass and attach it to the resource you are authoring.  The table is a container for the raw data your resource provides, and performs filtration services.

### FilterTable::ExceptionCatcher

TODO

## What are the major entry points? (FilterTable::Factory)

A resource class using FilterTable typically will call a sequence similar to this, in the class body:

```
  filter = FilterTable.create
  filter.add_accessor(:entries)
        .add(:exists?) { |x| !x.entries.empty? }
        .add(:thing_ids, field: :thing_id)
  filter.connect(self, :table)
```

Each of those calls supports method chaining.

### create

Returns a blank instance of a FilterTable::Factory.

### add\_accessor

Suggested alternate name: register_chainable_filter_method(:new_method_name)

This simply pushes the provided method name onto the `@accessors` instance variable array.  See "accessor" behavior section below for what this does.

After adding the method name to the array, it returns `self` - the FilterTable::Factory instance - so that method chaining will work.

### add

Suggested alternate name 1: register_property_or_matcher_and_filter_criterion
Suggested alternate name 2: register_connector

This is one of the most confusingly named methods.  `add` requires a symbol (which will be used as a method name _to be added to the resource class_), then also accepts a block and/or additional args.  These things - name, block, and opts - are packed into a simple struct called a Connector. The name stored in the struct will be `opts[:field]` if provided, and the method name if not.

The Connector struct is then appended to the Hash `@connectors`, keyed on the method name provided.  `self` is then returned for method chaining.

#### Behavior when a block is provided

This behavior is implemented by line 256.

If a block is provided, it is turned into a Lambda and used as the method body.

The block will be provided two arguments (though most users only use the first):
1. The FilterTable::Table instance that wraps the raw data.
2. An optional value used as an additional opportunity to filter.

For example, this is common:
```
filter.add(:exists?) { |x| !x.entries.empty? }
```

Here, `x` is the Table instance, which exposes the `entries` method (which returns an array, one entry for each raw data row).

You could also implement a more sophisticated property, which semantically should re-filter the table based on the candidate value, and return the new table.

```
filter.add(:smaller_than) { |table, threshold| table.where { some_field <= threshold } }
```

```
things.smaller_than(12)
```

If you provide _both_ a block and opts, only the block is used, and the options are ignored.

#### Behavior when no block is provided

If you do not provide a block, you _must_ provide a `:field` option (though that does no appear to be enforced). The behavior is to define a method with the name provided, that has a conditional return type. The method body is defined in lines 258-266.

If called without arguments, it returns an array of the values in the raw data for that column.
```
things.thing_ids => [1,2,3,4]
```

If called with an argument, it instead calls `where` passing the name of the field and the argument, effectively filtering.
```
things.thing_ids(2) => FilterTable::Table that only contains a row where thing_id = 2
```

If called with a block, it passes the block to where.
```
things.thing_ids { some_code } => Same as things.where { some_code }
```

POSSIBLE BUG: I think this case is broken; it certainly seems ill-advised.

#### Known Options

You can provide options to `add`, after the desired method name.

##### field

This is the most common option.  It selects an implementation in which the desired method will be defined such that it returns an array of the row values using the specified key.  In other words, this acts as a "column fetcher", like in SQL: "SELECT some_column FROM some_table"

Internally, (line 195-200), a Struct type is created to represent a row of raw data.  The struct's attribute list is taken from the `field` options passed to `add`.

* No checking is performed to see if the field name is actually a column in the raw data (the raw data hasn't been fetched yet, so we can't check).
* You can't have two `add` calls that reference the same field, because the Struct would see that as a duplicate attribute.

POSSIBLE BUG: We could deduplicate the field names when defining the Struct, thus allowing multiple properties to use the same field.

##### type

`type: :simple` has been seen in the wild. When you call the method like `things.thing_ids => Array`, this has the very useful effect of flattening and uniq'ing the returned array.

No other values for `:type` have been seen.

### connect

Suggested alternate name: install_filtertable

This method is called like this:

```
filter.connect(self, :data_fetching_method_name)
```

`filter` is an instance of FilterTable::Factory.  `self` is a reference to the resource class you are authoring. `data_fetching_method_name` is a symbol, the name of a method that will return the actual data to be processed by the FilterTable - as an array of hashes.

Note that 'connect' does not refer to Connectors.

`add` and `add_accessor` did nothing other than add register names for methods that we'd like to have added to the resource class.  No filtering ability is present, nor are the methods defined, at this point.

So, `connect`'s job is to actually install everything.

#### Re-pack the "connectors"

First, on lines 188-192, the list of custom methods ("connectors", registered using the `add` method) are repacked into an array of arrays of two elements - the desired method name and the lambda that will be used as the method body.  The lambda is created by the private method `create_connector`.

TBD: what exactly create_connector does

#### Defines a special Struct type to represent rows in the table

At lines 195-200, a new Struct type is defined, with attributes for each of the known table fields.  The motivation for this struct type is to implement the block-mode behavior of `where`.  Because each struct represents a row, and it has the attributes (accessors) for the fields, block-mode `where` is implemented by instance-evaling against each row as a struct.

Additionally, an instance variable, `@__filter` is defined, with an accessor(!). (That's really weird - double-underscore usually means "intended to be private"). `to_s` is implemented, using `@__filter`, or `super` if not defined.  I guess we then rely on the `Struct` class to stringify?

I think `@__filter` is a trace - a string indicating the filter criteria used to create the table.  I found no location where this per-row trace data was used.

CONFUSING NAME: `@__filter` meaning a trace of criteria operations is very confusing - the word "filter" is very overloaded.

Table fields are determined by listing the `field_name`s of the Connectors.

BUG: this means that any `add` call that uses a block but not options will end up with an attribute in the row Struct.  Thus, `filter.add(:exists?) { ... }` results in a row Struct that includes an attribute named `exists?` which may be undesired.

POSSIBLE MISFEATURE: Defining a Struct for rows means that people who use `entries` (or other data accessors) interact with something unusual.  The simplest possible thing would be an Array of Hashes.  There is likely something relying on this...

#### Subclass FilterTable::Table into an anonymous class

At line 203, create the local var `table`, which refers to an anonymous class that subclasses FilterTable::Table.  The class is opened and two groups of methods are defined.

Lines 204-206 install the "connector" methods, using the names and lambdas determined on line 188.

Line 208-213 define a method, `new_entry`.  Its job is to append a row to the FilterTable::Table as a row Struct, given a plain Hash (presumably as provided by the data fetching method) and a String piece of tracking information (again, confusingly referred to as "filter").

#### Install methods on the resource

Lines 216-232 install the data table accessors and "connector" methods onto the resource that you are authoring.

Line 222-223 collects the names of the methods to define - by agglomerating the names of the data table accessors and "connector" methods.  They are treated the same.

Line 224 uses `send` with a block to call `define_method` on the resource class that you're authoring.  Using a block with `send` is undocumented, but is treated as an implicit argument (per stackoverflow) , so the end result is that the block is used as the body for the new method being defined.

The method body is wrapped in an exception-catching facility that catches skipped or failed resource exceptions and wraps them in a specialized exception catcher class. TBD: understand this better.

Line 226 constructs an instance of the anonymous FilterTable::Table subclass defined at 203.  It passes three args:

1. `self`. TBD: which class is this referring to at this point?
2. The return value of calling the data fetcher method.
3. The string ' with', which is probably informing the criteria stringification. The extra space is intentional, as it follows the resource name: 'my_things with color == :red' might be a result.

And that new FilterTable::Table subclass instance is stored in a local variable, named, confusingly, "filter".

On line 227, we then immediately call a method on that "FilterTable::Table subclass instance". The method name is the same as the one we're defining on the resource - but we're calling it on the Table.  Recall we defined all the "connector" methods on the Table subclass at line 204-206.  The method gets called with any args or block passed, and since it's the last thing, it provides the return value.

VERY WORRISOME THING: So, the Table subclass has methods for the "connectors" (for example, `thing_ids` or `exist?`.  What about the "accessors" - `where` and `entries`?  Are those in the FilterTable::Table class, or method_missing'd?

## What is its behavior? (FilterTable::Table)

Assume that your resource has a method, `fetch_data`, which returns a fixed array:

```
 [
   { id: 1, name: 'Dani', color: 'blue' },
   { id: 2, name: 'Mike', color: 'red' },
   { id: 3, name: 'Erika', color: 'green' },
 ]
```

Assume that you then perform this sequence in your resource class body:
```
filter = FilterTable.create
filter.add_accessor(:entries)
filter.add_accessor(:where)
filter.add(:exists?) { |x| !x.exists.empty? }
filter.add(:names, field: :name)
filter.connect(self, :fetch_data)
```

We know from the above exploration of `connect` that we now have several new methods on the resource class, all of which delegate to the FilterTable::Table implementation.

### FilterTable::Table constructor and internals

Factory calls the FilterTable::Table constructor at 142-144 with three args. Table stores them into instance vars:
 * @resource - this was passed in as `self`; I think this would be the resource class
 * @params - the raw table data.  (confusing name)
 * @filters - This looks to be stringification trace data; the string ' with' was passed in by Factory.

 params and filters get `attr_reader`s.

### `entries` behavior

From usage, I expect entries to return a structure that resembles an array of hashes representing the (filtered) data.

#### A new method `entries` is defined on the resource class

That is performed by Factory#connect line 224.

#### It delegates to FilterTable::Table#entries

This is a real method defined in filter.rb line 120.

It loops over the provided raw data (@params) and builds an array, calling `new_entry` (see Factory 208-213) on each row; also appending a stringification trace to each entry.  The array is returned.

#### `entries` conclusion

Not Surprising: It does behave as expected - an array of hashlike structs representing the table.  I don't know why it adds in the per-row stringification data - I've never seen that used.

Surprising: this is a real method with a concrete implementation.  That means that you can't call `filter.add_accessor` with arbitrary method names - `:entries` means something very specific.

### `where` behavior

From usage, I expect this to take either method params or a block (both of which are magical), perform filtering, and return some object that contains only the filtered rows.

So, what happens when you call `add_accessor(:where)` and then call `resource.where`?

#### A new method `where` is defined on the resource class

That is performed by Factory#connect line 224.

#### It delegates to FilterTable::Table#where

Like `entries`, this is a real implemented method on FilterTable::Table, at line 93.

The method accepts all params as the local var `conditions` which defaults to an empty Hash. A block, if any, is also explicitly assigned the name `block`.

The implementation opens with two guard clauses, both of which will return `self` (which is the FilterTable::Table subclass instance).

MISFEATURE: The first guard clause simply returns the Table if `conditions` is not a Hash.  That would mean that someone called it like: `thing.where(:apples, :bananas, :cantaloupes)`.  That misuse is silently ignored; I think we should probably throw a ResourceFailed or something.

The second guard clause is a sensible degenerate case - return the existing Table if there are no conditions and no block.  So `thing.where` is OK.

Line 97 initializes a local var, `filters`, which again is a stringification tracker.

Line 98 confuses things further.  A local var `table` is initialized to the value of instance var `@params`.  The naming here is poorly chosen - @params is the initial raw data (and it has an attr_reader, no need for the @); and `table` is the new _raw data_ - not a new FilterTable class or instance.

Lines 99-102 loop over the provided Hash `conditions`. It repeatedly downfilters `table` by calling the private method `filter_lines` on it.  `filter_lines` does some syntactic sugaring for common types, Ints and Floats and Regexp matching.  Additionally, the 99-102 loop builds up the stringification tracker, `filter`, by stringifying the field name and target value.

BUG: (Issue 2943) - Lines 99-102 do not validate the names of the provided fields.

Line 104-109 begins work if a filtration block has been provided.  At this point, `table` has been initialized with the raw data, and (if method params were provided) has also been filtered down.

Line 105 filters the rows of the raw data using an odd approach: each row is evaluated using `Array#find_all`, with the block `{ |e| new_entry(e, '').instance_eval(&block) }`  `new_entry` wraps each raw row in a Struct (the `''` indicates we're not trying to save stringification data here).  (Recall that new_entry was defined by `FilterTable::Factory#connect`, line 195). Then the provided block is `instance_eval`'d against the Struct.  Because the Struct was defined with attributes (that is, accessor methods) for each declared field name (from FilterTable::Factory#add), you can use field names in the block, and each row-as-struct will be able to respond.

_That just explained a major spooky side-effect for me._

Lines 106-108 do something with stringification tracing.  TODO.

Finally, at line 111, the FilterTable::Table anonymous subclass is again used to construct a new instance, passing on the resource reference, the newly filtered raw data table, and the newly adjusted stringification tracer.

That new Table instance is returned, and thus `where` allows you to chain.

#### `where` conclusion

Unsurprising: How where works with method params.
Surprising: How where works in block mode, instance_eval'ing against each row-as-Struct.
Surprising: You can use method-mode and block-mode together if you want.
Problematic: Many confusing variable names here.  A lot of clarity could be gained by simple search and replace.
