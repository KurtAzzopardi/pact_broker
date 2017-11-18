require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/domain/webhook'

module PactBroker
  module Api
    module Decorators
      describe WebhookDecorator do
        let(:headers) { { :'Content-Type' => 'application/json' } }
        let(:request) do
          {
            method: 'POST',
            url: 'http://example.org/hook',
            headers: headers,
            body: { some: 'body' }
          }
        end

        let(:webhook_request) do
          Domain::WebhookRequest.new(request)
        end

        let(:consumer) { Domain::Pacticipant.new(name: 'Consumer') }
        let(:provider) { Domain::Pacticipant.new(name: 'Provider') }
        let(:event)    { Webhooks::WebhookEvent.new(name: 'something_happened') }
        let(:created_at) { DateTime.now }
        let(:updated_at) { created_at + 1 }

        let(:webhook) do
          Domain::Webhook.new(
            request: webhook_request,
            uuid: 'some-uuid',
            consumer: consumer,
            provider: provider,
            events: [event],
            created_at: created_at,
            updated_at: updated_at
          )
        end

        subject { WebhookDecorator.new(webhook) }

        describe 'to_json' do
          let(:parsed_json) { JSON.parse(subject.to_json(user_options: { base_url: 'http://example.org' }), symbolize_names: true) }

          it 'includes the request' do
            expect(parsed_json[:request]).to eq request
          end

          it 'includes a link to the consumer' do
            expect(parsed_json[:_links][:'pb:consumer'][:name]).to eq 'Consumer'
            expect(parsed_json[:_links][:'pb:consumer'][:href]).to eq 'http://example.org/pacticipants/Consumer'
          end

          it 'includes a link to the provider' do
            expect(parsed_json[:_links][:'pb:provider'][:name]).to eq 'Provider'
            expect(parsed_json[:_links][:'pb:provider'][:href]).to eq 'http://example.org/pacticipants/Provider'
          end

          it 'includes a link to itself' do
            expect(parsed_json[:_links][:self][:href]).to eq 'http://example.org/webhooks/some-uuid'
            expect(parsed_json[:_links][:self][:title]).to_not be_nil
          end

          it 'includes a link to its parent collection' do
            expect(parsed_json[:_links][:'pb:pact-webhooks'][:href]).to_not be_nil
          end

          it 'includes a link to the webhooks resource' do
            expect(parsed_json[:_links][:'pb:webhooks'][:href]).to_not be_nil
          end

          it 'includes a link to execute the webhook directly' do
            expect(parsed_json[:_links][:'pb:execute'][:href]).to eq 'http://example.org/webhooks/some-uuid/execute'
          end

          it 'includes the events' do
            expect(parsed_json[:events].first).to eq name: 'something_happened'
          end

          it 'includes timestamps' do
            expect(parsed_json[:createdAt]).to eq created_at.xmlschema
            expect(parsed_json[:updatedAt]).to eq updated_at.xmlschema
          end

          context 'when the headers are empty' do
            let(:headers) { nil }
            it 'does not include the headers' do
              expect(parsed_json[:request]).to_not have_key :headers
            end
          end
        end

        describe 'from_json' do
          let(:hash) { { request: request, events: [event] } }
          let(:event) { {name: 'something_happened'} }
          let(:json) { hash.to_json }
          let(:webhook) { Domain::Webhook.new }
          let(:parsed_object) { subject.from_json(json) }

          it 'parses the request method' do
            expect(parsed_object.request.method).to eq 'POST'
          end

          it 'parses the request URL' do
            expect(parsed_object.request.url).to eq 'http://example.org/hook'
          end

          it 'parses the request headers' do
            expect(parsed_object.request.headers).to eq 'Content-Type' => 'application/json'
          end

          it 'parses the request body' do
            expect(parsed_object.request.body).to eq 'some' => 'body'
          end

          it 'parses the events' do
            expect(parsed_object.events.first.name).to eq 'something_happened'
          end
        end
      end
    end
  end
end
