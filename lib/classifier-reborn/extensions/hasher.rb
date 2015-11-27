# encoding: utf-8
# Author::    Lucas Carlson  (mailto:lucas@rufy.com)
# Copyright:: Copyright (c) 2005 Lucas Carlson
# License::   LGPL

require 'set'
require 'jieba_rb'

module ClassifierReborn
  module Hasher
    STOPWORDS_PATH = [File.expand_path(File.dirname(__FILE__) + '/../../../data/stopwords')]

    module_function

    # Return a Hash of strings => ints. Each word in the string is stemmed,
    # interned, and indexes to its frequency in the document.
    def word_hash(str, language = 'en')
      cleaned_word_hash = clean_word_hash(str, language)
      symbol_hash = word_hash_for_symbols(str.scan(/[^\s\p{WORD}]/))
      cleaned_word_hash.merge(symbol_hash)
    end

    # Return a word hash without extra punctuation or short symbols, just stemmed words
    def clean_word_hash(str, language = 'en')
      if language == 'cn'
        seg = JiebaRb::Segment.new mode: :hmm
        words = seg.cut(str)
        word_hash_for_words words, language
      else
        word_hash_for_words str.gsub(/[^\p{WORD}\s]/, '').downcase.split, language
      end
    end

    def word_hash_for_words(words, language = 'en')
      d = Hash.new(0)
      word_len = language == 'cn' ? 1 : 2
      words.each do |word|
        next unless word.strip.length > word_len
        if language == 'cn'
          d[word.intern] += 1 if word.length > word_len && !STOPWORDS[language].include?(word)
        else
          d[word.stem.intern] += 1 if word.length > word_len && !STOPWORDS[language].include?(word)
        end
      end
      # p words, language, d
      d
    end

    def word_hash_for_symbols(words)
      d = Hash.new(0)
      words.each do |word|
        d[word.intern] += 1
      end
      d
    end

    # Create a lazily-loaded hash of stopword data
    STOPWORDS = Hash.new do |hash, language|
      hash[language] = []

      STOPWORDS_PATH.each do |path|
        if File.exist?(File.join(path, language))
          hash[language] = Set.new File.read(File.join(path, language.to_s)).split
          break
        end
      end

      hash[language]
    end
  end
end
