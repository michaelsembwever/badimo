require 'spec_helper'
require 'extreme_startup/question_factory'

module ExtremeStartup
  describe FinnQuestion do
    let(:question) { FinnQuestion.new(Player.new) }

    it "converts to a string" do
      question.as_text.should =~ /wh.+/
    end
  end
end
