RSpec.describe JSON::Schema::Serializer::WithContext do
  let(:klass) do
    Class.new do
      include JSON::Schema::Serializer::WithContext
    end
  end

  let(:data) { :data }
  let(:context) { :context }

  describe "block" do
    subject { klass.new.with_context!(context) { data } }

    it do
      is_asserted_by { subject.class == JSON::Schema::Serializer::DataWithContext }
      is_asserted_by { subject.data == :data }
      is_asserted_by { subject.context == :context }
    end
  end

  describe "positional" do
    subject { klass.new.with_context!(data, context) }

    it do
      is_asserted_by { subject.class == JSON::Schema::Serializer::DataWithContext }
      is_asserted_by { subject.data == :data }
      is_asserted_by { subject.context == :context }
    end
  end

  describe "keyword" do
    subject { klass.new.with_context!(data: data, context: context) }

    it do
      is_asserted_by { subject.class == JSON::Schema::Serializer::DataWithContext }
      is_asserted_by { subject.data == :data }
      is_asserted_by { subject.context == :context }
    end
  end
end
