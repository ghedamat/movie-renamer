module MovieRenamer
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

  # reads move filename and tries to initialize a movie object
  def MovieRenamer::readMovie(filename)
      if @parsepattern
          return MovieRenamer::parseMovie(filename)
      else
          filename = File.basename(filename)
          title = MovieRenamer::titleExtract(File.basename(filename,'.*'))
          return Movie.new(filename,:title => title)
      end
  end

  def MovieRenamer::parseMovie(filename)    
      filename.gsub!(/(\..+$)/,'')
      ext = $1
      p = []
      p << [:year= , @parsepattern =~ /\$year/] if @parsepattern =~ /\$year/
      p << [:title=, @parsepattern =~ /\$title/] if @parsepattern =~ /\$title/
      p << [:director=, @parsepattern =~ /\$director/] if @parsepattern =~ /\$director/
      p.compact!
      p.sort! { |a, b| a[1]<=> b[1] }
      newpattern = @parsepattern.gsub(/\$[a-z]+/,'(.+)')
      m = Movie.new(filename+ ext) 
      p.each_with_index do |e,i|
          filename =~ %r{#{newpattern}}
          m.send e[0], eval("$" +(i+1).to_s)
      end
      if m.title == nil #fallback on titleExtract
          m.title = MovieRenamer::titleExtract(filename)
      end
      return m
  end

  # attempt to remove the divx part from a filename
  def MovieRenamer::titleExtract(filename)
      r1 = %r{\s*\[?\(?\s*[dD](i|I)(v|V)(x|X)\s?(-|_)?\s?\w+\s*\)?\]?\s*}
      r2 = %r{\s*\[?\(?\s*(x|X)(v|V)(i|I)(d|D)\s?(-|_)?\s?\w+\s*\)?\]?\s*}
      r3 = %r{\s*\[?\(?\s*(d|D)(v|V)(d|D)(r|R)(i|I)(p|P)\s?(-|_)?\s*\)?\]?\s*}
      r = /(#{r1}|#{r2}|#{r3})/
      filename.gsub!(/-.*/,'') # XXX takes only first part
      filename.gsub(r,'').gsub(/\s?(-|_)\s?/,' ').gsub(/^\s/,'')
  end
                   
end