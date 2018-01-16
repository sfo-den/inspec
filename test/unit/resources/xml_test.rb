# encoding: utf-8

require 'helper'
require 'inspec/resource'
require 'rexml/document'

describe 'Inspec::Resources::XML' do
  describe 'when loading valid XML' do
    let (:resource) { load_resource('xml', 'default.xml') }

    it 'gets params as a document' do
      _(resource.params).must_be_kind_of REXML::Document
    end

    it 'retrieves empty array if xpath cannot be found' do
      _(resource.send('missing')).must_equal []
    end

    it 'retrieves xpath by name' do
      _(resource.send('breakfast_menu/food[1]/name')).must_equal ['Belgian Waffles']
      _(resource.send('/breakfast_menu/food[1]/name')).must_equal ['Belgian Waffles']
    end

    it 'retrieves many xpaths by name' do
      _(resource.send('/breakfast_menu/food/name')).must_equal ['Belgian Waffles', 'Strawberry Belgian Waffles']
      _(resource.send('//name')).must_equal ['Belgian Waffles', 'Strawberry Belgian Waffles']
    end
  end

  describe 'when loading xml with attributes' do
    let (:resource) { load_resource('xml', 'database.xml') }

    it 'gets params as a document' do
      _(resource.params).must_be_kind_of REXML::Document
    end

    it 'retrieves empty array if xpath cannot be found' do
      _(resource.send('missing')).must_equal []
    end

    it 'retrieves attribute value through xpath' do
      _(resource.send('//property[@name="url"]/@value')).must_equal ['jdbc:oracle:thin:@databaseserver.domain.tld:1521/DBO.DOMAIN.TLD']
      _(resource.send('/beans/bean[@id="dataSource"]/property[@name="url"]/@value')).must_equal ['jdbc:oracle:thin:@databaseserver.domain.tld:1521/DBO.DOMAIN.TLD']
    end
  end
end
