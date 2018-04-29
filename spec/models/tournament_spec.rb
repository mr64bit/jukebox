require 'rails_helper'

describe Tournament do
  it 'should add tournaments to the database' do
    Tournament.create(id: '123abc')
    expect(Tournament.count).to eq(1)
  end
end
