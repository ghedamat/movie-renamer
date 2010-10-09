#!/usr/bin/ruby

require 'imdb'
require 'highline'
require 'highline/import'
require 'htmlentities'
require 'yaml'

$config = ''
CONFIGFILE = File.join(File.expand_path(ENV['HOME']), '.movie-renamer')
begin 
    $config = YAML.load_file(CONFIGFILE)
rescue
=begin
    raise "\nplease create a .movie-renamer file in your $HOME
example:
filename: /path/to/your/movies/dir"
exit
=end
end

begin
    require 'imdb'
rescue LoadError
    $stderr.print "#{File.basename($0)} requires imdb gem to work\nPlease install it with gem install imdb\n"
    exit
end


if $config['language']
    $language = $config['language']
else
    $language = 'com'
end
# MonkeyPatching is bad..
module Imdb
    
    class Search
        class << self
            def query(query)
                open("http://www.imdb.#{$language}/find?q=#{CGI::escape(query)};s=tt")
            end
        end
    end

    class Movie
    def director
           document.at("h4[text()='Director:'] ~ a").innerHTML.strip.imdb_unescape_html rescue nil
                 document.search("h4[text()^='Director'] ~ a").map { |link| link.innerHTML.strip.imdb_unescape_html } rescue []
     end
     end
          
end

