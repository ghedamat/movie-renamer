require 'helper'
require File.join(File.dirname(__FILE__),'..', 'lib','movie-renamer')
require 'stringio'

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

    # test find movies
    must "find avi movies in the folder" do
        assert_equal %w{movie1.avi movie2.avi movie3.mkv movie4.mpg}, @movies
        
    end

    # test read movie
    must "create a movie object" do
       assert_equal MovieRenamer::Movie.new('movie1.avi',title: 'movie1'),MovieRenamer::readMovie(@movies.first)
    end
    
    # test title extraction
    must "extract a title correctly with bad words in filename" do
    ['DIvX-ITa Kill Bill Vol. 2','(Divx-Ita )Kill Bill Vol. 2',
    'Divx- ita Kill Bill Vol. 2','(Divx - ita) - Kill Bill Vol. 2',
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

    # print movie info check
    # XXX usless check for now
    must "print movie info correctly" do 
        movie = MovieRenamer::Movie.new 'movie1.avi', year: '2001' , director: 'me', title: 'famous'
        assert MovieRenamer::printMovieInfo(movie)

    end

    # test for ask function movie
    must "return true on yes input" do
        provide_input "yes\n"
        assert MovieRenamer::ask("do you want to edit this movie")
        expect_output "do you want to edit this movie\n"
    end
    
    must "return false on no input" do
        provide_input "no\n"
        assert ! MovieRenamer::ask("do you want to edit this movie")
        expect_output "do you want to edit this movie\n"
    end

    # test input sanitize
    must "sanitize input correctly" do
        input = "ain't a very bad movie{}\@# son     "
        assert_equal "ain't a very bad movie son", MovieRenamer::sanitizeInput(input)
    end

    # test edit movie
    must "edit a movie correctly" do 
        provide_input "yes\n1984\nOrwell James\nBig Brother\n\nyes\n"
        assert ! MovieRenamer::editMovie(@movies.first)
    end

    must "edit a movie correctly testing recursion" do 
        provide_input "yes\n1984\nOrwell James\nBig Brother\n\nno\nyes\n1984\nOrwell James\nBig Brother\n1\nyes\n"
        assert ! MovieRenamer::editMovie(@movies.first)
        #expect_output("wow")
    end


    # test main loop over folder
    must "ask for all movies in folder" do
       provide_input "no\nno\nno\nno\n" 
       assert MovieRenamer::folderLoop()
    end
    
    # suggest movies XXX no test here
    must "suggest a movie list from a movie title" do
        MovieRenamer::suggestMovies("Kill Bill")
        #expect_output "wow"
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

