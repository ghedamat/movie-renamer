# imdb monkeypatch 
module Imdb
    
    class Search
        class << self
            def query(query)
                open("http://www.imdb.#{$language}/find?q=#{CGI::escape(query)};s=tt")
            end
        end
    end

    class Movie
        #TODO improve this 'cause imdb site has changed
        def director
            document.at("h4[text()='Director:'] ~ a").innerHTML.strip.imdb_unescape_html rescue nil
            document.search("h4[text()^='Director'] ~ a").map { |link| link.innerHTML.strip.imdb_unescape_html } rescue []
        end
    end
          
end