module MovieRenamer
    
    @newpath = 'tmp'
    # TODO insert default
    @folderpath = '' 
    @is_a_test = false
    @renamepattern = '$year - $director - $title'
    MOVIEPATTERN = %r{\.((avi|AVI)|(mkv|MKV)|(mpg|MPG|mpeg|MPEG))$} 
    @input = STDIN
    @output = STDOUT
    
    if $config['filename']
        @renamepattern = $config['filename']
    end

    if $config['savepath']
        @newpath = File.expand_path($config['savepath'])
    end
    
    puts "Renamed movies will be saved in #{@newpath}"

    class Movie
        
        def initialize(filename,opts={})
            opts = { :year => '', :director => '', :title => '', :part => '', :imdb =>''}.merge(opts)
            @year = opts[:year] 
            @director = opts[:director]
            @title = opts[:title]
            @part = opts[:part]
            @imdb = opts[:imdb]
            @filename = filename
        end

        attr_accessor :year, :director, :title, :part, :imdb, :filename

        def == (movie)
           if @year == movie.year and @director == movie.director and @title == movie.title and @part == movie.part and @imdb == movie.imdb and @filename == movie.filename
                return true
           else
                return false
           end
        end

    end

    # setters
    def MovieRenamer::folderPath=(folderpath)
        @folderpath = folderpath
    end

    def MovieRenamer::newpath=(newpath)
        @newpath = newpath
    end

    #test helpers
    def MovieRenamer::input=(input)
        @input = input
    end

    def MovieRenamer::is_a_test=(input)
        @is_a_test = input
    end
    def MovieRenamer::output=(output)
        @output = output
    end

    # returns an array of filenames
    # TODO recursive find?
    def MovieRenamer::findMovies(folder = @folderpath)
        ar = Array.new
        Dir.open(folder) do |dir|
            dir.each do |file|
               if file =~ MOVIEPATTERN
                    ar << file
               end
            end
        end
        return ar.sort
    end

    # reads move filename and tries to initialize a movie object?
    # returns the movie object
    def MovieRenamer::readMovie(filename)
        # TODO insert logic here
        filename = File.basename(filename)
        title =MovieRenamer::titleExtract(File.basename(filename,'.*'))
        return Movie.new(filename,:title => title)
    end

    def MovieRenamer::parseMovie(filename)

        Movie.new(filename)
    end
    # attempt to remove the divx part from a filename
    def MovieRenamer::titleExtract(filename)
        r1 = %r{\s*\[?\(?\s*[dD](i|I)(v|V)(x|X)\s?(-|_)?\s?\w+\s*\)?\]?\s*}
        r2 = %r{\s*\[?\(?\s*(x|X)(v|V)(i|I)(d|D)\s?(-|_)?\s?\w+\s*\)?\]?\s*}
        r3 = %r{\s*\[?\(?\s*(d|D)(v|V)(d|D)(r|R)(i|I)(p|P)\s?(-|_)?\s*\)?\]?\s*}
        r = /(#{r1}|#{r2}|#{r3})/
        filename.gsub!(/-.*/,'')
        filename.gsub(r,'').gsub(/\s?(-|_)\s?/,' ').gsub(/^\s/,'')
    end

    # rename a movie according to movie data 
    # and moves it to the new path in filesystem 
    def MovieRenamer::renameMovie(movie,newpath = @newpath)
        filename = MovieRenamer::newName(movie)
        path = File.expand_path(newpath)
        unless File.exist?(path)
            Dir.mkdir(path)   
        end

        begin 
            require 'fileutils'
            # remove noop
            return FileUtils::mv(File.join(@folderpath,movie.filename), File.join(path,filename), :noop => @is_a_test) ? true : false
        rescue SystemCallError => e
            puts e
        end
    end

    # plays the movie with mplayer
    def MovieRenamer::playMovie(movie)
        
    end

    # edit a movie interactively
    # read the movie
    # print movie info
    # ask movie data
    # rename movie
    # play movie option?
    # XXX add part integer check
    def MovieRenamer::editMovie(filename)
       movie = MovieRenamer::readMovie(filename)  
       MovieRenamer::printMovieInfo(movie)
       ans = askMore "would you like to edit this movie? [ Yes, Skip movie, Quit, Imdb lookup]"# , play] "
       if ans 
           if ans == :info
             ret = MovieRenamer::suggestMovies(movie) 
             if ret.class == nil
               return true  
             end
           elsif ans == :play
             MovieRenamer::playMovie(movie) 
           end


           #if ask "play movie with mplayer?" 
           #     MovieRenamer::playMovie(movie) 
           #end

           # TODO insert imdb suggestions here?

          
           if movie.year == ''
               @output.puts "Enter a year"
               movie.year = @input.gets.chomp.to_i

               @output.puts "Enter a director"
               movie.director = MovieRenamer::sanitizeInput(@input.gets.chomp)

               @output.puts "Enter a title"
               movie.title = MovieRenamer::sanitizeInput(@input.gets.chomp)

               @output.puts "Enter a part (you can leave this blank)"
               movie.part = MovieRenamer::sanitizeInput(@input.gets.chomp)
           end

           MovieRenamer::printMovieInfo(movie)

           ans = ask("is this information correct: Yes, No") do |q|
                q.validate = /^y(es)?|^n(o)?/
           end
           if ans =~/^y(es)?/
               return MovieRenamer::renameMovie(movie)
               #return true
           else
               editMovie(filename) 
           end
       else 
           return true
       end
       
    end

    
    # invoke edit movie on a whole folder
    def MovieRenamer::folderLoop(folder = @folderpath)
        MovieRenamer::findMovies(folder).each do |file|
            MovieRenamer::editMovie(file)
        end
    end

=begin
    # yes or no questioner
    def MovieRenamer::ask(question)
        @output.puts question
        response = @input.gets.chomp
        case response
        when /^y(es)?$/i
            true
        when /^no?$/i
            false
        else 
            puts "I don't understand. Please retry"
            MovieRenamer::ask(question)
        end
    end
=end

    # yes no quit info play questioner
    def MovieRenamer::askMore(question)
        @output.puts question
        response = @input.gets.chomp
        case response
        when /^y(es)?$/i
            true
        when /^s(kip)?$/i
            false
        when /^q(uit)?$/i
            exit 0
        when /^i(mdb)?$/i
            return :info
        when /^p(lay)?$/i
            return :play
        else 
            puts "I don't understand. Please retry"
            askMore(question)
        end
    end

    def MovieRenamer::printMovieInfo(movie)
        say("Movie info is:
<%= color('old filename:', :red) %> #{movie.filename}
<%= color('year:', :red) %> #{movie.year}
<%= color('director:', :red) %> #{movie.director}
<%= color('title:', :red) %> #{movie.title}
<%= color('part:', :red) %> #{movie.part}
<%= color('filename:', :red) %> #{MovieRenamer::newName(movie)}")
        #@output.puts s
        #return s
    end

    # calculates new movie name based on a pattern? XXX
    # TODO change this and include a globalpattern
    def MovieRenamer::newName(movie)
        @renamepattern.gsub!(/\$[a-z]*/) { |m| ;'#{movie.'+m.sub(/\$/,'').chomp+'}' }
        s = eval( '"' + @renamepattern + '"')
        if movie.part =~ /\w/
            s+= " - part#{movie.part.to_i}"
        end
        s += File.extname(movie.filename)
        return s
    end

    
    # LIMITS the set of chars that can be used in movie names
    # just 'cause we love shell and we know how painful those chars can be :P 
    def MovieRenamer::sanitizeInput(input)
        # XXX naive sanitize
        # simply removing all non standard characters
        input.gsub(/[^A-Za-z0-9\_\-\s']/,'').gsub(/\s+/,' ').chomp.sub(/ +$/,'')
    end
    
    def MovieRenamer::imdbLookup(name)
        s = Imdb::Search.new(name) 
        coder = HTMLEntities.new
        s.movies[0..4].each_with_index do |m,i|
            m.title = coder.decode(m.title)#.encode("iso-8859-1")
            @output.puts "#{i}, #{m.year} - #{m.director.to_s.gsub(/(\[")|("\])/,'')} - #{m.title.gsub(/     .*/,'')}" 
        end
    end
    # makes a query to imdb database
    def MovieRenamer::suggestMovies(movie)
        coder = HTMLEntities.new
        s = Imdb::Search.new(movie.title) 
        s.movies[0..4].each_with_index do |m,i|
            m.title = coder.decode(m.title)#.encode("iso-8859-1")
            out =  "#{i}, #{m.year} - #{m.director.to_s.gsub(/(\[")|("\])/,'')} - #{m.title.gsub(/     .*/,'')}" 
            say(HighLine.new.color(out, :green))
        end
        mt = s.movies[0..4]
        cmd = ask("pick a choice [0..#{(mt.length) -1 }], Manual search, Edit manually, Skip Movie, Quit", ((0...mt.length).to_a.map{ |e| e.to_s} << %w{m e s q}).flatten) 
        if (0..mt.length).to_a.map{|e| e.to_s}.include?(cmd)
            m = s.movies[cmd.to_i]
            movie.title = m.title.gsub(/     .*/,'').gsub(/\s*\([0-9]+\).*/,'')#.gsub(/\saka\s.*/,'') # aka removes other lang from title
            movie.year = m.year
            movie.director = m.director.to_s.gsub(/(\[")|("\])/,'')
        elsif cmd == "m" 
            movie.title = ask("enter title")
            MovieRenamer::suggestMovies(movie )
        elsif cmd == "q"
            exit(0)
        elsif cmd == "s"
            return nil
        end
        return movie
    end

    # TODO output string variable
    def MovieRenamer::suggestMovie(name)
        s = Imdb::Search.new(name) 
        m = s.movies.first
        @output.puts "#{m.year} - #{m.director} - #{m.title}" 
    end

    # returns the first movie from imdb query
    
end

