FactoryGirl.define do
  factory :web_service, class: 'Service' do
    name "web"
    cpu 128
    memory 128
    public true
  end
end
