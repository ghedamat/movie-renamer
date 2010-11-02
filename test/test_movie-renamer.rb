require 'helper'
require File.join(File.dirname(__FILE__),'..', 'lib','movie-renamer')
require 'stringio'
require 'mocha'

class TestMovieRenamer < Test::Unit::TestCase
    
    def setup
       @folder = File.expand_path('temp')
       MovieRenamer::folderPath =  @folder
       @movies = MovieRenamer::findMovies(@folder)
       @input = StringIO.new
       @output = StringIO.new
       MovieRenamer::input = @input 
       MovieRenamer::output = @output 
       MovieRenamer::is_a_test = true 
    end

    
    # test title extraction
    must "extract a title correctly with bad words in filename" do
    ['DIvX-ITa Kill Bill Vol. 2','(Divx-Ita )Kill Bill Vol. 2',
    'Divx- ita Kill Bill Vol. 2','(Divx - ita) - Kill Bill Vol. 2',
    'xvid- ita Kill Bill Vol. 2','(xvid-ita) - Kill Bill Vol. 2',
    'xvidita Kill Bill Vol. 2','(dvdrip) Kill Bill Vol. 2',
    '[Divx-Ita ]Kill Bill Vol. 2','Kill Bill Vol. 2 [divx - Ita ]'].each do |name|
        assert_equal "Kill Bill Vol. 2", MovieRenamer::titleExtract(name)
    end
    end
    
    # simple checks that rename is done 
    must "rename a file (and moves it) correctly" do
        assert ! MovieRenamer::renameMovie(MovieRenamer::readMovie(@movies.first)), "file not renamed?"
    end

    # newname check
    must "rename a movie correctly" do 
        movie = MovieRenamer::Movie.new 'movie1.avi', year: '2001' , director: 'me', title: 'famous'
        assert_equal "2001 - me - famous.avi",MovieRenamer::newName(movie)
    end
    
    must "rename a movie correctly with parts" do 
        movie = MovieRenamer::Movie.new 'movie1.avi', year: '2001' , director: 'me', title: 'famous', part: '1'
        assert_equal "2001 - me - famous - part1.avi",MovieRenamer::newName(movie)
    end

    must "rename a movie correctly without part because part is wrong" do 
        movie = MovieRenamer::Movie.new 'movie1.avi', year: '2001' , director: 'me', title: 'famous', part: '    '
        assert_equal "2001 - me - famous.avi",MovieRenamer::newName(movie)
    end

    # test input sanitize
    must "sanitize input correctly" do
        input = "ain't a very bad movie{}\@# son     "
        assert_equal "ain't a very bad movie son", MovieRenamer::sanitizeInput(input)
    end

    must "parse a movie title" do
        input = "2010: Odissea Nello Spazio - Stanley Kubrick - 1964.avi"
        mov = MovieRenamer::Movie.new("test.avi",:title =>"2001: Odissea Nello Spazio",:director=>"Stanley Kubrick",:year=>1964)
        assert_equal mov, MovieRenamer::parseMovie(input)
    end



    # helpers
    def provide_input (string)
        @input << string
        @input.rewind
    end

    def expect_output(string)
        assert_equal string, @output.string
    end

end

