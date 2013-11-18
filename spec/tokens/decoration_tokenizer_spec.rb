# encoding: UTF-8

require 'helper'

describe Tr8n::Tokens::DecorationTokenizer do

  describe "parse" do
    it "should correctly parse tokens" do
      dt = Tr8n::Tokens::DecorationTokenizer.new("Hello World")
      expect(dt.fragments).to eq(["[tr8n]", "Hello World", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", "Hello World"])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold: Hello World]")
      expect(dt.fragments).to eq(["[tr8n]", "[bold:", " Hello World", "]", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["bold", "Hello World"]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold: Hello World")
      expect(dt.fragments).to eq(["[tr8n]", "[bold:", " Hello World", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["bold", "Hello World"]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold: Hello [strong: World]]")
      expect(dt.fragments).to eq(["[tr8n]", "[bold:", " Hello ", "[strong:", " World", "]", "]", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["bold", "Hello ", ["strong", "World"]]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold: Hello [strong: World]")
      expect(dt.fragments).to eq(["[tr8n]", "[bold:", " Hello ", "[strong:", " World", "]", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["bold", "Hello ", ["strong", "World"]]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold1: Hello [strong22: World]]")
      expect(dt.fragments).to eq(["[tr8n]", "[bold1:", " Hello ", "[strong22:", " World", "]", "]", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["bold1", "Hello ", ["strong22", "World"]]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold: Hello, [strong: how] [weak: are] you?]")
      expect(dt.fragments).to eq(["[tr8n]", "[bold:", " Hello, ", "[strong:", " how", "]", " ", "[weak:", " are", "]", " you?", "]", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["bold", "Hello, ", ["strong", "how"], " ", ["weak", "are"], " you?"]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold: Hello, [strong: how [weak: are] you?]")
      expect(dt.fragments).to eq(["[tr8n]", "[bold:", " Hello, ", "[strong:", " how ", "[weak:", " are", "]", " you?", "]", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["bold", "Hello, ", ["strong", "how ", ["weak", "are"], " you?"]]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[link: you have [italic: [bold: {count}] messages] [light: in your mailbox]]")
      expect(dt.fragments).to eq(["[tr8n]", "[link:", " you have ", "[italic:", " ", "[bold:", " {count}", "]", " messages", "]", " ", "[light:", " in your mailbox", "]", "]", "[/tr8n]"])
      expect(dt.parse).to eq(["tr8n", ["link", "you have ", ["italic", "", ["bold", "{count}"], " messages"], " ", ["light", "in your mailbox"]]])

      dt = Tr8n::Tokens::DecorationTokenizer.new("[link] you have [italic: [bold: {count}] messages] [light: in your mailbox] [/link]")
      expect(dt.fragments).to eq(["[tr8n]", "[link]", " you have ", "[italic:", " ", "[bold:", " {count}", "]", " messages", "]", " ", "[light:", " in your mailbox", "]", " ", "[/link]", "[/tr8n]"])
      expect(dt.parse).to eq( ["tr8n", ["link", " you have ", ["italic", "", ["bold", "{count}"], " messages"], " ", ["light", "in your mailbox"], " "]])
    end
  end

  describe "substitute" do
    it "should correctly substitute tokens" do
      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold: Hello World]")
      expect(dt.substitute).to eq("<strong>Hello World</strong>")

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold]Hello World[/bold]")
      expect(dt.substitute).to eq("<strong>Hello World</strong>")

      dt = Tr8n::Tokens::DecorationTokenizer.new("[bold] Hello World [/bold]")
      expect(dt.substitute).to eq("<strong> Hello World </strong>")

      dt = Tr8n::Tokens::DecorationTokenizer.new("[p: Hello World]", :p => '<p>{$0}</p>')
      expect(dt.substitute).to eq("<p>Hello World</p>")

      dt = Tr8n::Tokens::DecorationTokenizer.new("[p: Hello World]", :p => lambda{|text| "<p>#{text}</p>"})
      expect(dt.substitute).to eq("<p>Hello World</p>")

      dt = Tr8n::Tokens::DecorationTokenizer.new("[p]Hello World[/p]", :p => lambda{|text| "<p>#{text}</p>"})
      expect(dt.substitute).to eq("<p>Hello World</p>")

      dt = Tr8n::Tokens::DecorationTokenizer.new("[link: you have 5 messages]", "link" => '<a href="http://mail.google.com">{$0}</a>')
      expect(dt.substitute).to eq("<a href=\"http://mail.google.com\">you have 5 messages</a>")

      dt = Tr8n::Tokens::DecorationTokenizer.new("[link: you have {clount} messages]", "link" => '<a href="http://mail.google.com">{$0}</a>')
      expect(dt.substitute).to eq("<a href=\"http://mail.google.com\">you have {clount} messages</a>")

    end
  end

end

