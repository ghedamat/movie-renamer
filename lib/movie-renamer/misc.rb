
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
    
	if $config['parsepattern']
        @parsepattern = $config['parsepattern']
    end

    if $config['savepath']
        @newpath = File.expand_path($config['savepath'])
    end
    
    puts "Renamed movies will be saved in #{@newpath}/"

      
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
            say "#{i}, #{m.year} - #{m.director.to_s.gsub(/(\[")|("\])/,'')} - #{m.title.gsub(/     .*/,'')}" 
        end
    end
    # makes a query to imdb database
    def MovieRenamer::suggestMovies(movie)
        coder = HTMLEntities.new
        name = (movie.title + " ").gsub(/\W/,' ')#.gsub(/(^\w{,3})|( \w{,3} )/,'').gsub(/\s+/,' ').chomp        
        s = Imdb::Search.new(name) 
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
            MovieRenamer::suggestMovies(movie)
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


