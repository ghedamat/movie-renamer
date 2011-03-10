module  MovieRenamer
    
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
    
end