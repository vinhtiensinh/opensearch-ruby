require 'test_helper'

class Elasticsearch::Client::Transport::Connections::ConnectionTest < Test::Unit::TestCase
  include Elasticsearch::Client::Transport::Connections

  context "Connection" do

    should "be initialized with :host, :connection, and :options" do
      c = Connection.new :host => 'x', :connection => 'y', :options => {}
      assert_equal 'x', c.host
      assert_equal 'y', c.connection
      assert_instance_of Hash, c.options
    end

    should "return full path" do
      c = Connection.new
      assert_equal '_search', c.full_path('_search')
      assert_equal '_search', c.full_path('_search', {})
      assert_equal '_search?foo=bar', c.full_path('_search', {:foo => 'bar'})
      assert_equal '_search?foo=bar+bam', c.full_path('_search', {:foo => 'bar bam'})
    end

    should "return full url" do
      c = Connection.new :host => { :protocol => 'http', :host => 'localhost', :port => '9200' }
      assert_equal 'http://localhost:9200/_search?foo=bar', c.full_url('_search', {:foo => 'bar'})
    end

    should "have a string representation" do
      c = Connection.new :host => 'x'
      assert_match /host: x/, c.to_s
      assert_match /alive/,   c.to_s
    end

    should "not be dead by default" do
      c = Connection.new
      assert ! c.dead?
    end

    should "be dead when marked" do
      c = Connection.new.dead!
      assert c.dead?
      assert_equal 1, c.failures
      assert_in_delta c.dead_since, Time.now, 1
    end

    should "be alive when marked" do
      c = Connection.new.dead!
      assert c.dead?
      assert_equal 1, c.failures
      assert_in_delta c.dead_since, Time.now, 1

      c.alive!
      assert ! c.dead?
      assert_equal 1, c.failures
    end

    should "be healthy when marked" do
      c = Connection.new.dead!
      assert c.dead?
      assert_equal 1, c.failures
      assert_in_delta c.dead_since, Time.now, 1

      c.healthy!
      assert ! c.dead?
      assert_equal 0, c.failures
    end

    should "be resurrected if timeout passed" do
      c = Connection.new.dead!

      now = Time.now + 60
      Time.stubs(:now).returns(now)

      assert   c.resurrect!, c.inspect
      assert ! c.dead?,      c.inspect
    end

    should "be resurrected if timeout passed for multiple failures" do
      c = Connection.new.dead!.dead!

      now = Time.now + 60*2
      Time.stubs(:now).returns(now)

      assert   c.resurrect!, c.inspect
      assert ! c.dead?,      c.inspect
    end

  end

end
