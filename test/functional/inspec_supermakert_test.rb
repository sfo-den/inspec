# encoding: utf-8

require 'functional/helper'

describe 'inspec supermakert' do
  include FunctionalHelper

  it 'help' do
    out = inspec('supermarket help')
    out.exit_status.must_equal 0
    out.stdout.must_include 'inspec supermarket exec PROFILE'
  end

  it 'info' do
    out = inspec('supermarket info dev-sec/ssh-baseline')
    out.exit_status.must_equal 0
    out.stderr.must_equal ''
    out.stdout.must_include "name: \e[0m  ssh-baseline"
  end

  it 'supermarket exec' do
    out = inspec('supermarket exec dev-sec/ssh-baseline')
    out.exit_status.wont_equal 1
    out.stderr.must_equal ''
    out.stdout.must_include 'Profile Summary'
    out.stdout.must_include 'Test Summary'
  end
end
