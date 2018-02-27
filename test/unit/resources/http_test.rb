# encoding: utf-8
# author: Guilhem Lettron

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::Http' do
  describe 'InSpec::Resources::Http::Worker::Local' do
    let(:domain)      { 'www.example.com' }
    let(:http_method) { 'GET' }
    let(:opts)        { {} }
    let(:worker)      { Inspec::Resources::Http::Worker::Local.new(http_method, "http://#{domain}", opts) }

    describe 'simple HTTP request with no options' do
      it 'returns correct data' do
        stub_request(:get, domain).to_return(status: 200, body: 'pong')

        _(worker.status).must_equal 200
        _(worker.body).must_equal 'pong'
      end
    end

    describe 'request with basic auth' do
      let(:opts) { { auth: { user: 'user', pass: 'pass' } } }

      it 'returns correct data' do
        stub_request(:get, domain).with(basic_auth: ['user', 'pass']).to_return(status: 200, body: 'auth ok')

        _(worker.status).must_equal 200
        _(worker.body).must_equal 'auth ok'
      end
    end

    describe 'POST request with data' do
      let(:http_method) { 'POST'}
      let(:opts)        { { data: {a: '1', b: 'five'} } }

      it 'returns correct data' do
        stub_request(:post, domain).with(body: {a: '1', b: 'five'}).to_return(status: 200, body: 'post ok')

        _(worker.status).must_equal 200
        _(worker.body).must_equal 'post ok'
      end
    end

    describe 'with request headers' do
      let(:opts) { { headers: { 'accept' => 'application/json' } } }

      it 'returns correct data' do
        stub_request(:get, domain).with(headers: {'accept' => 'application/json'}).to_return(status: 200, body: 'headers ok', headers: {'mock' => 'ok'})

        _(worker.status).must_equal 200
        _(worker.body).must_equal 'headers ok'
        _(worker.response_headers['mock']).must_equal 'ok'
      end
    end

    describe 'with params' do
      let(:opts) { { params: { a: 'b' } } }

      it 'returns correct data' do
        stub_request(:get, domain).with(query: {a: 'b'}).to_return(status: 200, body: 'params ok')

        _(worker.status).must_equal 200
        _(worker.body).must_equal 'params ok'
      end
    end

    describe 'an OPTIONS request' do
      let(:http_method) { 'OPTIONS' }
      let(:opts) { { headers: { 'Access-Control-Request-Method' => 'GET',
                                'Access-Control-Request-Headers' => 'origin, x-requested-with',
                                'Origin' => 'http://www.example.com' } } }

      it 'returns correct data' do
        stub_request(:options, "http://www.example.com/").
          with(:headers => {'Access-Control-Request-Headers'=>'origin, x-requested-with', 'Access-Control-Request-Method'=>'GET', 'Origin'=>'http://www.example.com'}).
          to_return(:status => 200, :body => "", :headers => { 'mock' => 'ok', 'Access-Control-Allow-Origin' => 'http://www.example.com', 'Access-Control-Allow-Methods' => 'POST, GET, OPTIONS, DELETE', 'Access-Control-Max-Age' => '86400' })

        _(worker.status).must_equal 200
        _(worker.response_headers['mock']).must_equal 'ok'
        _(worker.response_headers['access-control-allow-origin']).must_equal 'http://www.example.com'
        _(worker.response_headers['access-control-allow-methods']).must_equal 'POST, GET, OPTIONS, DELETE'
        _(worker.response_headers['access-control-max-age']).must_equal '86400'
      end
    end
  end

  describe 'Inspec::Resource::Http::Worker::Remote' do
    let(:backend)     { MockLoader.new.backend }
    let(:http_method) { 'GET' }
    let(:url)         { 'http://www.example.com' }
    let(:opts)        { {} }
    let(:worker)      { Inspec::Resources::Http::Worker::Remote.new(backend, http_method, url, opts)}

    describe 'simple HTTP request with no options' do
      it 'returns correct data' do
        _(worker.status).must_equal 200
        _(worker.body).must_equal 'no options'
      end
    end

    describe 'request with basic auth' do
      let(:opts) { { auth: { user: 'user', pass: 'pass' } } }

      it 'returns correct data' do
        _(worker.status).must_equal 200
        _(worker.body).must_equal 'auth ok'
      end
    end

    describe 'POST request with data' do
      let(:http_method) { 'POST'}
      let(:opts)        { { data: {a: '1', b: 'five'} } }

      it 'returns correct data' do
        _(worker.status).must_equal 200
        _(worker.body).must_equal 'post ok'
      end
    end

    describe 'with request headers' do
      let(:opts) { { headers: { 'accept' => 'application/json', 'foo' => 'bar' } } }

      it 'returns correct data' do
        _(worker.status).must_equal 200
        _(worker.body).must_equal 'headers ok'
        _(worker.response_headers['mock']).must_equal 'ok'
      end
    end

    describe 'with params' do
      let(:opts) { { params: { a: 'b', c: 'd' } } }

      it 'returns correct data' do
        _(worker.status).must_equal 200
        _(worker.body).must_equal 'params ok'
      end
    end

    describe 'a HEAD request' do
      let(:http_method) { 'HEAD' }

      it 'returns correct data' do
        _(worker.status).must_equal 301
        _(worker.response_headers['Location']).must_equal 'http://www.google.com/'
      end
    end

    describe 'an OPTIONS request' do
      let(:http_method) { 'OPTIONS' }
      let(:opts) { { headers: { 'Access-Control-Request-Method' => 'GET',
                                'Access-Control-Request-Headers' => 'origin, x-requested-with',
                                'Origin' => 'http://www.example.com' } } }

      it 'returns correct data' do
        _(worker.status).must_equal 200
        _(worker.response_headers['Access-Control-Allow-Origin']).must_equal 'http://www.example.com'
        _(worker.response_headers['Access-Control-Allow-Methods']).must_equal 'POST, GET, OPTIONS, DELETE'
        _(worker.response_headers['Access-Control-Max-Age']).must_equal '86400'
      end
    end
  end

  describe 'Inspec::Resource::Http::Headers' do
    let(:headers) { Inspec::Resources::Http::Headers.create(a: 1, B: 2, 'c' => 3, 'D' => 4) }

    it 'returns the correct data via hash syntax ensuring case-insensitive keys' do
      headers['a'].must_equal(1)
      headers['A'].must_equal(1)
      headers['b'].must_equal(2)
      headers['B'].must_equal(2)
      headers['c'].must_equal(3)
      headers['C'].must_equal(3)
      headers['d'].must_equal(4)
      headers['D'].must_equal(4)
    end

    it 'returns the correct data via method syntax ensuring case-insensitive keys' do
      headers.a.must_equal(1)
      headers.A.must_equal(1)
      headers.b.must_equal(2)
      headers.B.must_equal(2)
      headers.c.must_equal(3)
      headers.C.must_equal(3)
      headers.d.must_equal(4)
      headers.D.must_equal(4)
    end
  end
end
