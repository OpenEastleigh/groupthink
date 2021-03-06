# frozen_string_literal: true

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the ProposalsHelper. For example:
#
# describe ProposalsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ProposalsHelper, type: :helper do
  context "when replacing emoji" do
    {
      ":thumbsup:": "👍",
      ":thumbsdown:": "👎",
      ":+1:": "👍",
      ":-1:": "👎",
      ":hand:": "✋",
      ":smiley:": "😃",
    }.each_pair do |input, output|
      it "#{input} with #{output}" do
        expect(helper.replace_emoji(input.to_s)).to eql output
      end
    end
  end

  context "when linking usernames" do
    it "at the start of a string" do
      input = "@hello there"
      output = "<a href='/users/hello'>@hello</a> there"
      expect(helper.link_usernames(input)).to eql output
    end

    it "in the middle of a string" do
      input = "well @hello there"
      output = "well <a href='/users/hello'>@hello</a> there"
      expect(helper.link_usernames(input)).to eql output
    end

    it "at the end of a string" do
      input = "well @hello"
      output = "well <a href='/users/hello'>@hello</a>"
      expect(helper.link_usernames(input)).to eql output
    end

    it "at the start of a paragraph tag" do
      input = "<p>@hello there</p>"
      output = "<p><a href='/users/hello'>@hello</a> there</p>"
      expect(helper.link_usernames(input)).to eql output
    end

    it "not in an email address" do
      input = "bob@example.com"
      output = "bob@example.com"
      expect(helper.link_usernames(input)).to eql output
    end
  end

  context "when linking proposals" do
    it "at the start of a string" do
      input = "#434 is relevant"
      output = "<a href='/proposals/434'>#434</a> is relevant"
      expect(helper.link_proposals(input)).to eql output
    end

    it "in the middle of a string" do
      input = "I think #434 is relevant"
      output = "I think <a href='/proposals/434'>#434</a> is relevant"
      expect(helper.link_proposals(input)).to eql output
    end

    it "at the end of a string" do
      input = "see #434"
      output = "see <a href='/proposals/434'>#434</a>"
      expect(helper.link_proposals(input)).to eql output
    end

    it "at the start of a paragraph tag" do
      input = "<p>#434 is relevant</p>"
      output = "<p><a href='/proposals/434'>#434</a> is relevant</p>"
      expect(helper.link_proposals(input)).to eql output
    end

    it "not in an HTML entity" do
      input = "&#434;"
      output = "&#434;"
      expect(helper.link_proposals(input)).to eql output
    end
  end

  context "when rendering diffs" do
    # Example diff from the GNU diff man pages: https://www.gnu.org/software/diffutils/manual/html_node/Example-Unified.html
    let(:diff) {
      <<~EOF.strip
      --- lao	2002-02-21 23:30:39.942229878 -0800
      +++ tzu	2002-02-21 23:30:50.442260588 -0800
      @@ -1,7 +1,6 @@
      -The Way that can be told of is not the eternal Way;
      -The name that can be named is not the eternal name.
       The Nameless is the origin of Heaven and Earth;
      -The Named is the mother of all things.
      +The named is the mother of all things.
      +
       Therefore let there always be non-being,
         so we may see their subtlety,
       And let there always be being,
      @@ -9,3 +8,6 @@
       The two are the same,
       But after they are produced,
         they have different names.
      +They both may be called deep and profound.
      +Deeper and more profound,
      +The door of all subtleties!
      EOF
    }

    it "always starts with an empty unchanged section" do
      expect(helper.render_diff(diff)).to start_with("<div class='diff unchanged'></div>")
    end

    it "ignores range lines" do
      expect(helper.render_diff(diff)).not_to include("-1,7")
    end

    it "ignores filename lines with ---" do
      expect(helper.render_diff(diff)).not_to include("lao")
    end

    it "ignores filename lines with +++" do
      expect(helper.render_diff(diff)).not_to include("tzu")
    end

    it "renders additions inside an 'added' div" do
      expected = "<div class='diff added'><p>The named is the mother of all things.</p></div>"
      expect(helper.render_diff(diff)).to include(expected)
    end

    it "renders removals inside a 'removed' div" do
      expected = "<div class='diff removed'><p>The Named is the mother of all things.</p></div>"
      expect(helper.render_diff(diff)).to include(expected)
    end

    it "renders untouches lines inside an 'unchanged' div" do
      x = "<div class='diff unchanged'><p>The Nameless is the origin of Heaven and Earth;</p></div>"
      expect(helper.render_diff(diff)).to include(x)
    end

    it "combines contiguous lines of the same type into one chunk" do
      expected = <<~EOF.strip
      <div class='diff removed'><p>The Way that can be told of is not the eternal Way;
      The name that can be named is not the eternal name.</p></div>
      EOF
      expect(helper.render_diff(diff)).to include(expected)
    end
  end
end
