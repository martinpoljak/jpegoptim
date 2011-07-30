# encoding: utf-8
# (c) 2011 Martin Kozák (martinkozak@martinkozak.net)

require "command-builder"
require "unix/whereis"

##
# The +jpegoptim+ tool command frontend.
# @see http://www.kokkonen.net/tjko/projects.html
#

module Jpegoptim

    ##
    # Holds +jpegoptim+ command.
    #
    
    COMMAND = :jpegoptim
    
    ##
    # Result structure.
    #
    # Contains members +:success+ and +:errors+. Sucess member contains 
    # hash of successfully optimized files with ratio as value. Zero 
    # or positive percent ratio means the same as file has been 
    # +skipped+. It's negative number against the number reported by
    # +jpegoptim+ so it means new size against the old size.
    #
    # Errors contains array with pairs where first member of the pair is
    # filename and second the message. First one can be null if message
    # isn't strictly associated with file. As unassociated messages are 
    # considered all errors beginning by the +jpegoptim:+ string althoug 
    # these are usually written to the error output so generaly 
    # unhandled and written out to error output of the application 
    # instead.
    #
    # Be warn, unassociated message is +can't open+ error too, so double
    # check, file exists if desired result is critical.
    # 
    
    Result = Struct::new(:succeed, :errors)
    
    ##
    # Holds output matchers.
    #
    
    MATCHERS = [
        /(.*)\[(ERROR)\]/,
        /jpegoptim:\s*(.*)/,
        /(.*)\s+\d+x\d+.*\((\-?\d+\.\d+)%\)/
    ]

    ##
    # Checks if +jpegoptim+ is available.
    # @return [Boolean] +true+ if it is, +false+ in otherwise
    #
    
    def self.available?
        return Whereis.available? self::COMMAND 
    end
    
    ##
    # Performs optimizations above file or set of files.
    #
    # Destination directory option isn't supported, so you are purely 
    # responsible for optimizing files on the right place. Use Ruby 
    # methods for it.
    #
    # If block is given, runs +jpegoptim+ asynchronously. In that case, 
    # +em-pipe-run+ file must be already required.
    #
    # @param [String, Array] paths file path or array of paths for optimizing
    # @param [Hash] options options 
    # @param [Proc] block block for giving back the results
    # @option options [Boolean, Symbol] :strip says what informations strip, see +jpegoptim+ documentation, default is +:all+
    # @option options [Boolean] :preserve turns on preserving the timestamps
    # @option options [Integer] :max set maximum image quality factor
    # @option options [Boolean] :debug turn on debugging mode, so command will be put out to the +STDERR+
    # @return [Struct] see {Result}
    #
    
    def self.optimize(paths, options = { }, &block)
    
        # Command
        cmd = CommandBuilder::new(self::COMMAND)
        
        # Strip definition
        strip = options[:strip]
        if strip.nil? or (strip == true)
            strip == :all
        end
        if strip
            cmd << ("strip-" << strip.to_s).to_sym
        end
        
        # Preserve
        if options[:preserve]
            cmd << :preserve
        end
        
        # Max
        if options[:max].kind_of? Integer
            cmd.arg(:max, options[:max].to_i)
        end
        
        # Files
        if paths.kind_of? String
            paths = [paths]
        end
        
        # Runs the command
        cmd << paths
        
        if options[:debug] == true
            STDERR.write cmd.to_s + "\n"
        end
            
            # Blocking
            if block.nil?
                output = cmd.execute!

                # Parses output
                succeed, errors = __parse_output(output)
                return self::Result::new(succeed, errors)
                
            # Non-blocking
            else
                cmd.execute do |output|
                    succeed, errors = __parse_output(output)
                    block.call(self::Result::new(succeed, errors))
                end
            end
    end
    
    
    private
    
    ##
    # Parses output.
    #
    
    def self.__parse_output(output)
        errors = [ ]
        succeed = { }
        
        output.each_line do |line|
            if m = line.match(self::MATCHERS[0])
                errors << [m[1].strip, m[2]]
            elsif m = line.match(self::MATCHERS[1])
                errors << [nil, m[1]]
            elsif m = line.match(self::MATCHERS[2])
                succeed[m[1]] = m[2].to_f * -1
            end
        end
        
        return [succeed, errors]
    end
end
