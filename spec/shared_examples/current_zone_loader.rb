# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'current_zone_loader' do
  describe('#flow_zone') do
    context('when no Spree::Zones::Product is created') do
      it('returns nil when Spree::Zones::Product') do
        expect(controller.flow_zone).to(be_nil)
      end
    end

    context('when Spree::Zones::Product') do
      context('without flow_data') do
        it('returns nil') do
          create(:germany_zone)
          expect(controller.flow_zone).to(be_nil)
        end
      end

      context('with flow_data') do
        let(:germany_zone) { create(:germany_zone, :with_flow_data) }
        let(:flowcommerce_session) do
          flowcommerce_session = FlowcommerceSpree::Session.new(ip: '85.214.132.117', visitor: 'testing_visitor')
          flowcommerce_session.session = OpenStruct.new(id: 'testing')
          flowcommerce_session
        end
        let(:experience) { OpenStruct.new(country: 'DEU', currency: 'EUR', key: 'germany', language: 'de', name: germany_zone.name) }

        before(:each) do
          allow(flowcommerce_session).to(receive(:experience).and_return(experience))
          allow(flowcommerce_session).to(receive(:create))
          allow(FlowcommerceSpree::Session).to(receive(:new).and_return(flowcommerce_session))
        end

        context('and request_iso_code associated to flow_experience') do
          it('returns zone associated') do
            allow(controller).to(receive(:request_iso_code).and_return('DE'))
            expect(controller.flow_zone).to(eq(germany_zone))
          end
        end

        context('and request_iso_code not associated to flow_experience') do
          it('returns zone associated') do
            allow(controller).to(receive(:request_iso_code).and_return('GB'))
            expect(controller.flow_zone).to(be_nil)
          end
        end
      end
    end
  end
end
