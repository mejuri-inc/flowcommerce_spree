# frozen_string_literal: true

FactoryBot.define do
  factory :flow_local, class: Io::Flow::V0::Models::Local do
    experience { build(:flow_experience_summary) }
    prices { [build(:flow_localized_total)] }
    rates { [build(:flow_rate)] }
    spot_rates { [{ 'EUR - USD' => 1.18 }] }

    initialize_with { new(**attributes) }
  end
end
