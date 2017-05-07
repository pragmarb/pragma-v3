# frozen_string_literal: true

RSpec.describe Pragma::Operation::Show do
  subject(:result) do
    described_class.call(
      params,
      'current_user' => current_user,
      'model.class' => model_klass,
      'decorator.default.class' => decorator_klass,
      'policy.default.class' => policy_klass
    )
  end

  let(:params) do
    {
      id: 1,
      expand: ['user', 'user.role']
    }
  end

  let(:current_user) { OpenStruct.new(id: 1) }

  let(:model_klass) do
    Class.new do
      def self.find_by(conditions)
        return unless conditions[:id] == 1

        OpenStruct.new(
          user_id: 1,
          title: 'My Beautiful Article',
          user: OpenStruct.new(
            id: 1,
            full_name: 'John Doe',
            role: OpenStruct.new(
              name: 'Editor'
            )
          )
        )
      end
    end
  end

  let(:role_decorator_klass) do
    Class.new(Pragma::Decorator::Base) do
      property :name
    end
  end

  let(:user_decorator_klass) do
    Class.new(Pragma::Decorator::Base) do
      include Pragma::Decorator::Association
      property :full_name
    end.tap do |klass|
      klass.belongs_to :role, decorator: role_decorator_klass
    end
  end

  let(:decorator_klass) do
    Class.new(Pragma::Decorator::Base) do
      include Pragma::Decorator::Association
      property :title
    end.tap do |klass|
      klass.belongs_to :user, decorator: user_decorator_klass
    end
  end

  let(:policy_klass) do
    Class.new(Pragma::Policy::Base) do
      def show?
        resource.user_id == user.id
      end
    end
  end

  it 'responds with 200 OK' do
    expect(result['result.response'].status).to eq(200)
  end

  it 'decorates the response entity' do
    expect(result['result.response'].entity).to be_kind_of(Pragma::Decorator::Base)
  end

  it 'expands associations' do
    expect(result['result.response.hash']).to eq(
      'title' => 'My Beautiful Article',
      'user' => {
        'full_name' => 'John Doe',
        'role' => {
          'name' => 'Editor'
        }
      }
    )
  end

  context 'when the model cannot be found' do
    let(:params) do
      { id: 2 }
    end

    it 'responds with 404 Not Found' do
      expect(result['result.response'].status).to eq(404)
    end

    it 'decorates the entity' do
      expect(result['result.response'].entity).to be_kind_of(Pragma::Decorator::Error)
    end
  end

  context 'when the user is not authorized' do
    let(:current_user) { OpenStruct.new(id: 2) }

    it 'responds with 403 Forbidden' do
      expect(result['result.response'].status).to eq(403)
    end

    it 'decorates the entity' do
      expect(result['result.response'].entity).to be_kind_of(Pragma::Decorator::Error)
    end
  end

  context 'with a plain string as the expand parameter' do
    let(:params) do
      { id: 1, expand: 'foo' }
    end

    it 'responds with 422 Unprocessable Entity' do
      expect(result['result.response'].status).to eq(422)
    end

    it 'decorates the error' do
      expect(result['result.response'].entity).to be_kind_of(Pragma::Decorator::Error)
    end
  end

  context 'when expanding a non-existing association' do
    let(:params) do
      {
        id: 1,
        expand: ['foo']
      }
    end

    it 'responds with 400 Bad Request' do
      expect(result['result.response'].status).to eq(400)
    end

    it 'decorates the error' do
      expect(result['result.response'].entity).to be_kind_of(Pragma::Decorator::Error)
    end
  end

  context 'when expanding a child association without expanding the parent' do
    let(:params) do
      {
        id: 1,
        expand: ['user.role']
      }
    end

    it 'responds with 400 Bad Request' do
      expect(result['result.response'].status).to eq(400)
    end

    it 'decorates the error' do
      expect(result['result.response'].entity).to be_kind_of(Pragma::Decorator::Error)
    end
  end
end
