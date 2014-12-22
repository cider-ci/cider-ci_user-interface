module FontMetrics

  DEFAULT_FONT= ["DejaVu Sans", 0, 12]


  case RUBY_ENGINE

  when "jruby" 

    include Java

    @canvas= java.awt.Canvas.new()
    @memoize_table= {}

    class << self


      def text_width text, font = DEFAULT_FONT
        @memoize_table[[text,font]] ||= text_width_unmemoized(text,font)
      end

      def text_width_unmemoized text, font
        jfont= java.awt.Font.new(*font)
        @canvas.getFontMetrics(jfont).stringWidth(text)
      end

    end


  else

    class << self

      # approximation, which is very close for e.g.
      # "A quick movement of the enemy will jeopardize six gunboats."
      def text_width text, font = DEFAULT_FONT 
        (text.length * font[2] * 0.5).ceil
      end

    end

  end

end

