Jpegoptim
=========

**Jpegoptim** provides Ruby interface to the [`jpegoptim`][1] tool. 
Some examples follow: (for details, see module documentation)

```ruby
require "jpegoptim"

Jpegoptim.available?    # will return true (or false)

files = ["foo.jpg", "empty.jpg", "nonexist.jpg"]
options = { :preserve => true, :strip => :all }

Jpegoptim.optimize(files, options)

# will run 'jpegoptim --strip-all --preserve foo.jpg bar.jpg empty.jpg'
# and then will return for example: 
#   '#<struct Jpegoptim::Result succeed={"foo.jpg => -22.1}},
#   errors=[["empty.jpg", "ERROR"]]>'
```
    
It can be also run asynchronously by non-blocking way (with [`eventmachine`][4]) 
simply by giving block with one argument to `#optimize`. See documentation. 
    
### Call Result

Result contains members `:success` and `:errors`. Sucess member contains 
hash of successfully optimized files with ratio as value. Zero or 
positive percent ratio means the same as file has been `skipped`. It's 
negative number against the number reported by `jpegoptim` so it means 
new size against the old size.

Errors contains array with pairs where first member of the pair is 
filename and second the message. First one can be null if message isn't
strictly associated with file. As unassociated messages are considered 
all errors beginning by the `jpegoptim:` string although these are 
usually written to the error output so generaly unhandled and written 
out to error output of the application instead.

Be warn, unassociated message is `can't open` error too, so double 
check, file exists if desired result is critical.

### Unsupported Options

Destination directory option isn't supported, so you are purely 
responsible for optimizing files on the right place. Use Ruby methods 
for it.

Copyright
---------

Copyright &copy; 2011 &ndash; 2015 [Martin Poljak][3]. See `LICENSE.txt` for
further details.

[1]: http://www.kokkonen.net/tjko/projects.html
[2]: http://github.com/martinkozak/jpegoptim/issues
[3]: http://www.martinpoljak.net/
[4]: http://rubyeventmachine.com/
