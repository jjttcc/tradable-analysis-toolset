require_relative 'publication'
require_relative 'subscription'

class PublisherSubscriber
  include Contracts::DSL, Publication, Subscription

  private

  post :channels_set do
    ! (default_publishing_channel.nil? || default_subscription_channel.nil?) end
  def initialize(pubchan = 'default-channel', subchan = 'default-channel')
    @default_publishing_channel = pubchan
    @default_subscription_channel = subchan
  end

end
