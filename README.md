BERT
====

BERT is a BERT (Binary ERlang Term) serialization library for Ruby. It can
encode Ruby objects into BERT format and decode BERT binaries into Ruby
objects.

Instances of the following Ruby classes will be automatically converted to the proper simple BERT type:

* Fixnum
* Float
* Symbol
* Array
* String

Instances of the following Ruby classes will be automatically converted to the proper complex BERT type:

* NilClass
* TrueClass
* FalseClass
* Hash
* Time
* Regexp

Most of these conversions work as expected with one important caveat. Arrays will be converted into tuples. To have an array converted as a list, simply prepend it with `l` like so:

    [:foo, l[1, 2, 3]]

This will be converted as (in Erlang syntax):

    {foo, [1, 2, 3]}


Installation
------------

    gem install bert -s http://gemcutter.org


Usage
-----

    require 'bert'
    
    bert = BERT.encode([:user, {:name => 'TPW', :nick => 'mojombo'}])
    # => "\203h\002d\000\004userh\003d\000\004dictl\000\000\000\002d
          \000\004nickm\000\000\000\amojombojl\000\000\000\002d\000
          \004namem\000\000\000\003TPWj"
    
    BERT.decode(bert)
    # => [:user, {:name => 'TPW', :nick => 'mojombo'}]



Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but
   bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.


Copyright
---------

Copyright (c) 2009 Tom Preston-Werner. See LICENSE for details.
