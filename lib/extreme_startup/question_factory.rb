# encoding: utf-8
require 'set'
require 'prime'

module ExtremeStartup
  class Question
    class << self
      def generate_uuid
        @uuid_generator ||= UUID.new
        @uuid_generator.generate.to_s[0..7]
      end
    end

    def ask(player)
      url = player.url + '?q=' + URI.escape(self.to_s)
      puts "GET: " + url
      begin
        response = get(url)
        if (response.success?) then
          self.answer = response.to_s
        else
          @problem = "error_response"
        end
      rescue => exception
        puts exception
        @problem = "no_server_response"
      end
    end

    def get(url)
      HTTParty.get(url)
    end

    def result
      if @answer && self.answered_correctly?(answer)
        "correct"
      elsif @answer
        "wrong"
      else
        @problem
      end
    end

    def delay_before_next
      case result
        when "correct"        then 5
        when "wrong"          then 10
        else 20
      end
    end

    def was_answered_correctly
      result == "correct"
    end

    def was_answered_wrongly
      result == "wrong"
    end

    def display_result
      "\tquestion: #{self.to_s}\n\tanswer: #{answer}\n\tresult: #{result}"
    end

    def id
      @id ||= Question.generate_uuid
    end

    def to_s
      "#{id}: #{as_text}"
    end

    def answer=(answer)
      @answer = answer.force_encoding("UTF-8")
    end

    def answer
      begin
        @answer && @answer.downcase.strip
      rescue
      end
    end

    def answered_correctly?(answer)
      correct_answer.to_s.downcase.strip == answer
    end

    def points
      10
    end
  end

  class BinaryMathsQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @n1, @n2 = *numbers
      else
        @n1, @n2 = rand(20), rand(20)
      end
    end
  end

  class TernaryMathsQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @n1, @n2, @n3 = *numbers
      else
        @n1, @n2, @n3 = rand(20), rand(20), rand(20)
      end
    end
  end

  class SelectFromListOfNumbersQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @numbers = *numbers
      else
        size = rand(2)
        @numbers = random_numbers[0..size].concat(candidate_numbers.shuffle[0..size]).shuffle
      end
    end

    def random_numbers
      randoms = Set.new
      loop do
        randoms << rand(1000)
        return randoms.to_a if randoms.size >= 5
      end
    end

    def correct_answer
       @numbers.select do |x|
         should_be_selected(x)
       end.join(', ')
     end
  end

  class MaximumQuestion < SelectFromListOfNumbersQuestion
    def as_text
      "hvilket av disse tallene er storst: " + @numbers.join(', ')
    end
    def points
      40
    end
    private
      def should_be_selected(x)
        x == @numbers.max
      end

      def candidate_numbers
          (1..100).to_a
      end
    end

  class AdditionQuestion < BinaryMathsQuestion
    def as_text
      "hva er #{@n1} pluss #{@n2}"
    end
  private
    def correct_answer
      @n1 + @n2
    end
  end

  class SubtractionQuestion < BinaryMathsQuestion
    def as_text
      "hva er #{@n1} minus #{@n2}"
    end
  private
    def correct_answer
      @n1 - @n2
    end
  end

  class MultiplicationQuestion < BinaryMathsQuestion
    def as_text
      "hva er #{@n1} ganget med #{@n2}"
    end
  private
    def correct_answer
      @n1 * @n2
    end
  end

  class AdditionAdditionQuestion < TernaryMathsQuestion
    def as_text
      "hva er #{@n1} pluss #{@n2} pluss #{@n3}"
    end
    def points
      30
    end
  private
    def correct_answer
      @n1 + @n2 + @n3
    end
  end

  class AdditionMultiplicationQuestion < TernaryMathsQuestion
    def as_text
      "hva er #{@n1} pluss #{@n2} ganget med #{@n3}"
    end
    def points
      60
    end
  private
    def correct_answer
      @n1 + @n2 * @n3
    end
  end

  class MultiplicationAdditionQuestion < TernaryMathsQuestion
    def as_text
      "hva er #{@n1} ganget med #{@n2} pluss #{@n3}"
    end
    def points
      50
    end
  private
    def correct_answer
      @n1 * @n2 + @n3
    end
  end

  class PowerQuestion < BinaryMathsQuestion
    def as_text
      "hva er #{@n1} opphoyet i #{@n2}"
    end
    def points
      20
    end
  private
    def correct_answer
      @n1 ** @n2
    end
  end

  class SquareCubeQuestion < SelectFromListOfNumbersQuestion
    def as_text
      "hvilke av disse tallene har heltalls kvadratrot og kubikkrot: " + @numbers.join(', ')
    end
    def points
      60
    end
  private
    def should_be_selected(x)
      is_square(x) and is_cube(x)
    end

    def candidate_numbers
        square_cubes = (1..100).map { |x| x ** 3 }.select{ |x| is_square(x) }
        squares = (1..50).map { |x| x ** 2 }
        square_cubes.concat(squares)
    end

    def is_square(x)
      if (x ==0)
        return true
      end
      (x % (Math.sqrt(x).round(4))) == 0
    end

    def is_cube(x)
      if (x ==0)
        return true
      end
      (x % (Math.cbrt(x).round(4))) == 0
    end
  end

  class PrimesQuestion < SelectFromListOfNumbersQuestion
     def as_text
       "hvilke av disse tallene er primtall: " + @numbers.join(', ')
     end
     def points
       60
     end
   private
     def should_be_selected(x)
       Prime.prime? x
     end

     def candidate_numbers
       Prime.take(100)
     end
   end

  class FibonacciQuestion < BinaryMathsQuestion
    def as_text
      n = @n1 + 4
      return "hva er det #{n}. nummeret i Fibonaccirekken"
    end
    def points
      50
    end
  private
    def correct_answer
      n = @n1 + 4
      a, b = 0, 1
      n.times { a, b = b, a + b }
      a
    end
  end

  class GeneralKnowledgeQuestion < Question
    class << self
      def question_bank
        [
          ["which city is the Eiffel tower in", "Paris"],
          ["what currency did Spain use before the Euro", "peseta"],
          ["what colour is a banana", "yellow"],
          ["hvilken farge har bananer", "gul"],
          ["hva er FINNs fire verdier som preger oss i alt vi gjør", "sult, presisjon, takhøyde og humør"],
          ["who played James Bond in the film Dr No", "Sean Connery"],
          ["hvilket år endret FINNs nettsider fra oransje til blå", "1999"],
          ["hvilket år fikk FINN 100 ansatte", "2006"],
          ["hvilken by finner du Louvre", "Paris"],
          ["hvilken myntenhet brukte Italia tidligere", "lire"]
        ]
      end
    end

    def initialize(player)
      question = GeneralKnowledgeQuestion.question_bank.sample
      @question = question[0]
      @correct_answer = question[1]
    end

    def as_text
      @question
    end

    def correct_answer
      @correct_answer
    end
  end

  require 'yaml'
  class AnagramQuestion < Question
    def as_text
      possible_words = [@anagram["correct"]] + @anagram["incorrect"]
      %Q{which of the following is an anagram of "#{@anagram["anagram"]}": #{possible_words.shuffle.join(", ")}}
    end

    def initialize(player, *words)
      if words.any?
        @anagram = {}
        @anagram["anagram"], @anagram["correct"], *@anagram["incorrect"] = words
      else
        anagrams = YAML.load_file(File.join(File.dirname(__FILE__), "anagrams.yaml"))
        @anagram = anagrams.sample
      end
    end

    def correct_answer
      @anagram["correct"]
    end
  end

  class ScrabbleQuestion < Question
    def as_text
      "what is the english scrabble score of #{@word}"
    end

    def initialize(player, word=nil)
      if word
        @word = word
      else
        @word = ["banana", "september", "cloud", "zoo", "ruby", "buzzword"].sample
      end
    end

    def correct_answer
      @word.chars.inject(0) do |score, letter|
        score += scrabble_scores[letter.downcase]
      end
    end

    private

    def scrabble_scores
      scores = {}
      %w{e a i o n r t l s u}.each  {|l| scores[l] = 1 }
      %w{d g}.each                  {|l| scores[l] = 2 }
      %w{b c m p}.each              {|l| scores[l] = 3 }
      %w{f h v w y}.each            {|l| scores[l] = 4 }
      %w{k}.each                    {|l| scores[l] = 5 }
      %w{j x}.each                  {|l| scores[l] = 8 }
      %w{q z}.each                  {|l| scores[l] = 10 }
      scores
    end
  end

  class FinnkodeQuestion < Question
    class << self
      def question_type
        ["pris", "tittel"]
      end
      def question_bank
        [
          ["52871626", "14 900 000", "HOLMENKOLLEN: Representativ, påkostet murvilla med spennende arkitektur, unike interiørløsninger og solid konstruksjon"],
          ["52992738", "0", "2 stk 2013 model tv'er gis bort. pga Latterlige regler hos NRK"],
          ["52992702", "20", "Kjeledyr på 15 selges billig ved hurtig avgjørelse"],
          ["52987398", "321 500", "Porsche 911 E 1969, 95 200 km, kr 321 500,-"],
          ["52992230", "200 000", "El Diablo 42 Limited Edition"],
          ["52987538", "4 600 000", "NYBYGG Selfa 1099 MAX"],
          ["52992050", "2 230 000", "RÅHOLT/ SENTRALT - Tiltalende 1/2 tomannsbolig i barnevennlig område"],
          ["52969613", "65", "Fyrstikkholder i kobber"],
          ["52827860", "2 800", "Vakker 1800-talls rokokko sofa"],
          ["52993375", "1 500", "Maleri av J. Lidsheim - Hålandsdal"],
          ["52940791", "500", "Sinkbalje"],
          ["52987860", "0", "HP Pavilion p6669sc"],
          ["52993210", "0", "Candy Grand Vaskemaskin"],
          ["52992977", "2 000", "Samsung Note 3"],
          ["52980000", "1 800", "iPhone 5 16GB hvit"],
          ["53001872", "0", "Fin gyngehest"],
          ["52927028", "0", "TV JVC 37 tommer"],
          ["52862481", "8 500", "Sentralt - sentralfyr og nytt kjøkken"],
          ["52017699", "400", "Xbox 360 konsoler til salg"],
          ["52868872", "4 000", "Sentrumsnært rom til leie"],
          ["52899324", "7 000", "Louis Vuitton"],
          ["52835034", "50", "MASSE nydelige pyntegjenstander selges billig"],
          ["52873320", "550", "iPhone 5S deletelefon"],
          ["52867518", "0", "Barglobus"],
          ["52841476", "0", "Fin hjørnesofa gis bort!"],
          ["52846114", "0", "Kjeler"],
          ["52854025", "750", "Intel 3770k PSU og ASRock HK"],
          ["52832726", "1 500", "Brenderup Tilhenger til salgs"],
          ["52809446", "0", "To stålamper gis bort ved henting"],
          ["52806371", "0", "Canon Pixma MP800"],
          ["52795506", "14 500 000", "Villa på Slemdal - stor tomt - Oppussingsobjekt"],
          ["52804463", "0", "Farmors sofa"],
          ["51226040", "45 000 000,", "DØNNEVIK GÅRD - En unik mulighet for å realisere en drøm - Høy prisklasse"],
          ["49150651", "45 000 000", "Herskapelig og ærverdig gods på stor sjøeiendom i Larvik"],
          ["48957077", "45 000 000", "Spektakulær eiendom i Sandefjord"],
          ["41609162", "45 000 000", "IDYLL PÅ SNARØYA -Lekkert arkitekttegnet teglsteinshus-Strandtomt-Panoramautsikt"],
          ["47946692", "43 500 000", "Strandeiendom på Bygdøy-Unik mulighet. Bryggeanlegg i betong-innendørs svømmebasseng-strandhus-praktikantdel-stor tomt."],
          ["52953788", "100 016 733", "Pen hjørnesofa, 3 x 2 m inkl sjeselong"],
          ["52576997", "750 000", "Tangen sotet, komplett, 47 glass"],
          ["52060372", "600 000", "Gullnummer 9779 9779"],
          ["48162135", "475 000", "Antikk Drikkehorn i sølv"],
          ["48072141", "3 800", "Veldig pent diamantanheng!"],
          ["51767365", "489 000", "AP Royal Oak Offshore Rubens Barrichello"],
          ["52886210", "395 495", "NYE 1:18 GT Modeller: Anson - Yat Ming - Burago - Maisto - Welly"]
        ]
      end
    end
    def as_text
      "hva er #{@type} til finnkode #{@finnkode}"
    end

    def initialize(player)
      @type = FinnkodeQuestion.question_type.sample
      question = FinnkodeQuestion.question_bank.sample
      @finnkode = question[0]
      if @type == "pris"
        @correct_answer = question[1]
      else
        @correct_answer = question[2]
      end
    end

    def answered_correctly?(answer)
      answer.to_s.downcase.strip.include? @correct_answer.to_s.downcase.strip
    end
  end

  class QuestionFactory
    attr_reader :round

    def initialize
      @round = 1
      @question_types = [
        AdditionQuestion,
        MaximumQuestion,
        MultiplicationQuestion,
        SquareCubeQuestion,
        GeneralKnowledgeQuestion,
        PrimesQuestion,
        FinnkodeQuestion,
        SubtractionQuestion,
        FibonacciQuestion,
        PowerQuestion,
        AdditionAdditionQuestion,
        FinnkodeQuestion,
        AdditionMultiplicationQuestion,
        MultiplicationAdditionQuestion,
        AnagramQuestion,
        ScrabbleQuestion
      ]
    end

    def next_question(player)
      window_end = (@round * 2 - 1)
      window_start = 0
      available_question_types = @question_types[window_start..window_end]
      available_question_types.sample.new(player)
    end

    def advance_round
      @round += 1
    end

  end

  class WarmupQuestion < Question
    def initialize(player)
      @player = player
    end

    def correct_answer
      @player.name
    end

    def as_text
      "hva heter laget deres"
    end
  end

  class WarmupQuestionFactory
    def next_question(player)
      WarmupQuestion.new(player)
    end

    def advance_round
      raise("please just restart the server")
    end
  end

end
